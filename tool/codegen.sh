#!/usr/bin/env bash
# Deterministic codegen for satset.
# Scope: freezed/json_serializable for lib/{domain,data}/models/**
# and drift for lib/server/db/**.
set -euo pipefail

cd "$(dirname "$0")/.."

# `--delete-conflicting-outputs` was removed in build_runner 2.15 — it now
# warns and ignores it rather than failing, which is the quiet kind of stale
# flag that survives for years. Conflicting outputs are resolved by the
# builder itself now; there is nothing to pass.
dart run build_runner build --release
