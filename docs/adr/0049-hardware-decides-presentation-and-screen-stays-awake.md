# ADR-0049 — Hardware decides presentation, and the screen stays awake

## Status

Accepted.

## Context

Two service-floor failures, both of them the device fighting the staff rather
than the app being wrong:

1. **The screen slept.** A KDS on a hot line is read for a whole service and
   frequently never touched, so Android's display timeout blanks it exactly when
   it is doing its job. A waiter mid-order loses the screen between one table and
   the next and pays the unlock tax one-handed, tray in the other.
2. **The device rotated.** A phone turned sideways to hand a menu across, or a
   tablet knocked on its mount, re-laid-out the whole screen. Nothing in this app
   benefits from a phone in landscape or a tablet in portrait — the layouts are
   authored one way round per device class.

Nothing existed for either: no `wakelock` dependency, no `SystemChrome` call, no
`android:screenOrientation` on the activity.

## Decision

### Both are native, in `MainActivity.onCreate`

```kotlin
window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

requestedOrientation =
    if (resources.configuration.smallestScreenWidthDp >= 600) {
        ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
    } else {
        ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
    }
```

Five lines, no new dependency. `wakelock_plus` was the alternative for the first
half and buys nothing while the policy is unconditional; the flag is Android's
own answer and this app is Android-only (minSdk 29) by construction.

### Keep-awake is unconditional

Every device, every screen, no setting. `FLAG_KEEP_SCREEN_ON` is scoped to the
window, so Android drops it the moment SatSet backgrounds — the app cannot leak
a wakelock.

The trade is real and accepted: a phone left foregrounded in an apron pocket
burns battery and collects pocket taps. Gating it to tablets, or to the KDS
screen, was rejected because it buys battery the fleet does not need (shift
devices live on a charging pile) at the cost of the one thing this is for — a
screen that is never ambiguous about whether it is still showing your order.

### Device class is `smallestScreenWidthDp >= 600`, not a width read

`context.layout` classifies by *current* width (`>= 1024`), which is
orientation-dependent — and orientation is the thing being decided. A tablet
booted in portrait reads ~800dp wide, classifies as a phone, locks to portrait,
and never reaches landscape. `smallestScreenWidthDp` is the `sw600dp` qualifier:
invariant under rotation, and readable in `onCreate` before the first Flutter
frame, so there is no visible flip at launch.

Tablets get `SENSOR_LANDSCAPE`, so a wall-mounted unit can be remounted either
way up and corrects itself; this deliberately ignores the device's own rotation
lock. Phones get `PORTRAIT` — upside-down is never wanted with a notch and an
earpiece.

Consequence, accepted: **Dart can no longer influence orientation.** A future
screen that needs to opt out (a full-bleed scanner, say) needs a method channel,
not a `SystemChrome` call. No such screen exists today.

### `forcePhoneView` is removed

`forcePhoneViewProvider` let a Server-mode host tablet render the phone layout
via a toggle in the Me screen. With presentation decided by hardware, it is a
runtime override of a decision that is no longer runtime — and worse, a way to
leave a mounted KDS in a state nobody can explain later. ADR-0048 had already
taken the tables screen off it and called the remainder a deliberate
half-measure; this finishes the job.

The provider, its Me-screen toggle (`_LayoutToggleButton`, `a11yToggleLayout`)
and the `app_shell` branch are gone. `AppShell` and `MeScreen` now read
`context.layout.useTabletShell` alone. Previewing the phone layout during
development is now: run it on a phone, or write a widget test with a fixed
surface size.

## Consequences

- Compact-landscape branches in `layout.dart` (`useSideRail`, `topInset`) stay.
  They are not dead: `requestedOrientation` is ignored in Android split-screen
  and multi-window, which minSdk 29 supports, and that path genuinely produces a
  compact-landscape window.
- Verification is manual by nature — neither the flag nor the activity's
  orientation is assertable from Dart. Install on a phone (`sw` ≈ 385) and a
  tablet (`sw` ≈ 800): rotate each and confirm it does not follow; leave each
  idle past its display timeout and confirm it stays lit.
- A 7" tablet sits at exactly `sw600dp` and reads as landscape. That is the
  intended side of the line for a KDS.
