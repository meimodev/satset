#!/usr/bin/env bash
# Deploys the fleet control plane: functions, Firestore indexes, and the public
# invoker grants that Gen2 callables need but this org's policy blocks.
#
# Idempotent — safe to re-run after every functions change, and you have to:
# the invoker binding is dropped on each deploy (ADR-0016, and see below).
set -euo pipefail

PROJECT="${FIREBASE_PROJECT:-satset-3a795}"
REGION="${FUNCTIONS_REGION:-us-central1}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

say() { printf '\n\033[1;33m▸ %s\033[0m\n' "$1"; }

# The callables the app invokes, read from source so a new one is covered the
# day it is written. Scheduled and background functions are not onCall and are
# deliberately excluded — they are invoked by Google, not by a client.
callables() {
  grep -oE '^exports\.[A-Za-z0-9_]+ = onCall' "$ROOT/functions/index.js" \
    | sed -E 's/^exports\.([A-Za-z0-9_]+).*/\1/'
}

say "APIs"
# Cloud Scheduler backs sweepExpiredTempPasswords (ADR-0075). Without it the
# whole functions deploy fails, not just that one function.
gcloud services enable \
  cloudscheduler.googleapis.com \
  cloudfunctions.googleapis.com \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  eventarc.googleapis.com \
  --project "$PROJECT"

say "Deploy: functions + firestore indexes"
# Rules are not in this list on purpose: they change far less often, and folding
# them in means every routine function deploy can also reshape access control.
(cd "$ROOT" && firebase deploy --only functions,firestore:indexes --project "$PROJECT")

say "Invoker grants"
# Firebase asks Google to make each callable public at deploy time; an org
# policy on this account denies that, so the deploy succeeds and every call
# comes back 401 until the binding is added by hand. Gen2 callables are Cloud
# Run services, so the binding lives there and not on the function — under a
# lowercased name, which is why every command below folds the case.
for fn in $(callables); do
  svc="$(printf '%s' "$fn" | tr '[:upper:]' '[:lower:]')"
  if err="$(gcloud run services add-iam-policy-binding "$svc" \
      --member=allUsers --role=roles/run.invoker \
      --region "$REGION" --project "$PROJECT" 2>&1 >/dev/null)"; then
    printf '  ✓ %s\n' "$fn"
  else
    printf '  ✗ %s — grant failed, this callable will 401\n    %s\n' \
      "$fn" "$(printf '%s' "$err" | tail -1)" >&2
    FAILED=1
  fi
done

say "Verify"
# Cheap proof the grants landed: anything missing allUsers is still 401.
for fn in $(callables); do
  svc="$(printf '%s' "$fn" | tr '[:upper:]' '[:lower:]')"
  gcloud run services get-iam-policy "$svc" --region "$REGION" --project "$PROJECT" \
    --format='value(bindings.members)' 2>/dev/null | grep -q allUsers \
    || { printf '  ✗ %s has no allUsers binding\n' "$fn" >&2; FAILED=1; }
done

if [[ -n "${FAILED:-}" ]]; then
  say "Done with errors — see ✗ above"
  exit 1
fi
say "Done"
