# ADR-0059 — Password recovery goes through the developer

## Status

Accepted. Covers the admin email/password form on `PinScreen` only. The fleet
console's own reset (`functions/index.js` `resetAdminPassword`, called from
`venue_edit_screen.dart`) is a different surface and is untouched.

## Context

Two faults sat on the same form.

`SatField` welded obscuring to one kind: `obscureText: _kind == _Kind.pin`.
The admin password used `SatField.text`, so it was rendered in plaintext on a
shared Android device. Worse, the screen built its own eye button and tracked
`_showAdminPw`, so the icon flipped between `visibility_outlined` and
`visibility_off_outlined` on tap while the characters never changed. The
control advertised a state it did not have — the failure mode that hides a bug
rather than showing it.

Recovery, meanwhile, went through `FirebaseAuth.sendPasswordResetEmail`. It
worked, but it assumes the owner can reach the inbox they registered with, on
a device that may be a shared tablet with no mail client, in a venue whose
internet is the thing that failed.

## Decision

**`SatField.password` owns the mask and the eye together.** A new `_Kind`, a
factory taking `visible` + `onToggle`, and the reveal button built into the
decoration. The parent still holds the bool — `PinScreen` already did, and a
field that hid its own reveal state could not be driven from a settings-level
"show passwords" switch later. Every screen that rolled this by hand got the
icon right and the masking wrong; shipping them as one unit is what stops that
recurring. Not a parameter on `.text`: an `obscure` flag there would have left
the eye as the caller's problem, which is exactly the half that was broken.

Not `SatField.pin` either — that forces `digitsOnly` and a number keyboard, so
an alphanumeric password becomes untypeable.

**"Lupa password?" opens the developer's WhatsApp.** The button validates the
email as before, then launches
`https://wa.me/<devWhatsApp>?text=<prefilled>` carrying the typed address. The
admin taps Send; a human resets it.

**The Firebase reset path is deleted, not kept as a fallback.**
`sendAdminPasswordReset` and `sendPasswordReset` had one caller each — this
button — so they became dead code. Two recovery paths on one tap would have
meant a snackbar explaining which one fired.

**The number is hardcoded** (`AppStrings.devWhatsApp`). This button is pressed
by someone who cannot log in, on a device that may be unpaired or offline. A
number fetched from Firestore fails exactly when it is needed, and would have
required a hardcoded fallback anyway — two sources of truth for one string.

**The email gate stays.** Blank or malformed email shows the inline error and
WhatsApp never opens. The developer cannot act on a request that does not name
an account, so an empty one is a message wasted on both ends.

## Consequences

- Recovery now depends on a human answering WhatsApp. There is no automated
  path left. This is slower than a reset email and has no out-of-hours story;
  it was chosen deliberately over a self-serve flow the owner often cannot
  complete.
- The reset request travels through a third-party chat, and the support number
  ships in the APK where anyone unpacking it can read it. Fine for a published
  support line — it must not be reused as anything trusted.
- New dependency: `url_launcher`. Android 11+ hides other packages, so
  `AndroidManifest.xml` gains a `<queries>` intent for `VIEW` + `https`
  alongside the existing `PROCESS_TEXT` one.
- No `canLaunchUrl` gate. `wa.me` is an https link: it resolves to WhatsApp
  when installed and to the browser's "Continue to chat" page when not, so
  there is no missing-app dead end to guard. The `catch` only covers a device
  with no https handler at all, and says so plainly.
- `PinScreen` sheds its hand-built eye suffix; `_showAdminPw` and its setter
  stay where they were and now actually mask.
