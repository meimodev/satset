// One-off local backfill of admin custom claims {role, venueId} (ADR-0017).
// NOT a deployed function (only index.js exports deploy). Mirrors the
// `backfillAdminClaims` callable but runs locally via Application Default
// Credentials, so it needs no super-admin password.
//
// Run once:
//   gcloud auth application-default login         # interactive, one time
//   node functions/backfill_claims.local.js
//
// Idempotent. Safe to re-run.
const admin = require("firebase-admin");

admin.initializeApp({ projectId: "satset-3a795" });
const db = admin.firestore();
const auth = admin.auth();

(async () => {
  const snap = await db.collection("admins").get();
  let updated = 0;
  let skipped = 0;
  for (const doc of snap.docs) {
    const role = doc.get("role") || "admin";
    const venueId = doc.get("venueId") || "";
    try {
      await auth.setCustomUserClaims(doc.id, { role, venueId });
      updated++;
      console.log(`  ✓ ${doc.id}  role=${role} venueId=${venueId || "—"}`);
    } catch (e) {
      skipped++;
      console.log(`  ✗ ${doc.id}  ${e.message}`);
    }
  }
  console.log(`\nDone. updated=${updated} skipped=${skipped}`);
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
