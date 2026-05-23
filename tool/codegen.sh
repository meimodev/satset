#!/usr/bin/env bash
# Deterministic codegen for satset.
# Scope: freezed/json_serializable for lib/{domain,data}/models/**
# and drift for lib/server/db/**.
set -euo pipefail

cd "$(dirname "$0")/.."

dart run build_runner build \
  --delete-conflicting-outputs \
  --release
