/**
 * SatSet fleet control-plane — privileged callables for the super admin.
 *
 * All mutations a super admin performs from the in-app Fleet console route
 * through here: the Admin SDK can create/disable/delete Firebase Auth users and
 * write the kill switch / billing fields that Firestore rules deny to clients.
 * Every callable is guarded by assertSuper().
 *
 * See docs/adr/0016-fleet-superadmin-cloud-control-plane.md.
 */
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();
const auth = getAuth();

const STATUSES = ["active", "suspended", "banned"];

/** Throw unless the caller is signed in AND their admins/{uid}.role == 'super'. */
async function assertSuper(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Login required.");
  }
  const snap = await db.collection("admins").doc(uid).get();
  if (!snap.exists || snap.get("role") !== "super") {
    throw new HttpsError("permission-denied", "Super admin only.");
  }
  return uid;
}

function reqStr(data, key) {
  const v = data && data[key];
  if (typeof v !== "string" || v.trim() === "") {
    throw new HttpsError("invalid-argument", `Missing '${key}'.`);
  }
  return v.trim();
}

function reqStatus(data) {
  const s = reqStr(data, "status");
  if (!STATUSES.includes(s)) {
    throw new HttpsError("invalid-argument", `status must be one of ${STATUSES}.`);
  }
  return s;
}

// ── Admin account lifecycle ──────────────────────────────────────────────────

exports.createAdmin = onCall(async (request) => {
  await assertSuper(request);
  const email = reqStr(request.data, "email");
  const password = reqStr(request.data, "password");
  const name = reqStr(request.data, "name");
  const venueId = reqStr(request.data, "venueId");

  const venue = await db.collection("venues").doc(venueId).get();
  if (!venue.exists) {
    throw new HttpsError("not-found", "Venue does not exist.");
  }

  let user;
  try {
    user = await auth.createUser({ email, password, displayName: name });
  } catch (e) {
    throw new HttpsError("already-exists", e.message || "Could not create user.");
  }

  // Custom claims {role, venueId} ride the admin's Firebase ID token so a
  // Main-Device host can verify them offline when admitting an admin-client
  // (ADR-0017). The Firestore admins/{uid} doc stays the human-readable record.
  await auth.setCustomUserClaims(user.uid, { role: "admin", venueId });

  const avatarColorHex =
    typeof request.data.avatarColorHex === "number"
      ? request.data.avatarColorHex
      : null;

  await db.collection("admins").doc(user.uid).set({
    role: "admin",
    status: "active",
    name,
    email,
    venueId,
    avatarColorHex,
    createdAt: FieldValue.serverTimestamp(),
  });
  return { uid: user.uid };
});

/**
 * One-time backfill: stamp {role, venueId} custom claims onto every existing
 * admin from their Firestore doc, so admins created before claims shipped can
 * still join as admin-clients (ADR-0017). Idempotent; super-only.
 */
exports.backfillAdminClaims = onCall(async (request) => {
  await assertSuper(request);
  const snap = await db.collection("admins").get();
  let updated = 0;
  for (const doc of snap.docs) {
    const role = doc.get("role") || "admin";
    const venueId = doc.get("venueId") || "";
    try {
      await auth.setCustomUserClaims(doc.id, { role, venueId });
      updated++;
    } catch (_) {
      // Auth user may be gone; skip and continue.
    }
  }
  return { ok: true, updated };
});

exports.setAdminStatus = onCall(async (request) => {
  await assertSuper(request);
  const uid = reqStr(request.data, "uid");
  const status = reqStatus(request.data);
  await db.collection("admins").doc(uid).update({ status });
  // Mirror suspend/ban onto the Auth user so they can't even sign in.
  await auth.updateUser(uid, { disabled: status !== "active" });
  return { ok: true };
});

exports.deleteAdmin = onCall(async (request) => {
  await assertSuper(request);
  const uid = reqStr(request.data, "uid");
  try {
    await auth.deleteUser(uid);
  } catch (_) {
    // already gone — fall through to clean the doc
  }
  await db.collection("admins").doc(uid).delete();
  return { ok: true };
});

exports.resetAdminPassword = onCall(async (request) => {
  await assertSuper(request);
  const email = reqStr(request.data, "email");
  const link = await auth.generatePasswordResetLink(email);
  return { link };
});

// ── Venue lifecycle ──────────────────────────────────────────────────────────

exports.createVenue = onCall(async (request) => {
  await assertSuper(request);
  const name = reqStr(request.data, "name");
  const address = (request.data.address || "").toString().trim();
  const plan = (request.data.plan || "free").toString().trim();
  const ref = await db.collection("venues").add({
    name,
    address,
    status: "active",
    plan,
    billingStatus: "trial",
    paidUntil: null,
    lastSeenAt: null,
    createdAt: FieldValue.serverTimestamp(),
  });
  return { vid: ref.id };
});

exports.updateVenue = onCall(async (request) => {
  await assertSuper(request);
  const vid = reqStr(request.data, "vid");
  const patch = {};
  if (typeof request.data.name === "string") patch.name = request.data.name.trim();
  if (typeof request.data.address === "string") patch.address = request.data.address.trim();
  if (Object.keys(patch).length === 0) {
    throw new HttpsError("invalid-argument", "Nothing to update.");
  }
  await db.collection("venues").doc(vid).update(patch);
  return { ok: true };
});

// The kill switch.
exports.setVenueStatus = onCall(async (request) => {
  await assertSuper(request);
  const vid = reqStr(request.data, "vid");
  const status = reqStatus(request.data);
  await db.collection("venues").doc(vid).update({ status });
  return { ok: true };
});

exports.setVenueBilling = onCall(async (request) => {
  await assertSuper(request);
  const vid = reqStr(request.data, "vid");
  const patch = {};
  if (typeof request.data.plan === "string") patch.plan = request.data.plan.trim();
  if (typeof request.data.billingStatus === "string") {
    patch.billingStatus = request.data.billingStatus.trim();
  }
  if (typeof request.data.paidUntil === "number") {
    patch.paidUntil = Timestamp.fromMillis(request.data.paidUntil);
  } else if (request.data.paidUntil === null) {
    patch.paidUntil = null;
  }
  if (Object.keys(patch).length === 0) {
    throw new HttpsError("invalid-argument", "Nothing to update.");
  }
  await db.collection("venues").doc(vid).update(patch);
  return { ok: true };
});

exports.deleteVenue = onCall(async (request) => {
  await assertSuper(request);
  const vid = reqStr(request.data, "vid");
  const admins = await db.collection("admins").where("venueId", "==", vid).limit(1).get();
  if (!admins.empty) {
    throw new HttpsError("failed-precondition", "Venue still has admins.");
  }
  await db.collection("venues").doc(vid).delete();
  return { ok: true };
});
