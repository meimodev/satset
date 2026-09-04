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

// The modules a venue can hold à la carte, beside its plan (ADR-0107). These are
// **persisted strings**, same rule as an AuditKind: renaming one silently
// un-entitles every venue holding it. A `trial` holds all of them implicitly and
// stores none, so an empty array on a trial means nothing at all.
const MODULES = ["members", "selfOrder"];

// Kedai mode (ADR-0109). A key of a different kind: it does not unlock a
// feature, it reshapes the app into a counter shop. It rides the same `addOns`
// array — one transport — but it is **outside** the trial's implicit grant,
// because a trial demos the restaurant product. The client reads it through a
// separate fail-closed resolver; see venueHasMode in lib/server/modules.dart.
//
// `bypassKds` (ADR-0115) is the second of the kind and independent of the
// first: the venue has no prep queue, so a sent line is born `ready`. A counter
// shop may still run a cook line and a small restaurant may have none, so
// neither key implies the other.
//
// `memberSplit` (ADR-0118) is the third: a split bill may name a member per
// receipt, so each regular in a party earns points on their own share. It is a
// mode rather than a sellable module for the fail-closed reading — offering a
// per-receipt member picker at a venue that never mirrored would write
// mis-attributed rows into a points ledger that never expires. Meaningless
// without `members`, which the server ANDs it with.
//
// `serviceTerm` (ADR-0127) is the fourth: the venue sells service, not seats,
// so every user-facing "Meja" reads "Layanan · Service". It gates nothing and
// branches no writer — the client resolves it to a locale variant and the
// whole app, struk and exports included, follow. Fail-closed like the rest:
// a restaurant that has not mirrored must not wake up renaming its floor.
//
// `tableExpense` (ADR-0130) is the fifth: a waiter may spend small cash on a
// party out of what that visit is producing, capped at the visit's subtotal and
// photographed. It branches no writer — the bill never learns an expense
// happened — and gates the route plus the affordance. Fail-closed for the
// bluntest reason of the five: fail-open would hand a revenue-reducing write to
// the floor of every venue that has not mirrored yet.
const MODE_MODULES = [
  "counterService",
  "bypassKds",
  "memberSplit",
  "serviceTerm",
  "tableExpense",
];

// Everything `addOns` may contain. Must stay equal to `venueEntitlementKeys` in
// lib/domain/models/venue_module.dart.
const ALL_MODULES = [...MODULES, ...MODE_MODULES];

// The switches Kedai mode is made of. Persisted keys, unrenameable, stored as a
// map of explicit booleans on the venue doc so a key nobody has ticked is
// distinguishable from one this build has not heard of. Must stay equal to
// `counterSwitchKeys` in lib/domain/models/venue_module.dart.
const COUNTER_SWITCHES = [
  "menuHome",
  "anonTakeaway",
  "settleAfterSend",
  "simpleKds",
  "counterQr",
  "ringkasReport",
];

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

/**
 * The release gate (ADR-0087): which builds of SatSet the fleet may run.
 * `min` hard-blocks below it, `recommended` nags the host, `latest` is what the
 * GitHub Release currently holds. Each is a plain MAJOR.MINOR.PATCH string or
 * null; the build number never appears, because CI is free to move it and the
 * release tag never carries it.
 */
const RELEASE_GATE_KEYS = ["min", "recommended", "latest"];
const SEMVER_RE = /^\d+\.\d+\.\d+$/;

/**
 * Orders two version strings. **A null on either side compares equal**: null is
 * "no floor set", not "version zero", and treating it as a version would make
 * `min: null` fail the ordering check against every real `recommended`.
 */
function cmpSemver(a, b) {
  if (!a || !b) return 0;
  const pa = String(a).split(".").map(Number);
  const pb = String(b).split(".").map(Number);
  for (let i = 0; i < 3; i++) {
    if ((pa[i] || 0) !== (pb[i] || 0)) return (pa[i] || 0) < (pb[i] || 0) ? -1 : 1;
  }
  return 0;
}

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

/**
 * Outstanding member debt for a venue, in rupiah, or 0 when unknown.
 *
 * The cloud cannot see Drift, so this reads the figure the host publishes on its
 * own report snapshot (ADR-0036). **Absent reads as zero on purpose**: a host on
 * an older build, or one that has not published since boot, must not be able to
 * block its operator from editing modules. The refusal it feeds (ADR-0107 §7) is
 * a guard against a known debt, not a proof that none exists.
 */
async function venueOpenDebt(vid) {
  try {
    const snap = await db.collection("reports").doc(vid).get();
    const n = snap.get("openDebt");
    return typeof n === "number" && n > 0 ? n : 0;
  } catch (e) {
    logger.warn("openDebt read failed", { vid, err: String(e) });
    return 0;
  }
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
// it never pairs, never runs a server, and only reads its venue's published
// report snapshot — so owners stay uncapped where admins do not (ADR-0077).
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

  // One ACTIVE admin per venue (ADR-0077). The cap counts `active` rather than
  // documents so handing a venue to a new operator is suspend-then-create with
  // no window where the venue has nobody: the outgoing admin's doc survives for
  // the audit trail and stops counting the moment it is suspended. Owners are
  // deliberately not capped — they are powerless on the floor.
  if (role === "admin") {
    const held = await db
      .collection("admins")
      .where("venueId", "==", venueId)
      .where("role", "==", "admin")
      .where("status", "==", "active")
      .limit(1)
      .get();
    if (!held.empty) {
      throw new HttpsError(
        "failed-precondition",
        "Venue already has an active admin. Suspend it before creating another.",
      );
    }
  }

  let user;
  try {
    user = await auth.createUser({ email, password, displayName: name });
  } catch (e) {
    throw new HttpsError("already-exists", e.message || "Could not create user.");
  }

  // Custom claims {role, venueId} ride the admin's Firebase ID token. Their one
  // consumer — a host verifying a joining admin-client offline — was retired
  // with admin-client itself (ADR-0077), so nothing reads these today. They are
  // written anyway because claims are the one thing that cannot be reconstructed
  // cheaply after the fact: `backfillAdminClaims` had to exist for precisely the
  // gap that dropping this line would reopen. One call, no maintenance.
  // Security rules read the Firestore doc, never the token.
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

exports.setAdminStatus = onCall(async (request) => {
  const actor = await assertSuper(request);
  const uid = reqStr(request.data, "uid");
  const status = reqStatus(request.data);
  const ref = db.collection("admins").doc(uid);
  const prev = await ref.get();
  // The same one-active-admin cap as createAdmin, enforced on the other door
  // into `active` (ADR-0077). Without it, reactivating a suspended admin walks
  // a venue back to two — which is exactly the handover sequence in reverse.
  if (status === "active" && prev.get("role") === "admin") {
    const held = await db
      .collection("admins")
      .where("venueId", "==", prev.get("venueId") || "")
      .where("role", "==", "admin")
      .where("status", "==", "active")
      .limit(1)
      .get();
    if (!held.empty && held.docs[0].id !== uid) {
      throw new HttpsError(
        "failed-precondition",
        "Venue already has an active admin. Suspend it first.",
      );
    }
  }
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
    // The plan does not bend entitlement any more (ADR-0108), so a trial that
    // started empty would demo missing half the app. Provisioning branches on
    // the plan; reading never does. A partner starts empty because a module
    // nobody quoted is a module nobody bought.
    addOns: plan === "trial" ? [...MODULES] : [],
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
  // Entitlement rides `updateVenue`, not `setVenueBilling` (ADR-0107 §9):
  // setVenueBilling exists to write the fields that can disagree with *each
  // other* in one act, and a module set cannot disagree with a date.
  if (Array.isArray(request.data.addOns)) {
    const addOns = [...new Set(request.data.addOns.map((m) => String(m).trim()))];
    for (const m of addOns) {
      if (!ALL_MODULES.includes(m)) {
        throw new HttpsError("invalid-argument", `addOns must be a subset of ${ALL_MODULES}.`);
      }
    }
    patch.addOns = addOns;
  }
  // The switches (ADR-0109 §3). Config, not entitlement: written whole, every
  // key with an explicit bool, so unticking one is a value and not an absence.
  // Kept independent of `addOns` on purpose — unticking the mode freezes the
  // switches rather than clearing them, which is the module rule one level down.
  if (request.data.counterConfig && typeof request.data.counterConfig === "object") {
    const cfg = {};
    for (const [k, v] of Object.entries(request.data.counterConfig)) {
      if (!COUNTER_SWITCHES.includes(k)) {
        throw new HttpsError("invalid-argument", `counterConfig keys must be a subset of ${COUNTER_SWITCHES}.`);
      }
      cfg[k] = v === true;
    }
    patch.counterConfig = cfg;
  }
  if (Object.keys(patch).length === 0) {
    throw new HttpsError("invalid-argument", "Nothing to update.");
  }
  const ref = db.collection("venues").doc(vid);
  const prev = await ref.get();
  // A venue still owed money by its own members must not lose the screen it
  // collects on (ADR-0107 §7). An invariant here rather than a warning in the
  // console, because the console is not the only caller.
  if (patch.addOns && !patch.addOns.includes("members")) {
    const had = (prev.get("addOns") || []).includes("members");
    if (had && (await venueOpenDebt(vid)) > 0) {
      throw new HttpsError(
        "failed-precondition",
        "Venue has outstanding member debt; settle or write it off before removing the members module.",
      );
    }
  }
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

/**
 * The super admin's override of the release gate (ADR-0087).
 *
 * Codemagic writes `config/release_gate` from the tag on every release; this is
 * the other way in. It exists for exactly one situation — a `-breaking` tag that
 * should not have been breaking — and it is the only correction that reaches a
 * venue nobody can drive to. Cutting a higher tag takes a CI round trip and then
 * a physical visit to every device, which is a week of outage for a typo.
 *
 * Each field is independently clearable: pass "" to drop a floor entirely.
 * Absent keys are left alone.
 */
exports.setReleaseGate = onCall(async (request) => {
  const actor = await assertSuper(request);
  const ref = db.collection("config").doc("release_gate");
  const prev = await ref.get();

  const patch = {};
  for (const key of RELEASE_GATE_KEYS) {
    if (!(key in (request.data || {}))) continue;
    const raw = request.data[key];
    if (raw === "" || raw === null) {
      patch[key] = null;
      continue;
    }
    if (typeof raw !== "string" || !SEMVER_RE.test(raw.trim())) {
      throw new HttpsError("invalid-argument", `${key} must be MAJOR.MINOR.PATCH or empty.`);
    }
    patch[key] = raw.trim();
  }
  if (Object.keys(patch).length === 0) {
    throw new HttpsError("invalid-argument", "Nothing to set.");
  }

  // min ≤ recommended ≤ latest is an invariant of the write, not something the
  // reader checks. A console that could publish min > latest would block every
  // device in the fleet on a build that does not exist.
  const merged = { ...(prev.exists ? prev.data() : {}), ...patch };
  if (cmpSemver(merged.min, merged.recommended) > 0 || cmpSemver(merged.recommended, merged.latest) > 0) {
    throw new HttpsError("invalid-argument", "Requires min <= recommended <= latest.");
  }

  patch.updatedAt = FieldValue.serverTimestamp();
  patch.updatedBy = actor;
  await ref.set(patch, { merge: true });
  await writeFleetAudit(
    actor,
    "setReleaseGate",
    { type: "config", id: "release_gate", name: null },
    auditFields(prev, RELEASE_GATE_KEYS),
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
