# SatSet — Agent Instructions

## Overview
Flutter 3.41+ (Android-only, minSdk 29) app for LAN-based restaurant ordering. Single APK runs in either Server or Client mode. Currently UI-first phase with dummy data — no real WebSocket/DB yet.

## Commands
```bash
flutter analyze          # Static analysis (must pass with zero issues)
flutter pub get          # Install dependencies
flutter build apk --debug # Build debug APK (slow first time)
flutter run              # Run on connected device/emulator
```

## Key Architecture
- **State:** Riverpod (`flutter_riverpod`)
- **Routing:** GoRouter with ShellRoute for 4-tab bottom nav
- **Theme:** Heritage Hospitality (Soft Cream `#FBF9F4`, Rich Brown `#4A3728`)
- **Fonts:** Google Fonts package — fetches Noto Serif & Be Vietnam Pro at runtime
- **No codegen** in use yet (no freezed, no drift, no build_runner)

## Directory Layout
```
lib/
├── main.dart              # Entry point, ProviderScope, portrait-only
├── app.dart               # MaterialApp.router with ThemeData, TopAppBar
├── design/                # Design tokens + shared components
│   ├── colors.dart         #   All Heritage Hospitality color tokens
│   ├── theme.dart          #   Full ThemeData (not currently used; app.dart has inline)
│   ├── spacing.dart        #   4/8/12/16/24/40 constants
│   └── components/         #   sat_button, sat_card, sat_input, sat_chip, sat_divider
├── models/                # Plain Dart classes (no freezed)
│   └── dummy_data.dart     #   ALL dummy data — users, zones, tables, orders, menu, inventory
├── auth/                  # AuthState Riverpod notifier + LoginScreen
├── router/                # GoRouter config with ShellRoute + role guards
├── widgets/               # TopAppBar, BottomNavBar
└── features/
    ├── zone_map/           # Zone Map screen with table grid
    ├── product_matrix/     # Menu item matrix
    ├── tickets/            # Kitchen order wall
    ├── admin/              # Inventory management (manager/admin only)
    ├── order_taking/       # Order creation flow with modifier sheet
    └── table_detail/       # Table status + active orders
```

## Auth (Dummy)
- Login screen accepts any password for demo users: `admin`, `chef`, `waiter`, `manager`
- Role-based guards: Admin screen hidden for waiters
- No real credential hashing yet

## Dummy Data
All in `lib/models/dummy_data.dart`:
- 4 users, 3 zones, 18 tables, 4 categories, 12 menu items, 3 modifier groups, 4 orders, 9 inventory items
- Tables have varied statuses (empty/ordering/waiting/ready)
- Orders have realistic elapsed times and items with modifiers
- Modifier groups: "Doneness" (required/single), "Extras" (optional/multi), "Milk" (optional/single)

## Known Gotchas
- Avoid naming class `Table` — conflicts with `dart:ffi`. Use `VenueTable`.
- `AppColors.surfaceVariant` = `#E4E2DD` (added, make sure it's in colors.dart)
- `AppColors.surfaceContainerLow` = `#F5F3EE` (alias for surfaceLow)
- First APK build is slow (Gradle downloads dependencies). Subsequent builds are fast.
- Google Fonts downloads fonts at runtime — requires network on first launch.
