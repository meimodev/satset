# Venue & Fleet features disappear after restart

Status: reproduced ordering defect fixed, 2026-09-23. Confirmation on affected devices remains outstanding.

## Reported behavior

- Venue & Fleet switches remain ON.
- Membership, the attached member on cart review, and automatic bill-detail opening disappear after restarting the app.
- Both Server and Client devices are affected.
- Features return only after saving Venue & Fleet again; reconnecting does not restore them.
- The recovery screen is the super-admin fleet console. Whether recovery involved changing switches or saving unchanged values is unknown.

## Confirmed code behavior

These features share the runtime `venueSettingsProvider`, but use different gates:

| Behavior | Runtime conditions |
| --- | --- |
| Membership | `membersEnabled` and `members` entitlement |
| Cart member controls and existing member label | Membership plus `memberSplit` mode |
| Automatic settlement navigation | `counterService` mode and `settleAfterSend` switch |

See `lib/data/models/venue_settings_dto.dart:165-189`, `lib/ui/features/menu/cart_line_actions.dart:38-63`, and `lib/ui/features/review/review_screen.dart:409,448,600`.

The cart hides an existing member label when the gate is false; this alone does not establish that stored member attribution was deleted.

[ADR-0128](adr/0128-a-client-caches-the-venue-settings-whole.md) already requires whole-settings caching and reconnect resynchronization. Those mechanisms exist in the current implementation. The fleet mirror writes `modules` and `counterConfig`, but not the venue's `membersEnabled` preference (`lib/data/repositories/auth_repository.dart:699-737`). Cloud switches therefore do not establish the runtime settings value.

No ordinary startup database reset was identified. A possible delayed-preferences edge case is not a demonstrated normal-startup cause: main supplies an already-loaded preferences object, and locale initialization reads preferences before venue settings.

Startup and subsequent cloud changes share `watchVenue` and `_mirrorVenueCloudFields`. Normal authentication establishes the API configuration and session before starting that listener. Failed settings PATCH requests restore the previous provider state. These checks do not support a separate save-only mirror implementation or a missing failed-request rollback as the cause.

This checkout reports `1.0.10+11`, with the whole-settings cache fix in commit `87b6515`. The installed version remains unknown. No Android devices were connected to ADB during this investigation, so runtime evidence was unavailable.

## Reproduced defect: an old response replaces newer settings

The regression test in [../test/venue_settings_ordering_test.dart](../test/venue_settings_ordering_test.dart) uses the real repository and preferences cache with a controlled API:

1. Hold a startup GET response in flight.
2. Complete a settings PATCH with membership, member attachment, counter mode, and automatic settlement enabled. Confirm member attachment is enabled.
3. Deliver the older GET snapshot, which lacks the mode configuration.
4. Assert member attachment and automatic settlement remain enabled in both runtime state and persisted cache.

Before the fix, the check failed: all four flags were false. `_fetch` unconditionally adopted the late response, replacing the more recent PATCH result and caching the regression. This confirms an ordering defect; it does not establish that the same ordering occurred on the reported devices, nor explain why their server would initially return stale settings. The probe specifically demonstrates the member-attachment and automatic-settlement gates, not deletion of member records or the membership preference itself.

Run the regression and existing cache checks with:

```sh
flutter test --no-pub test/venue_settings_ordering_test.dart test/offline_settings_cache_test.dart
```

Implemented after user confirmation: each read captures a revision. A later read or accepted snapshot supersedes that read, so its eventual response or error cannot replace current state, cache, or loading/error status. Live updates are subscribed before the initial fetch, closing the window where startup could miss a settings broadcast. Successful snapshot adoption clears the settings fetch error/loading status.

The regression covers delayed responses and errors after a successful PATCH, a live settings update, and a reconnect read. Existing offline-cache coverage remains applicable. Runtime verification on an affected installation remains necessary to close the original report.

## Next evidence needed

1. If reproducing again, record whether recovery requires changing a switch or merely saving unchanged values; do not infer this from the current report.
2. Identify the installed version/build on both affected devices.
3. On an affected restart, compare cloud configuration, server settings response, and each device's adopted runtime settings. Identify the first divergence before choosing a fix.
4. Distinguish the local membership preference from fleet entitlement, and hidden cart attribution from erased attribution.

No new architecture decision or glossary term has been established. Reuse ADR-0128 unless evidence requires a different policy.
