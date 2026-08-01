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
const { onSchedule } = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");
const crypto = require("node:crypto");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();
const auth = getAuth();

// Two states, not three. `banned` did exactly what `suspended` does — stop the
// venue's server, lock its staff out — so the pair only ever offered a choice of
// tone on the most destructive control in the console. Removed in ADR-0076;
// documents still holding it parse to "unknown" on the client, which fails the
// isActive test, so they stay blocked.
const STATUSES = ["active", "suspended"];

// The plans a venue can hold. A trial has a term, a partner has a price; a plan
// with neither would be a hole in the model, which is what free/basic/pro/
// enterprise were. Not enforced on write — a venue on a legacy plan keeps it
// until someone re-plans it deliberately.
const PLANS = ["trial", "partner"];
const CYCLES = ["monthly", "yearly"];

// How long a partner keeps trading past its term before the cutoff sweep
// suspends it. A trial gets none of this — going dark on the stated date is what
// a trial is for. Must stay equal to `fleetGraceAfterLapse` in
// lib/data/services/venue_billing.dart: two numbers for one promise is how the
// console's warning and the venue's cutoff become different facts.
const GRACE_AFTER_LAPSE_MS = 7 * 24 * 60 * 60 * 1000;

// The actor recorded when the schedule acts rather than a person. `actorUid` is
// a free string with no reference, so a reserved value costs nothing — and the
// one class of change nobody remembers making is the one whose audit row gets
// wanted at 09:00 when a venue rings to ask why it is dark.
const SYSTEM_ACTOR = "system";

/**
 * How long a temporary password stays usable. Enforced twice on purpose: the
 * sweep below re-randomizes the credential at Firebase so it is genuinely dead,
 * and the app compares the same window during sign-in so the sweep's schedule
 * slop can never be ridden. See ADR-0075.
 */
const OTP_TTL_MS = 24 * 60 * 60 * 1000;

/** The shortest password Firebase Auth will accept. */
const MIN_PASSWORD_LEN = 6;

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

/**
 * The temporary password a super admin dictates to a venue over the phone.
 *
 * Eight digits, because this is read aloud in a noisy restaurant and typed on a
 * tablet: no case to ask about, no letter that sounds like another one, and the
 * same shape as every bank OTP an Indonesian venue owner has already received.
 * `randomInt` and not `Math.random` — this is a credential, and `Math.random` is
 * seeded predictably enough to enumerate.
 */
function generateOtp() {
  return String(crypto.randomInt(0, 100000000)).padStart(8, "0");
}

/**
 * A password nobody will ever hold, used to retire an expired temporary one.
 * The account is not disabled — the venue admin simply cannot sign in and must
 * ask the operator for a fresh code.
 */
function generateDeadPassword() {
  return crypto.randomBytes(24).toString("base64url");
}

// ── Audit ────────────────────────────────────────────────────────────────────

/**
 * The fleet plane's audit writer. Every mutating callable goes through this one
 * function for the same reason the venue server routes every act through
 * `writeAudit` (lib/server/audit_log.dart): hand-roll the insert and a new field
 * reaches three call sites out of four.
 *
 * **Best-effort by design.** A failed audit write must never roll back the
 * mutation it describes. An operator who taps "Blokir" mid-incident and gets an
 * error because the *log* failed will tap it again; a venue left running because
 * its audit row did not commit is the worse of the two outcomes by a distance.
 * The failure goes to Cloud Logging instead, where it is still recoverable.
 *
 * Never carries a credential: `resetAdminPassword` audits the email it was asked
 * about and never the digits it minted, and `changeOwnPassword` records that a
 * password changed and nothing about what it changed to.
 */
async function writeFleetAudit(actorUid, action, target, before, after) {
  try {
    await db.collection("fleet_audit").add({
      at: FieldValue.serverTimestamp(),
      actorUid,
      action,
      targetType: target.type,
      targetId: target.id || null,
      targetName: target.name || null,
      before: before === undefined ? null : before,
      after: after === undefined ? null : after,
    });
  } catch (e) {
    logger.error("fleet_audit write failed", {
      action,
      targetId: target.id,
      err: String(e),
    });
  }
}

/** Picks only [keys] off a doc snapshot, so the audit records fields not blobs. */
function auditFields(snap, keys) {
  if (!snap || !snap.exists) return null;
  const out = {};
  for (const k of keys) {
    const v = snap.get(k);
    out[k] = v === undefined ? null : v;
  }
  return out;
}

const VENUE_BILLING_KEYS = [
  "plan",
  "trialStartAt",
  "paidUntil",
  "priceMonthly",
  "billingCycle",
];

// ── Admin account lifecycle ──────────────────────────────────────────────────

// Roles a super admin may mint via createAdmin. `super` is seeded by hand, not
// through this callable. `owner` is a read-only cloud report viewer (ADR-0036):
// it never pairs, never runs a server, and is excluded from the admin-client
// token gate — it only reads its venue's published report snapshot.
const CREATABLE_ROLES = ["admin", "owner"];

exports.createAdmin = onCall(async (request) => {
  const actor = await assertSuper(request);
  const email = reqStr(request.data, "email");
  const password = reqStr(request.data, "password");
  const name = reqStr(request.data, "name");
  const venueId = reqStr(request.data, "venueId");
  const role = request.data.role === undefined ? "admin" : reqStr(request.data, "role");
  if (!CREATABLE_ROLES.includes(role)) {
    throw new HttpsError("invalid-argument", `role must be one of ${CREATABLE_ROLES}.`);
  }

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
  await auth.setCustomUserClaims(user.uid, { role, venueId });

  const avatarColorHex =
    typeof request.data.avatarColorHex === "number"
      ? request.data.avatarColorHex
      : null;

  await db.collection("admins").doc(user.uid).set({
    role,
    status: "active",
    name,
    email,
    venueId,
    avatarColorHex,
    // Written explicitly rather than left absent: the sweep queries on this
    // field, and a document missing it is invisible to that query. False here —
    // the operator chose this password, so it is not a dictated temporary one.
    mustChangePassword: false,
    passwordResetAt: null,
    createdAt: FieldValue.serverTimestamp(),
  });
  await writeFleetAudit(actor, "createAdmin", { type: "admin", id: user.uid, name }, null, {
    role,
    status: "active",
    email,
    venueId,
  });
  return { uid: user.uid };
});

/**
 * One-time backfill: stamp {role, venueId} custom claims onto every existing
 * admin from their Firestore doc, so admins created before claims shipped can
 * still join as admin-clients (ADR-0017). Idempotent; super-only.
 */
exports.backfillAdminClaims = onCall(async (request) => {
  const actor = await assertSuper(request);
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
  await writeFleetAudit(actor, "backfillAdminClaims", { type: "fleet" }, null, {
    updated,
  });
  return { ok: true, updated };
});

exports.setAdminStatus = onCall(async (request) => {
  const actor = await assertSuper(request);
  const uid = reqStr(request.data, "uid");
  const status = reqStatus(request.data);
  const ref = db.collection("admins").doc(uid);
  const prev = await ref.get();
  await ref.update({ status });
  // Mirror suspend/ban onto the Auth user so they can't even sign in.
  await auth.updateUser(uid, { disabled: status !== "active" });
  await writeFleetAudit(
    actor,
    "setAdminStatus",
    { type: "admin", id: uid, name: prev.get("name") },
    auditFields(prev, ["status"]),
    { status },
  );
  return { ok: true };
});

exports.deleteAdmin = onCall(async (request) => {
  const actor = await assertSuper(request);
  const uid = reqStr(request.data, "uid");
  // Read before the delete: after it there is nothing left to say who this was,
  // and "an account was removed" without a name or a venue is not a record.
  const prev = await db.collection("admins").doc(uid).get();
  try {
    await auth.deleteUser(uid);
  } catch (_) {
    // already gone — fall through to clean the doc
  }
  await db.collection("admins").doc(uid).delete();
  await writeFleetAudit(
    actor,
    "deleteAdmin",
    { type: "admin", id: uid, name: prev.get("name") },
    auditFields(prev, ["role", "status", "email", "venueId"]),
    null,
  );
  return { ok: true };
});

/**
 * Mints a temporary password for one venue admin and hands it back to the
 * operator to dictate.
 *
 * This used to call `generatePasswordResetLink`, which mints a URL and sends
 * nothing — this project has no mail extension and no SMTP, so the link reached
 * the operator's screen, was discarded by the caller, and the admin waiting for
 * it received nothing at all. The act is now what it always was in practice: the
 * operator is on the phone with the venue and reads them a code.
 *
 * Sets `mustChangePassword`, which the app enforces *before* the eligibility
 * gauntlet and before booting the venue's server — a credential that travelled
 * over WhatsApp never starts a restaurant. See ADR-0075.
 */
exports.resetAdminPassword = onCall(async (request) => {
  const actor = await assertSuper(request);
  const uid = reqStr(request.data, "uid");
  const ref = db.collection("admins").doc(uid);
  const prev = await ref.get();
  if (!prev.exists) {
    throw new HttpsError("not-found", "Admin does not exist.");
  }
  if (prev.get("role") === "super") {
    // A fleet operator resetting another fleet operator locks the console for
    // whoever is not holding the phone. Seeded by hand, recovered by hand.
    throw new HttpsError("failed-precondition", "Cannot reset a super admin.");
  }

  const otp = generateOtp();
  await auth.updateUser(uid, { password: otp });
  await ref.update({
    mustChangePassword: true,
    passwordResetAt: FieldValue.serverTimestamp(),
  });
  // The email and the fact, never the digits.
  await writeFleetAudit(
    actor,
    "resetAdminPassword",
    { type: "admin", id: uid, name: prev.get("name") },
    null,
    { email: prev.get("email") || null, mustChangePassword: true },
  );
  return { otp, email: prev.get("email") || null };
});

/**
 * The other half of the reset: a venue admin, holding a temporary password,
 * setting their own.
 *
 * Deliberately **not** guarded by `assertSuper` — the caller here is the subject,
 * not the operator. It is guarded on being signed in and owning the account,
 * which is the whole authorization story: Firebase already proved they hold the
 * current password by issuing the token this request carries.
 *
 * Clears the flag in the same call that changes the credential, so there is no
 * window where the password is new but the app still demands a change.
 */
exports.changeOwnPassword = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Login required.");
  }
  const password = reqStr(request.data, "password");
  if (password.length < MIN_PASSWORD_LEN) {
    throw new HttpsError(
      "invalid-argument",
      `Password must be at least ${MIN_PASSWORD_LEN} characters.`,
    );
  }
  const ref = db.collection("admins").doc(uid);
  const prev = await ref.get();
  if (!prev.exists) {
    throw new HttpsError("not-found", "Admin does not exist.");
  }

  await auth.updateUser(uid, { password });
  await ref.update({
    mustChangePassword: false,
    passwordResetAt: null,
  });
  // Records that it happened and who did it. Nothing about the password itself,
  // not even its length.
  await writeFleetAudit(
    uid,
    "changeOwnPassword",
    { type: "admin", id: uid, name: prev.get("name") },
    { mustChangePassword: prev.get("mustChangePassword") === true },
    { mustChangePassword: false },
  );
  return { ok: true };
});

/**
 * Retires temporary passwords that were never used.
 *
 * `auth.updateUser({password})` has no expiry of its own, so without this a code
 * dictated over a phone call stays valid forever. The app also refuses an
 * expired code during sign-in, but that refusal is only the app's — this is what
 * makes the credential actually dead at Firebase, for any client.
 *
 * Runs hourly. The window it can leave open (a code up to an hour past its TTL
 * still authenticating at Firebase) is closed by the app-side comparison against
 * the same `passwordResetAt`, so neither check is redundant.
 */
exports.sweepExpiredTempPasswords = onSchedule("every 60 minutes", async () => {
  const cutoff = Timestamp.fromMillis(Date.now() - OTP_TTL_MS);
  const stale = await db
    .collection("admins")
    .where("mustChangePassword", "==", true)
    .where("passwordResetAt", "<", cutoff)
    .get();

  let retired = 0;
  for (const doc of stale.docs) {
    try {
      await auth.updateUser(doc.id, { password: generateDeadPassword() });
      await doc.ref.update({ mustChangePassword: false, passwordResetAt: null });
      // Actor is the system: no operator tapped anything, and leaving the field
      // blank would make the row read as an unattributed credential change.
      await writeFleetAudit(
        "system",
        "expireTempPassword",
        { type: "admin", id: doc.id, name: doc.get("name") },
        { mustChangePassword: true },
        { mustChangePassword: false },
      );
      retired++;
    } catch (e) {
      // One broken account must not strand the rest of the sweep.
      logger.error("temp password sweep failed", { uid: doc.id, err: String(e) });
    }
  }
  if (retired > 0) logger.info("temp passwords retired", { retired });
});

/**
 * Suspends venues whose subscription has run out. See ADR-0076.
 *
 * This overturns ADR-0074's central invariant ("nothing auto-suspends on
 * non-payment") deliberately. What survives of that ADR's argument is the reason
 * a **partner** gets `GRACE_AFTER_LAPSE_MS` and a **trial** gets none: a
 * mis-typed date must not take a paying restaurant offline mid-service, whereas
 * a trial going dark on its stated end date is the trial working.
 *
 * Only `active` venues are touched, and only ones with a term — a null
 * `paidUntil` never lapses, so a venue created before anyone set a term sits
 * idle rather than being cut off at creation.
 *
 * **Nothing here has to avoid re-firing.** The editor disables `Aktifkan` while
 * a venue is past its cutoff, so an operator cannot put back what this took
 * down without first giving it a future date — which is the same rule stated
 * from the other end, and needs no `autoSuspendedAt` bookkeeping to hold.
 *
 * Runs hourly beside the temp-password sweep. An hour of slop on a date-grained
 * cutoff is not worth a tighter schedule.
 */
exports.sweepLapsedSubscriptions = onSchedule("every 60 minutes", async () => {
  const now = Date.now();
  // The widest term that could possibly be due, so the query stays a range scan
  // rather than a full collection read. The per-plan cutoff is applied below.
  const newest = Timestamp.fromMillis(now);
  const live = await db
    .collection("venues")
    .where("status", "==", "active")
    .where("paidUntil", "<", newest)
    .get();

  let suspended = 0;
  for (const doc of live.docs) {
    const paidUntil = doc.get("paidUntil");
    if (!paidUntil) continue;
    const grace = doc.get("plan") === "trial" ? 0 : GRACE_AFTER_LAPSE_MS;
    if (paidUntil.toMillis() + grace >= now) continue;
    try {
      await doc.ref.update({ status: "suspended" });
      await writeFleetAudit(
        SYSTEM_ACTOR,
        "autoSuspendVenue",
        { type: "venue", id: doc.id, name: doc.get("name") },
        { status: "active", plan: doc.get("plan"), paidUntil },
        { status: "suspended" },
      );
      suspended++;
    } catch (e) {
      // One broken venue must not strand the rest of the sweep.
      logger.error("subscription sweep failed", { vid: doc.id, err: String(e) });
    }
  }
  if (suspended > 0) logger.info("venues auto-suspended", { suspended });
});

// ── Venue lifecycle ──────────────────────────────────────────────────────────

exports.createVenue = onCall(async (request) => {
  const actor = await assertSuper(request);
  const name = reqStr(request.data, "name");
  const address = (request.data.address || "").toString().trim();
  const plan = (request.data.plan || "trial").toString().trim();
  // Plan only, no term (ADR-0076). A null `paidUntil` never lapses, so a venue
  // created here waits for someone to open the editor and decide how long it
  // runs rather than inheriting a default length nobody chose.
  const ref = await db.collection("venues").add({
    name,
    address,
    status: "active",
    plan,
    trialStartAt: plan === "trial" ? FieldValue.serverTimestamp() : null,
    paidUntil: null,
    priceMonthly: null,
    billingCycle: "monthly",
    lastSeenAt: null,
    createdAt: FieldValue.serverTimestamp(),
  });
  await writeFleetAudit(actor, "createVenue", { type: "venue", id: ref.id, name }, null, {
    address,
    status: "active",
    plan,
  });
  return { vid: ref.id };
});

exports.updateVenue = onCall(async (request) => {
  const actor = await assertSuper(request);
  const vid = reqStr(request.data, "vid");
  const patch = {};
  if (typeof request.data.name === "string") patch.name = request.data.name.trim();
  if (typeof request.data.address === "string") patch.address = request.data.address.trim();
  if (Object.keys(patch).length === 0) {
    throw new HttpsError("invalid-argument", "Nothing to update.");
  }
  const ref = db.collection("venues").doc(vid);
  const prev = await ref.get();
  await ref.update(patch);
  await writeFleetAudit(
    actor,
    "updateVenue",
    { type: "venue", id: vid, name: prev.get("name") },
    auditFields(prev, Object.keys(patch)),
    patch,
  );
  return { ok: true };
});

// The kill switch. Audited above all the others: this is the act that takes a
// restaurant offline mid-service, and "who did this and when" is the first
// question asked afterwards.
exports.setVenueStatus = onCall(async (request) => {
  const actor = await assertSuper(request);
  const vid = reqStr(request.data, "vid");
  const status = reqStatus(request.data);
  const ref = db.collection("venues").doc(vid);
  const prev = await ref.get();
  await ref.update({ status });
  await writeFleetAudit(
    actor,
    "setVenueStatus",
    { type: "venue", id: vid, name: prev.get("name") },
    auditFields(prev, ["status"]),
    { status },
  );
  return { ok: true };
});

exports.setVenueBilling = onCall(async (request) => {
  const actor = await assertSuper(request);
  const vid = reqStr(request.data, "vid");
  const patch = {};
  if (typeof request.data.plan === "string") {
    const plan = request.data.plan.trim();
    if (!PLANS.includes(plan)) {
      throw new HttpsError("invalid-argument", `plan must be one of ${PLANS}.`);
    }
    patch.plan = plan;
  }
  if (typeof request.data.billingCycle === "string") {
    const cycle = request.data.billingCycle.trim();
    if (!CYCLES.includes(cycle)) {
      throw new HttpsError("invalid-argument", `billingCycle must be one of ${CYCLES}.`);
    }
    patch.billingCycle = cycle;
  }
  // A negative rate would sail through and read as a discount on every surface
  // that formats it, so it is refused rather than clamped — the operator typed
  // something they did not mean and should see that.
  if (typeof request.data.priceMonthly === "number") {
    const price = Math.trunc(request.data.priceMonthly);
    if (!(price >= 0)) {
      throw new HttpsError("invalid-argument", "priceMonthly must not be negative.");
    }
    patch.priceMonthly = price;
  } else if (request.data.priceMonthly === null) {
    patch.priceMonthly = null;
  }
  for (const key of ["trialStartAt", "paidUntil"]) {
    if (typeof request.data[key] === "number") {
      patch[key] = Timestamp.fromMillis(request.data[key]);
    } else if (request.data[key] === null) {
      patch[key] = null;
    }
  }
  if (Object.keys(patch).length === 0) {
    throw new HttpsError("invalid-argument", "Nothing to update.");
  }
  const ref = db.collection("venues").doc(vid);
  const prev = await ref.get();
  await ref.update(patch);
  await writeFleetAudit(
    actor,
    "setVenueBilling",
    { type: "venue", id: vid, name: prev.get("name") },
    auditFields(prev, VENUE_BILLING_KEYS),
    patch,
  );
  return { ok: true };
});

exports.deleteVenue = onCall(async (request) => {
  const actor = await assertSuper(request);
  const vid = reqStr(request.data, "vid");
  const admins = await db.collection("admins").where("venueId", "==", vid).limit(1).get();
  if (!admins.empty) {
    throw new HttpsError("failed-precondition", "Venue still has admins.");
  }
  const ref = db.collection("venues").doc(vid);
  const prev = await ref.get();
  await ref.delete();
  await writeFleetAudit(
    actor,
    "deleteVenue",
    { type: "venue", id: vid, name: prev.get("name") },
    auditFields(prev, ["address", "status", ...VENUE_BILLING_KEYS]),
    null,
  );
  return { ok: true };
});
