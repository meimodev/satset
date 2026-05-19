# SatSet — Technical Specification

**Platform:** Flutter (Android only, API 29+ / Android 10+)  
**Architecture:** Single app, dual-mode (Server / Client), fully offline over LAN  
**Design System:** Heritage Hospitality (Material 3)  
**Date:** 2026-04-30

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Technology Stack](#2-technology-stack)
3. [Project Structure](#3-project-structure)
4. [Data Model & SQLite Schema](#4-data-model--sqlite-schema)
5. [WebSocket Protocol](#5-websocket-protocol)
6. [Navigation & Route Design](#6-navigation--route-design)
7. [State Management (Riverpod)](#7-state-management-riverpod)
8. [Data Flow Architecture](#8-data-flow-architecture)
9. [Feature Modules](#9-feature-modules)
10. [Networking & LAN Discovery](#10-networking--lan-discovery)
11. [Authentication & Roles](#11-authentication--roles)
12. [Offline Resilience](#12-offline-resilience)
13. [Design System Implementation](#13-design-system-implementation)
14. [Build Configuration](#14-build-configuration)
15. [Testing Strategy](#15-testing-strategy)
16. [Milestones](#16-milestones)

---

## 1. Architecture Overview

```
┌──────────────────────────────────────────────────────────┐
│                    Local WiFi / LAN                       │
│                                                           │
│  ┌─────────────────┐            ┌──────────────────────┐  │
│  │  Waiter Handheld │            │   Kitchen Tablet      │  │
│  │  (Client Mode)   │──WS──────→│   (Server Mode)       │  │
│  │                  │←──WS──────│                       │  │
│  └─────────────────┘            │  ┌─────────────────┐  │  │
│                                  │  │ SQLite (drift)  │  │  │
│  ┌─────────────────┐            │  │ WebSocket Server│  │  │
│  │  Admin Tablet    │──WS──────→│  │ mDNS Advertiser │  │  │
│  │  (Client Mode)   │←──WS──────│  └─────────────────┘  │  │
│  └─────────────────┘            └──────────────────────┘  │
│                                                           │
│  ┌─────────────────┐                                     │
│  │  Bar Tablet      │──WS──────→  (same server)          │
│  │  (Client Mode)   │←──WS──────                         │
│  └─────────────────┘                                     │
└──────────────────────────────────────────────────────────┘
```

### Mode Selection

A single Flutter APK runs in one of two modes, selected at startup:

| Mode   | Role                                      | Services Started                          |
|--------|-------------------------------------------|-------------------------------------------|
| Server | Kitchen tablet or dedicated admin device  | SQLite DB, WebSocket server, mDNS advertiser |
| Client | Waiter handheld, bar tablet, admin tablet | Connects to server via WebSocket           |

Mode is persisted in `SharedPreferences`. The first-run experience offers a choice: "Set up as Kitchen Server" or "Connect to Existing Server".

A device in Server mode also runs the full client UI — the server runs within the same Dart process (no separate isolate needed for initial release).

---

## 2. Technology Stack

| Concern               | Choice                          | Rationale                                          |
|-----------------------|---------------------------------|----------------------------------------------------|
| Framework             | Flutter 3.x (stable)            | Single codebase, Android target                    |
| Language              | Dart 3.x                        | Null safety, patterns                              |
| State Management      | Riverpod 2.x                    | Chosen by team; reactive, testable, compile-safe   |
| Navigation            | GoRouter                        | Declarative, path-based, guard support             |
| Database (Server)     | drift (SQLite)                  | Type-safe queries, migrations, reactive streams    |
| Database (Client)     | drift (in-memory)               | Ephemeral cache only for MVP                        |
| WebSocket Server      | `web_socket_channel` + `shelf`  | Lightweight, Dart-native                            |
| WebSocket Client      | `web_socket_channel`            | Same package for client connections                |
| mDNS                  | `multicast_dns`                 | Zero-config service discovery on LAN               |
| Code Generation       | `build_runner` + `freezed`      | Immutable models, JSON serialization               |
| JSON Serialization    | `json_serializable`             | Generated from/to JSON for DB & WebSocket          |
| Audio (post-MVP)      | `audioplayers`                  | Order notification sounds                          |
| Haptics (post-MVP)    | `HapticFeedback` (Flutter SDK)  | Vibration on order-ready                           |
| Icons                 | Material Symbols (`Icons`)      | Bundled with Flutter, 1pt stroke variants          |
| DI                    | Riverpod `ProviderScope`        | No external DI package needed                      |

### Key Packages (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  go_router: ^14.0.0
  drift: ^2.21.0
  sqlite3_flutter_libs: ^0.5.0
  web_socket_channel: ^2.4.0
  shelf: ^1.4.0
  shelf_web_socket: ^2.0.0
  multicast_dns: ^0.3.2
  freezed_annotation: ^2.4.0
  json_annotation: ^4.8.0
  shared_preferences: ^2.2.0
  path_provider: ^2.1.0
  path: ^1.9.0
  crypto: ^3.0.0
  uuid: ^4.0.0
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  drift_dev: ^2.21.0
  freezed: ^2.5.0
  json_serializable: ^6.7.0
  riverpod_generator: ^2.4.0
  mocktail: ^1.0.0
  integration_test:
    sdk: flutter
```

---

## 3. Project Structure

```
satset/
├── android/                          # Android platform config
│   └── app/
│       └── build.gradle.kts          # minSdk = 29, targetSdk = 34
├── assets/
│   ├── fonts/
│   │   ├── NotoSerif-Medium.ttf
│   │   ├── NotoSerif-SemiBold.ttf
│   │   ├── BeVietnamPro-Regular.ttf
│   │   ├── BeVietnamPro-Medium.ttf
│   │   └── BeVietnamPro-SemiBold.ttf
│   └── sounds/                       # Post-MVP: notification audio files
├── lib/
│   ├── main.dart                     # Entry point, ProviderScope, mode init
│   ├── app.dart                      # MaterialApp.router, ThemeData
│   │
│   ├── core/                         # Shared infrastructure
│   │   ├── constants.dart
│   │   ├── exceptions.dart
│   │   ├── extensions.dart
│   │   └── utils.dart
│   │
│   ├── design/                       # Design system (from DESIGN.md)
│   │   ├── theme.dart                # heritageTheme(), darkTheme()
│   │   ├── colors.dart               # All color token constants
│   │   ├── typography.dart           # TextTheme, font declarations
│   │   ├── spacing.dart              # Spacing constants & helpers
│   │   ├── shapes.dart               # BorderRadius constants
│   │   ├── shadows.dart              # BoxShadow helpers
│   │   └── components/               # Shared design-level widgets
│   │       ├── sat_button.dart       # Primary / Secondary / Tertiary
│   │       ├── sat_card.dart         # High-density card with Taupe border
│   │       ├── sat_input.dart        # Bottom-border text field
│   │       ├── sat_chip.dart         # Status chip (tertiary fill)
│   │       ├── sat_divider.dart      # 0.5px Taupe line
│   │       └── sat_list_tile.dart    # Dense divided list row
│   │
│   ├── models/                       # Freezed data models
│   │   ├── user.dart
│   │   ├── zone.dart
│   │   ├── table.dart
│   │   ├── category.dart
│   │   ├── menu_item.dart
│   │   ├── modifier_group.dart
│   │   ├── order.dart
│   │   ├── order_item_modifier.dart
│   │   └── inventory_item.dart
│   │
│   ├── database/                     # drift database (server-side)
│   │   ├── database.dart             # @DriftDatabase definition
│   │   ├── tables.dart               # All table definitions
│   │   ├── daos/
│   │   │   ├── user_dao.dart
│   │   │   ├── zone_dao.dart
│   │   │   ├── table_dao.dart
│   │   │   ├── menu_dao.dart
│   │   │   ├── order_dao.dart
│   │   │   └── inventory_dao.dart
│   │   └── seed.dart                 # Initial sample data seeder
│   │
│   ├── websocket/                    # WebSocket protocol
│   │   ├── protocol.dart             # Message type enum, base class
│   │   ├── messages.dart             # All message classes (freezed)
│   │   ├── codec.dart                # Encode/decode via json_serializable
│   │   ├── server.dart               # WebSocket server (shelf + ws)
│   │   ├── client.dart               # WebSocket client with reconnect
│   │   └── sync.dart                 # Initial sync protocol
│   │
│   ├── network/                      # LAN networking
│   │   ├── discovery.dart            # mDNS advertiser + browser
│   │   └── connection_service.dart   # Manage server connection state
│   │
│   ├── auth/                         # Authentication
│   │   ├── auth_service.dart         # Login/logout, credential verification
│   │   ├── auth_state.dart           # Riverpod auth state
│   │   └── screens/
│   │       └── login_screen.dart     # Role-based login UI
│   │
│   ├── router/                       # GoRouter configuration
│   │   └── app_router.dart           # Route definitions, guards
│   │
│   ├── features/                     # Feature modules
│   │   ├── setup/
│   │   │   ├── setup_screen.dart
│   │   │   └── setup_providers.dart
│   │   │
│   │   ├── zone_map/
│   │   │   ├── zone_map_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── table_grid.dart
│   │   │   │   ├── table_tile.dart
│   │   │   │   ├── zone_section.dart
│   │   │   │   └── status_legend.dart
│   │   │   └── providers/
│   │   │       └── zone_map_providers.dart
│   │   │
│   │   ├── product_matrix/
│   │   │   ├── product_matrix_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── category_filter_bar.dart
│   │   │   │   └── menu_item_tile.dart
│   │   │   └── providers/
│   │   │       └── menu_providers.dart
│   │   │
│   │   ├── tickets/
│   │   │   ├── tickets_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── ticket_card.dart
│   │   │   │   └── ticket_item_row.dart
│   │   │   └── providers/
│   │   │       └── order_providers.dart
│   │   │
│   │   ├── admin/
│   │   │   ├── admin_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── inventory_category_card.dart
│   │   │   │   ├── inventory_item_row.dart
│   │   │   │   └── search_bar.dart
│   │   │   └── providers/
│   │   │       └── inventory_providers.dart
│   │   │
│   │   ├── order_taking/
│   │   │   ├── order_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── menu_category_tabs.dart
│   │   │   │   ├── menu_item_card.dart
│   │   │   │   ├── modifier_sheet.dart
│   │   │   │   └── order_summary.dart
│   │   │   └── providers/
│   │   │       └── order_taking_providers.dart
│   │   │
│   │   └── table_detail/
│   │       ├── table_detail_screen.dart
│   │       ├── widgets/
│   │       │   ├── active_order_card.dart
│   │       │   └── order_timeline.dart
│   │       └── providers/
│   │           └── table_detail_providers.dart
│   │
│   └── widgets/                      # App-level shared widgets
│       ├── top_app_bar.dart
│       ├── bottom_nav_bar.dart
│       └── connection_badge.dart
│
├── test/
│   ├── models/
│   ├── database/
│   ├── websocket/
│   ├── features/
│   └── design/
│
├── integration_test/
│   └── app_test.dart
│
├── pubspec.yaml
├── analysis_options.yaml
└── TECH_SPEC.md
```

---

## 4. Data Model & SQLite Schema

All tables live in a single drift database on the server device.

### 4.1 Entity-Relationship Diagram

```
Users
  │
Zones
  │
  └── Tables
        │
Categories
  │
  └── MenuItems ──┐
        │          │
        │    MenuItemModifierGroups
        │          │
ModifierGroups ───┘
  │
  └── ModifierOptions

Orders ────── Tables
  │              │
  └── OrderItems │
        │        │
        │        │ (waiter)
        └── OrderItemModifiers
        │
        └── Users (waiter, chef)

InventoryItems  (standalone, not linked to menu)
```

### 4.2 Table Definitions (drift)

```dart
// tables.dart

@DataClassName('User')
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get username => text().unique()();
  TextColumn get passwordHash => text()();
  TextColumn get role => textEnum<UserRole>()();
  TextColumn get displayName => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

enum UserRole { waiter, chef, manager, admin }

@DataClassName('Zone')
class Zones extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('VenueTable')
class VenueTables extends Table {
  TextColumn get id => text()();
  TextColumn get zoneId => text().references(Zones, #id)();
  TextColumn get label => text()();
  IntColumn get capacity => integer().withDefault(const Constant(4))();
  TextColumn get status => textEnum<TableStatus>().withDefault(const Constant('empty'))();

  @override
  Set<Column> get primaryKey => {id};
}

enum TableStatus { empty, ordering, waiting, ready }

@DataClassName('Category')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MenuItem')
class MenuItems extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  RealColumn get price => real()();
  TextColumn get imageAsset => text().nullable()();
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();
  TextColumn get sku => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ModifierGroup')
class ModifierGroups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get selectionType => textEnum<SelectionType>()();
  BoolColumn get isRequired => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

enum SelectionType { single, multiple }

@DataClassName('ModifierOption')
class ModifierOptions extends Table {
  TextColumn get id => text()();
  TextColumn get modifierGroupId => text().references(ModifierGroups, #id)();
  TextColumn get name => text()();
  RealColumn get priceAdjustment => real().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MenuItemModifierGroup')
class MenuItemModifierGroups extends Table {
  TextColumn get menuItemId => text().references(MenuItems, #id)();
  TextColumn get modifierGroupId => text().references(ModifierGroups, #id)();

  @override
  Set<Column> get primaryKey => {menuItemId, modifierGroupId};
}

@DataClassName('Order')
class Orders extends Table {
  TextColumn get id => text()();
  TextColumn get tableId => text().references(VenueTables, #id)();
  TextColumn get waiterId => text().references(Users, #id)();
  TextColumn get status => textEnum<OrderStatus>().withDefault(const Constant('received'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

enum OrderStatus { received, cooking, ready, served, cancelled }

@DataClassName('OrderItem')
class OrderItems extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text().references(Orders, #id)();
  TextColumn get menuItemId => text().references(MenuItems, #id)();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('OrderItemModifier')
class OrderItemModifiers extends Table {
  TextColumn get id => text()();
  TextColumn get orderItemId => text().references(OrderItems, #id)();
  TextColumn get modifierOptionId => text().references(ModifierOptions, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('InventoryItem')
class InventoryItems extends Table {
  TextColumn get id => text()();
  TextColumn get category => text()();
  TextColumn get name => text()();
  TextColumn get sku => text().unique()();
  TextColumn get unit => text()();
  RealColumn get currentStock => real()();
  RealColumn get lowStockThreshold => real()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
```

### 4.3 Seed Data

On first server boot, if the database is empty, seed with sample data:

- 3 users (admin/chef/waiter)
- 3 zones (Main Floor, Terrace, VIP Gallery)
- ~20 tables across zones
- 4 categories (Signatures, Mains, Beverages, Seasonal)
- ~10 menu items with modifier groups
- Modifier groups: "Doneness" (required/single), "Extras" (optional/multiple)
- ~10 inventory items across Beverages, Spirits, Amenities

---

## 5. WebSocket Protocol

### 5.1 Connection

- **Port:** `8765` (configurable)
- **Path:** `ws://<server-ip>:8765/satset`
- **Format:** JSON text frames
- **Heartbeat:** Client sends `ping` every 15s; server responds `pong`. Disconnect after 30s of silence.

### 5.2 Message Envelope

```json
{
  "type": "<message_type>",
  "id": "<uuid>",
  "timestamp": "<ISO-8601>",
  "payload": { ... }
}
```

### 5.3 Message Catalog

#### Client → Server

| Type                     | Payload                              | Description                              |
|--------------------------|--------------------------------------|------------------------------------------|
| `auth.login`             | `{username, passwordHash}`           | Authenticate user                        |
| `auth.logout`            | `{}`                                 | End session                              |
| `sync.request`           | `{since: timestamp?}`                | Request full/incremental data sync       |
| `order.create`           | `{tableId, items: [{menuItemId, qty, notes, modifierOptionIds}]}` | Submit new order |
| `order.status_update`    | `{orderId, newStatus}`               | Chef changes status                      |
| `order.cancel`           | `{orderId, reason}`                  | Manager cancels order                    |
| `table.status_update`    | `{tableId, newStatus}`               | Waiter updates table status              |
| `menu.toggle_available`  | `{menuItemId, isAvailable}`          | Admin kills/restores item                |
| `inventory.update_stock` | `{inventoryItemId, newStock}`        | Admin updates inventory                  |
| `inventory.create`       | `{category, name, sku, unit, stock}` | Admin adds inventory item                |
| `ping`                   | `{}`                                 | Heartbeat                                |

#### Server → Client

| Type                       | Payload                              | Description                                  |
|----------------------------|--------------------------------------|----------------------------------------------|
| `auth.response`            | `{success, user?, error?}`           | Login result                                 |
| `sync.data`                | `{users, zones, tables, categories, menuItems, modifierGroups, modifierOptions, inventoryItems, activeOrders}` | Full data dump |
| `sync.ack`                 | `{timestamp}`                        | Sync complete confirmation                   |
| `event.order.new`          | `Order`                              | New order broadcast (to kitchen + waiter)     |
| `event.order.updated`      | `{orderId, newStatus, updatedAt}`    | Status change broadcast                      |
| `event.order.cancelled`    | `{orderId}`                          | Cancellation broadcast                       |
| `event.table.updated`      | `VenueTable`                         | Table status change broadcast                |
| `event.menu.updated`       | `MenuItem`                           | Menu item availability change                |
| `event.inventory.updated`  | `InventoryItem`                      | Inventory stock change                       |
| `event.inventory.created`  | `InventoryItem`                      | New inventory item added                     |
| `pong`                     | `{}`                                 | Heartbeat response                           |
| `error`                    | `{code, message}`                    | General error                                |

### 5.4 Sync Flow

1. Client connects → sends `auth.login`
2. Server validates → returns `auth.response`
3. Client sends `sync.request`
4. Server returns `sync.data` with all current state
5. Server returns `sync.ack` — client enters "live" mode
6. Subsequent state changes arrive via `event.*` messages

---

## 6. Navigation & Route Design

### 6.1 Route Table (GoRouter)

| Path                | Screen               | Guard               | Description                  |
|---------------------|----------------------|----------------------|------------------------------|
| `/setup`            | SetupScreen          | None                 | First-run mode selection     |
| `/login`            | LoginScreen          | None                 | Authentication               |
| `/`                 | ZoneMapScreen        | AuthGuard            | Default tab — zone map       |
| `/matrix`           | ProductMatrixScreen  | AuthGuard            | Menu item matrix             |
| `/tickets`          | TicketsScreen        | AuthGuard            | Kitchen order wall           |
| `/admin`            | AdminScreen          | AuthGuard (admin/manager) | Inventory management   |
| `/table/:id`        | TableDetailScreen    | AuthGuard            | Table status + active orders |
| `/order/:tableId`   | OrderScreen          | AuthGuard (waiter)   | Order taking flow            |

### 6.2 Navigation Structure

```
ScaffoldWithNavBar (persistent shell for 4 bottom tabs)
├── Tab 0: ZoneMapScreen      (/)
├── Tab 1: ProductMatrixScreen (/matrix)
├── Tab 2: TicketsScreen       (/tickets)
└── Tab 3: AdminScreen         (/admin)
         ↑ guard: role == admin || role == manager

Modals / push routes (no bottom nav):
├── SetupScreen              (/setup)
├── LoginScreen              (/login)
├── TableDetailScreen        (/table/:id)
├── OrderScreen              (/order/:tableId)
└── ModifierSheet            (bottom sheet, not a route)
```

### 6.3 Route Guards

- **AuthGuard:** Redirects to `/login` if no authenticated session.
- **RoleGuard(roles):** Redirects to `/` if user's role is not in the allowed set.

### 6.4 GoRouter Configuration Sketch

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/setup',
    redirect: (context, state) {
      final isSetup = ref.read(setupCompleteProvider);
      final isLoggedIn = authState.isAuthenticated;
      final loc = state.uri.path;

      if (!isSetup && loc != '/setup') return '/setup';
      if (isSetup && !isLoggedIn && loc != '/login') return '/login';
      if (isLoggedIn && (loc == '/login' || loc == '/setup')) return '/';

      if (loc == '/admin' && authState.user?.role == UserRole.waiter) return '/';

      return null;
    },
    routes: [
      GoRoute(path: '/setup', builder: (_, __) => const SetupScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      ShellRoute(
        builder: (_, __, child) => ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const ZoneMapScreen()),
          GoRoute(path: '/matrix', builder: (_, __) => const ProductMatrixScreen()),
          GoRoute(path: '/tickets', builder: (_, __) => const TicketsScreen()),
          GoRoute(path: '/admin', builder: (_, __) => const AdminScreen()),
        ],
      ),
      GoRoute(path: '/table/:id', builder: (_, state) =>
        TableDetailScreen(tableId: state.pathParameters['id']!)),
      GoRoute(path: '/order/:tableId', builder: (_, state) =>
        OrderScreen(tableId: state.pathParameters['tableId']!)),
    ],
  );
});
```

---

## 7. State Management (Riverpod)

### 7.1 Provider Architecture

```
                       ┌────────────────────┐
                       │   WebSocketClient   │ (raw stream)
                       └─────────┬──────────┘
                                 │ Stream<WsMessage>
                                 ▼
                       ┌────────────────────┐
                       │  messageStreamProv  │ (parsed, typed)
                       └─────────┬──────────┘
                                 │
          ┌──────────────────────┼──────────────────────┐
          ▼                      ▼                       ▼
   ┌──────────────┐     ┌──────────────┐       ┌──────────────┐
   │ zoneProviders │     │orderProviders│       │ menuProviders │
   └──────────────┘     └──────────────┘       └──────────────┘
          │                      │                       │
          └──────────────────────┼───────────────────────┘
                                 ▼
                        ┌────────────────┐
                        │   UI Screens   │
                        └────────────────┘
```

### 7.2 Key Providers

```dart
// ── Infrastructure ──

// Server mode flag (persisted)
final serverModeProvider = StateProvider<bool>((ref) => false);

// Current connection state
final connectionStateProvider = StateProvider<ConnectionState>((ref) =>
  ConnectionState.disconnected);

enum ConnectionState { disconnected, connecting, connected, syncing, error }

// WebSocket message stream (raw)
final messageStreamProvider = StreamProvider<WsMessage>((ref) {
  final client = ref.watch(webSocketClientProvider);
  return client.messageStream;
});

// ── Auth ──

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

class AuthState {
  final bool isAuthenticated;
  final User? user;
}

// ── Zone Map ──

final zonesProvider = StateNotifierProvider<ZoneNotifier, List<Zone>>((ref) {
  return ZoneNotifier(ref);
});

final tablesByZoneProvider = Provider.family<List<VenueTable>, String>((ref, zoneId) {
  final tables = ref.watch(allTablesProvider);
  return tables.where((t) => t.zoneId == zoneId).toList();
});

// ── Menu ──

final categoriesProvider = StateNotifierProvider<CategoryNotifier, List<Category>>((ref) {
  return CategoryNotifier(ref);
});

final menuItemsByCategoryProvider = Provider.family<List<MenuItem>, String>((ref, catId) {
  final items = ref.watch(allMenuItemsProvider);
  return items.where((i) => i.categoryId == catId).toList();
});

// ── Orders / Tickets ──

final activeOrdersProvider = StateNotifierProvider<OrderNotifier, List<Order>>((ref) {
  return OrderNotifier(ref);
});

// ── Order Taking (local state, not synced until "Send") ──

final currentOrderProvider = StateNotifierProvider<CurrentOrderNotifier, DraftOrder>((ref) {
  return CurrentOrderNotifier();
});

// ── Admin Inventory ──

final inventoryProvider = StateNotifierProvider<InventoryNotifier, List<InventoryItem>>((ref) {
  return InventoryNotifier(ref);
});
```

### 7.3 State Synchronization Pattern

All `*Notifier` classes that manage server-side data follow this pattern:

1. Populate on `sync.data` message
2. On `event.*` messages, update local state
3. On user action, send message to server AND optimistically update local state
4. On `error` response from server, roll back optimistic update

---

## 8. Data Flow Architecture

### 8.1 Order Lifespan (End-to-End)

```
WAITER HANDHELD                    SERVER (KITCHEN TABLET)           KITCHEN DISPLAY
─────────────                      ─────────────────────────         ───────────────
1. Tap table on Zone Map
2. View table detail
3. "New Order" button
4. Select items from menu
5. Modifier sheet (if required)
6. "Send Order" ─────────────────→ 7. Persist to SQLite
                                   8. Broadcast event.order.new ────→ 9. Ticket card appears
                                                                     10. Chef taps "Cooking"
                                   11. event.order.updated ←──────── 11. Broadcast
   12. Waiter sees "Cooking" ←──── 12. Broadcast
                                                                     13. Chef taps "Ready"
                                   14. event.order.updated ←──────── 14. Broadcast
   15. Waiter sees "Ready" ←────── 15. Broadcast
   16. Waiter serves, marks table
```

### 8.2 Data Ownership

| Data              | Owner           | Client Access   |
|--------------------|-----------------|------------------|
| Users              | Server (SQLite) | Read on sync     |
| Zones              | Server (SQLite) | Read on sync     |
| Tables             | Server (SQLite) | Read + write status |
| Menu Items         | Server (SQLite) | Read + toggle available (admin) |
| Modifier Groups    | Server (SQLite) | Read on sync     |
| Orders             | Server (SQLite) | Create (waiter), Update status (chef) |
| Inventory          | Server (SQLite) | Read + write (admin/manager) |
| Draft Order        | Client (memory) | Full ownership until "Send" |

---

## 9. Feature Modules

### 9.1 Zone Map Screen (`/`)

**Purpose:** Visual floor plan showing all tables with live status colors.

**Layout (from stitch export):**
- Top App Bar: "FlowServe" branding, user avatar
- Header: "Zone Map" headline, status legend (Occupied/Available/Reserved)
- Content: Bento grid of zone sections per the HTML design

**Table Tile States:**

| Status      | Background              | Border              | Interaction             |
|-------------|-------------------------|----------------------|-------------------------|
| Empty       | `surface` (#FBF9F4)     | `outlineVariant`     | Tap → start order       |
| Ordering    | `primary` (#322214)     | none                 | Tap → view order detail |
| Waiting     | `primaryContainer`      | none                 | Tap → view order detail |
| Ready       | `secondaryFixed`        | none                 | Tap → view ready items  |

**Responsive Grid:**
- Mobile (4 col): Each table tile is `1fr` width, square aspect
- Booth tables span 2 columns with `aspect-ratio: 2/1`

### 9.2 Product Matrix Screen (`/matrix`)

**Purpose:** High-density menu item browser for reference.

**Layout:**
- Header with category filter chips (All Items, Signatures, Seasonal, Beverages)
- Grid: 2 cols mobile — each tile shows icon placeholder, name, price
- Green dot indicator for available items, orange for seasonal

### 9.3 Tickets Screen (Order Wall) (`/tickets`)

**Purpose:** Kitchen display — real-time order queue with urgency colors.

**Layout:**
- Full-width grid of ticket cards (2 cols mobile)
- Each card: 256px tall, color-coded top border

**Urgency Color Coding:**

| Elapsed Time | Border Color | Hex       | Meaning    |
|-------------|--------------|-----------|------------|
| 0–5 min     | Green        | `#16a34a` | Normal     |
| 5–12 min    | Amber        | `#d97706` | Warning    |
| >12 min     | Red          | `#BA1A1A` | Critical   |

**Ticket Card Content:**
- Table number, order type, ticket #
- Elapsed timer (live-updating)
- Scrollable item list with quantities, modifier notes
- Status action buttons (Received → Cooking → Ready)

### 9.4 Admin Screen (`/admin`)

**Purpose:** Inventory management, accessible only to manager/admin roles.

**Layout:**
- Header: "Inventory Management" + search bar + "New Item" button
- Category cards (Beverages, Spirits, Amenities) in a responsive grid
- Each category card: category header, divided list of items with icon, name, SKU, status badge, stock level
- Status badges: "ACTIVE" or "LOW STOCK"

### 9.5 Order Taking Flow (`/order/:tableId`)

**Purpose:** Waiter creates a new order for a table.

**Flow Steps:**
1. **Category Selection:** Horizontal scrollable tab bar
2. **Item Selection:** Grid of menu items. Tap to add to draft.
3. **Modifier Sheet (conditional):** If item has required modifier groups, open bottom sheet automatically.
4. **Order Summary:** Floating bottom bar shows count + total. "Send Order" button.
5. **Send:** Serialize draft → WebSocket → server persists + broadcasts.

**Zero-Typing Enforcement:**
- Modifiers are pre-defined taps (radio buttons for single-select, checkboxes for multi-select)
- Quantity via `+`/`−` stepper buttons
- Notes: quick-tap presets only (no free-text entry)

### 9.6 Table Detail Screen (`/table/:id`)

**Purpose:** View active orders for a table.

**Content:**
- Table header: Table #, capacity, current status chip
- Active orders list
- Actions: "New Order", "Mark as Served"

---

## 10. Networking & LAN Discovery

### 10.1 mDNS Discovery

- **Service Type:** `_satset._ws.local.`
- **Port:** `8765`
- **TXT Records:** `serverName=<device_name>`, `version=<app_version>`

**Server side:**
```dart
final service = MDnsService(
  serviceType: '_satset._ws.local',
  serviceName: deviceName,
  port: 8765,
  properties: {'version': '1.0.0'},
);
await service.advertise();
```

**Client side:**
```dart
final client = MDnsClient();
await client.start();
await for (final service in client.lookup<MdnsService>(
  serviceType: '_satset._ws.local',
)) {
  // Display discovered servers in setup screen
}
```

### 10.2 Manual IP Entry (Fallback)

If no servers are auto-discovered, the Connection screen provides:
- Text field for IP address + port
- "Connect" button
- Connection status indicator

### 10.3 Connection Screen States

```
┌──────────────────────────────────────┐
│          Connect to Server            │
│                                       │
│   ┌─────────────────────────────┐     │
│   │  Searching for servers...    │     │
│   └─────────────────────────────┘     │
│                                       │
│   Discovered Servers:                 │
│   ┌─────────────────────────────┐     │
│   │ Kitchen Tablet               │     │
│   │    192.168.1.105:8765        │     │
│   └─────────────────────────────┘     │
│                                       │
│   ── OR ──                            │
│                                       │
│   Manual IP: [192.168.1.___]:[8765]   │
│   [Connect]                           │
└──────────────────────────────────────┘
```

---

## 11. Authentication & Roles

### 11.1 Credential Storage

- Passwords hashed with SHA-256
- User records stored in server's SQLite database
- Default admin created during seed: `admin` / `admin123`

### 11.2 Auth Flow

1. Client connects WebSocket
2. Client sends `auth.login` with `{username, passwordHash}`
3. Server looks up user, verifies hash
4. Server returns `auth.response { success: true, user: {...} }`
5. Client stores session in memory (Riverpod `AuthState`)

### 11.3 Role Permissions

| Action                         | Waiter | Chef  | Manager | Admin |
|--------------------------------|--------|-------|---------|-------|
| View Zone Map                  | ✓      | ✓     | ✓       | ✓     |
| View Product Matrix            | ✓      | ✓     | ✓       | ✓     |
| View Tickets (Order Wall)      | ✓      | ✓     | ✓       | ✓     |
| Create new order               | ✓      | ✗     | ✓       | ✓     |
| Update order status            | ✗      | ✓     | ✓       | ✓     |
| Cancel order                   | ✗      | ✓     | ✓       | ✓     |
| View Admin / Inventory         | ✗      | ✗     | ✓       | ✓     |
| Update inventory stock         | ✗      | ✗     | ✓       | ✓     |
| Toggle menu availability       | ✗      | ✗     | ✓       | ✓     |
| Manage users                   | ✗      | ✗     | ✗       | ✓     |
| Manage zones/tables            | ✗      | ✗     | ✗       | ✓     |

---

## 12. Offline Resilience

### 12.1 Client-Side Queue

When a client loses WebSocket connection:

1. **Detection:** WebSocket `onDone` / ping timeout (30s no pong)
2. **UI:** Connection badge turns red, shows "Reconnecting..."
3. **Order Queue:** `order.create` messages buffered in-memory
4. **Reconnect:** Exponential backoff (1s, 2s, 4s, 8s, max 30s)
5. **Flush:** On reconnect → authenticate → flush queued messages → request sync

### 12.2 Client-Side Cache

- All synced data held in Riverpod state (in memory)
- UI continues to render from last-known state on disconnect
- Orders created while offline marked with "pending" badge
- No persistent client-side SQLite for MVP

### 12.3 Server Resilience

- All state is in SQLite (durable)
- On restart, server re-advertises via mDNS
- Clients automatically reconnect and re-sync
- No data loss (SQLite is ACID)

---

## 13. Design System Implementation

### 13.1 Theme Setup

The full `ThemeData` from `DESIGN.md` §9 is implemented verbatim in `lib/design/theme.dart`.

### 13.2 Dark Mode (Post-MVP)

Architecture planned but deferred:

```dart
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

themeMode: ref.watch(themeModeProvider),
theme: heritageLightTheme(),
darkTheme: heritageDarkTheme(), // post-MVP
```

Dark palette uses inverse tokens: `inverseSurface: #30312E`, `inverseOnSurface: #F2F1EC`.

### 13.3 Component Map

| Design Spec Element      | Flutter Widget              | File                                  |
|--------------------------|-----------------------------|---------------------------------------|
| Primary Button           | `FilledButton`              | `lib/design/components/sat_button.dart` |
| Secondary Button         | `OutlinedButton`            | `lib/design/components/sat_button.dart` |
| Input Field              | `TextField` + custom style  | `lib/design/components/sat_input.dart` |
| Card                     | `Container` + border        | `lib/design/components/sat_card.dart` |
| Status Chip              | `Chip`                      | `lib/design/components/sat_chip.dart` |
| Divided List             | `ListView.separated`        | `lib/design/components/sat_list_tile.dart` |
| Top App Bar              | Custom widget               | `lib/widgets/top_app_bar.dart` |
| Bottom Nav               | `NavigationBar` (M3)        | `lib/widgets/bottom_nav_bar.dart` |

### 13.4 Key Design Tokens

```dart
// lib/design/colors.dart
class AppColors {
  static const primary = Color(0xFF322214);
  static const primaryContainer = Color(0xFF4A3728);
  static const onPrimary = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFBF9F4);
  static const outlineVariant = Color(0xFFD2C4BB);
  static const error = Color(0xFFBA1A1A);
  static const secondaryFixed = Color(0xFFF2DFCC);
  static const tertiaryContainer = Color(0xFF46392B);
}

// lib/design/spacing.dart
class AppSpacing {
  static const double unit = 4;
  static const double xs = 4;
  static const double sm = 8;
  static const double gutter = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double containerMargin = 24;
  static const double xl = 40;
}

// lib/design/shapes.dart
class AppShapes {
  static const double sm = 4;
  static const double md = 6;
  static const double lg = 8;
  static const double xl = 12;
}
```

---

## 14. Build Configuration

### 14.1 Android (`android/app/build.gradle.kts`)

```kotlin
android {
    namespace = "id.satset.app"
    compileSdk = 34

    defaultConfig {
        applicationId = "id.satset.app"
        minSdk = 29        // Android 10+
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }
}
```

### 14.2 Permissions (`AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE" />
<uses-permission android:name="android.permission.VIBRATE" />  <!-- post-MVP -->
```

### 14.3 Code Generation

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 15. Testing Strategy

### 15.1 Unit Tests

| Layer            | Scope                                      | Package     |
|------------------|--------------------------------------------|-------------|
| Models           | Freezed equality, JSON round-trip           | `flutter_test` |
| Database (drift) | DAO queries, insert/update/delete           | drift in-memory |
| WebSocket codec  | Message encode/decode, protocol compliance  | `flutter_test` |
| Auth             | Hash verification, role checks              | `flutter_test` |
| State notifiers  | Riverpod state transitions                  | `flutter_test` + `mocktail` |

### 15.2 Widget Tests

| Screen               | Key Test Cases                                    |
|----------------------|--------------------------------------------------|
| LoginScreen          | Empty fields, wrong credentials, success redirect |
| ZoneMapScreen        | Table tile states render correct colors           |
| TicketsScreen        | Urgency color boundaries, timer updates            |
| OrderScreen          | Required modifier enforcement, draft validation   |

### 15.3 Integration Tests

- End-to-end: Two emulators on same network → server + client → full order flow
- Reconnection: Kill server → verify client queues → restart → verify flush
- mDNS: Server advertises → client discovers → connection established

### 15.4 Coverage Target

- 80%+ on models, database, WebSocket protocol
- 60%+ on state management notifiers
- Key user flows covered by widget/integration tests

---

## 16. Milestones

### Phase 1: Foundation (Week 1–2)
- Flutter project scaffold with Android config (minSdk 29)
- Heritage Hospitality `ThemeData` implemented
- Design system component library
- Drift database with all tables + DAOs
- Seed data matching Stitch screens
- Freezed models + JSON serialization
- Code generation pipeline working

### Phase 2: Networking & Auth (Week 2–3)
- WebSocket server (shelf + ws) integrated with drift
- WebSocket client with auto-reconnect
- Full message protocol (codec, all message types)
- mDNS advertiser + browser
- Setup screen (server/client mode, mDNS discovery, manual IP)
- Auth service + login screen
- Role-based route guards (GoRouter)

### Phase 3: Core Features (Week 3–5)
- Zone Map screen (live table grid, status colors, zone sections)
- Table Detail screen (active orders, status management)
- Order Taking flow (category tabs → item selection → modifier sheet → send)
- Tickets screen (order wall with live elapsed timers, status buttons)
- Product Matrix screen (category filters, item grid)
- Admin screen (inventory by category, search, stock updates)
- Bottom navigation bar (4 tabs, role-aware)

### Phase 4: Sync & Resilience (Week 5–6)
- Initial data sync protocol
- Real-time event broadcasting
- Offline queue + flush on reconnect
- Connection state UI (badge, reconnecting indicator)
- Optimistic updates with rollback

### Phase 5: Polish (Week 6–7)
- 100ms transitions on all interactive elements
- Empty states for all screens
- Error states (connection lost, invalid data, permission denied)
- Loading skeletons
- Admin: menu item CRUD (add/edit/delete items, modifiers, categories)
- Admin: zone & table management

### Phase 6: Post-MVP (Week 8+)
- Dark mode variant
- Haptic feedback on order-ready
- Audio cues (new order chime, cancellation alert)
- Menu item images
- Order history / reporting
- "Kill item" (mark sold out) with instant broadcast
- Live heatmap (waiting time visualization per table)
- Server failover (secondary device can take over)

---

## Appendix A: WebSocket Server Implementation Sketch

```dart
// lib/websocket/server.dart

class SatSetWebSocketServer {
  final AppDatabase _db;
  final Set<WebSocketChannel> _clients = {};
  HttpServer? _httpServer;
  MdnsService? _mdns;

  Future<void> start({int port = 8765}) async {
    _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, port);

    _mdns = MdnsService(
      serviceType: '_satset._ws.local',
      port: port,
      properties: {'version': '1.0.0'},
    );
    await _mdns!.advertise();

    await for (final HttpRequest request in _httpServer!) {
      if (request.uri.path == '/satset') {
        final channel = WebSocketChannel(
          await WebSocketTransformer.upgrade(request),
        );
        _clients.add(channel);
        _handleClient(channel);
      }
    }
  }

  void _handleClient(WebSocketChannel channel) {
    channel.stream.listen(
      (data) async {
        final message = MessageCodec.decode(data as String);
        final response = await _processMessage(message, channel);
        if (response != null) {
          channel.sink.add(MessageCodec.encode(response));
        }
      },
      onDone: () => _clients.remove(channel),
    );
  }

  void broadcast(WsMessage message) {
    final encoded = MessageCodec.encode(message);
    for (final client in _clients) {
      client.sink.add(encoded);
    }
  }

  Future<void> stop() async {
    await _mdns?.stop();
    await _httpServer?.close();
    for (final client in _clients) {
      await client.sink.close();
    }
    _clients.clear();
  }
}
```

## Appendix B: Drift Database Wiring

```dart
// lib/database/database.dart

@DriftDatabase(
  tables: [
    Users, Zones, VenueTables, Categories, MenuItems,
    ModifierGroups, ModifierOptions, MenuItemModifierGroups,
    Orders, OrderItems, OrderItemModifiers, InventoryItems,
  ],
  daos: [UserDao, ZoneDao, TableDao, MenuDao, OrderDao, InventoryDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await seedDatabase(this);
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'satset.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
```

## Appendix C: Widget Sizing Reference

All dimensions from DESIGN.md:

| Element              | Size / Dimension                        |
|----------------------|-----------------------------------------|
| Touch target minimum | 48×48px                                 |
| Button height        | 48px                                    |
| Card border          | 1px Taupe (`#A39382`)                   |
| Divider              | 0.5px Taupe, 12px vertical space        |
| Icon size            | 20–24px, 1pt stroke                     |
| Chip radius          | 2px                                     |
| Input vertical pad   | 12px                                    |
| Card internal pad    | 12px (compact)                          |
| Screen margin (h)    | 24px                                    |
| Transition duration  | 100ms, `Curves.easeOut`                 |
| Grid columns (mobile)| 4, gutter 12px                          |
| Font: headlines      | Noto Serif (32px, 24px)                 |
| Font: body           | Be Vietnam Pro (18px, 16px, 14px)       |
| Font: labels         | Be Vietnam Pro (12px, ALL-CAPS variant) |
