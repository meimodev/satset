# A refused visit stays read-only until resolved

**Status:** Accepted — 2026-09-10 — clarifies the refusal behavior in
[ADR-0123](0123-an-offline-settlement-is-a-journal-not-an-intent.md) and
[ADR-0139](0139-a-captured-visit-is-authoritative-until-it-drains.md).

When the host explicitly refuses a captured event, the affected visit becomes
read-only until the contradiction is resolved through the refusal workflow.
Its lines, captured money and refusal details remain visible, and existing
events are preserved for resolution. Staff cannot append new orders, voids,
discounts, payments or bill closure behind the parked chain. Other visits remain
usable.

Allowing further capture behind a refused event would grow a chain whose
prerequisites are already contradicted. We accept the temporary interruption to
service on that visit rather than accumulate further dependent actions. This
is distinct from transport interruption, which still allows ordinary offline
capture under the existing rules, including ADR-0140's missing-history boundary.

Resolution remains the existing human refusal workflow; this decision does not
authorize automatic retries, automatic deletion of captured money, or clearing
the restriction merely because the socket reconnects. Once resolved, ordinary
visit and bill eligibility rules apply again.
