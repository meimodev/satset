// One-off local backfill making a trial's implicit entitlement explicit
// (ADR-0108). NOT a deployed function (only index.js exports deploy). Runs
// locally via Application Default Credentials, so it needs no super-admin
// password.
//
// Until ADR-0108, `hasModule` read `isTrial || addOns.contains(key)` — a trial
// held every module while storing `addOns: []`. That short-circuit is gone, so
// every existing trial must be written the set it already had, or both modules
// vanish from every live trial the moment a new APK reads the document.
//
// **Run this against prod BEFORE the APK ships.** An old APK still computes the
// implicit rule and is unharmed by the write; a new APK on an un-backfilled
// trial is.
//
// Writes the full MODULES set to every `plan == "trial"` venue
// unconditionally — not just the ones with an empty `addOns`. The job is to
// record the entitlement a trial *actually has today*, which is all of them;
// a partial set left on the document is a value nobody chose (the control was
// inert on a trial) and preserving it would take a module away silently.
//
// Partners are untouched: `isTrial` was the only implicit, so their stored
// `addOns` was already the honest answer.
//
// Run once:
//   gcloud auth application-default login         # interactive, one time
//   node functions/backfill_trial_modules.local.js
//
// Idempotent. Safe to re-run.
const admin = require("firebase-admin");

// Keep in step with MODULES in index.js.
const MODULES = ["members", "selfOrder"];

admin.initializeApp({ projectId: "satset-3a795" });
const db = admin.firestore();

(async () => {
  const snap = await db.collection("venues").where("plan", "==", "trial").get();
  let written = 0;
  let already = 0;
  let failed = 0;
  for (const doc of snap.docs) {
    const had = doc.get("addOns") || [];
    const same =
      had.length === MODULES.length && MODULES.every((m) => had.includes(m));
    if (same) {
      already++;
      console.log(`  · ${doc.id}  ${doc.get("name") || "—"}  already full`);
      continue;
    }
    try {
      await doc.ref.update({ addOns: [...MODULES] });
      written++;
      console.log(
        `  ✓ ${doc.id}  ${doc.get("name") || "—"}  [${had.join(",")}] → [${MODULES.join(",")}]`,
      );
    } catch (e) {
      failed++;
      console.log(`  ✗ ${doc.id}  ${e.message}`);
    }
  }
  console.log(
    `\nDone. trials=${snap.size} written=${written} already=${already} failed=${failed}`,
  );
  process.exit(failed === 0 ? 0 : 1);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
