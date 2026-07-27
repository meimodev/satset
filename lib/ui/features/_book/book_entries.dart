import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/admin_grace.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/accounting_report_repository.dart';
import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/data/repositories/order_history_repository.dart';
import 'package:satset/data/repositories/reports_repository.dart';
import 'package:satset/data/repositories/staff_report_repository.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/admin_grace_banner.dart';
import 'package:satset/ui/core/widgets/anim.dart';
import 'package:satset/ui/core/widgets/custom_range_sheet.dart';
import 'package:satset/ui/core/widgets/elapsed_pill.dart';
import 'package:satset/ui/core/widgets/exit_guard.dart';
import 'package:satset/ui/core/widgets/export_sheet.dart';
import 'package:satset/ui/core/widgets/menu_photo.dart';
import 'package:satset/ui/core/widgets/note_line.dart';
import 'package:satset/ui/core/widgets/order_line_card.dart';
import 'package:satset/ui/core/widgets/pin_sheet.dart';
import 'package:satset/ui/core/widgets/ready_banner.dart';
import 'package:satset/ui/core/widgets/ready_toast.dart';
import 'package:satset/ui/core/widgets/sat_app_bar.dart';
import 'package:satset/ui/core/widgets/satset_top_bar.dart';
import 'package:satset/ui/core/widgets/skeleton_card.dart';
import 'package:satset/ui/core/widgets/staff_avatar.dart';
import 'package:satset/ui/core/widgets/status_chip.dart';
import 'package:satset/ui/core/widgets/tablet_chrome.dart';
import 'package:satset/ui/core/widgets/tag_badge_row.dart';
import 'package:satset/ui/features/me/widgets/theme_sheet.dart';

import 'book_stubs.dart';

/// One rendered variation of a widget.
typedef BookBuild = Widget Function(BuildContext context, WidgetRef ref);

class BookState {
  /// Caption printed above the render. Dev-facing English on purpose — this is
  /// a tool, not a screen a guest or a waiter ever sees, so it deliberately
  /// does **not** go through `AppStrings`.
  final String label;
  final BookBuild build;

  /// Why this state is odd, when that is not obvious from looking at it.
  final String? note;
  const BookState(this.label, this.build, {this.note});
}

class BookEntry {
  final String name;
  final String group;
  final String? note;
  final List<BookState> states;
  const BookEntry({
    required this.name,
    required this.group,
    required this.states,
    this.note,
  });
}

// ── Provider plumbing ───────────────────────────────────────────────────────

/// `authStateProvider` is a `StateNotifierProvider<AuthRepository, AuthState>`,
/// so an override has to hand back an `AuthRepository`. The real constructor is
/// inert — it only stores `ref` and `storage` — so subclassing and seeding
/// `state` is safe and starts no listeners, timers or Firebase subscriptions.
class _BookAuth extends AuthRepository {
  _BookAuth(Ref ref, AuthState seed)
    : super(ref: ref, storage: ref.read(secureStorageServiceProvider)) {
    state = seed;
  }
}

Override _auth(AuthState s) =>
    authStateProvider.overrideWith((ref) => _BookAuth(ref, s));

Override _ws(WsConnState s) => wsConnStateProvider.overrideWith((ref) => s);

Override _grace(AdminGrace? g) =>
    adminOfflineGraceProvider.overrideWith((ref) => Stream.value(g));

final _menu = <Override>[
  menuItemsProvider.overrideWith((ref) => BookStubs.menuItems),
  menuTagsByIdProvider.overrideWith((ref) => BookStubs.tags),
];

/// Canned report fetchers so the export sheet can run end to end without a
/// paired server. It will produce a real (empty) PDF/CSV and open the Android
/// share sheet — that is the point, not a leak.
final _exportFetchers = <Override>[
  orderHistoryFetcherProvider.overrideWith(
    (ref) =>
        (ReportsQuery q) async => BookStubs.orderHistory(q),
  ),
  orderHistoryPhotosFetcherProvider.overrideWith(
    (ref) =>
        (OrderHistory h) async => BookStubs.historyPhotos(h),
  ),
  staffReportFetcherProvider.overrideWith(
    (ref) =>
        (ReportsQuery q) async => BookStubs.staffReport(q),
  ),
  accountingReportFetcherProvider.overrideWith(
    (ref) =>
        (ReportsQuery q) async => BookStubs.accountingReport(q),
  ),
];

/// Wraps [child] in its own scope so two states of the same widget can disagree
/// about the world — `SatAppBar` connected *and* disconnected, side by side.
Widget _scope(List<Override> overrides, Widget child) =>
    ProviderScope(overrides: overrides, child: child);

// ── Small helpers used by several entries ───────────────────────────────────

/// Tap target that cycles through [values]. Used where the interesting thing is
/// the transition between two values, not either value on its own.
class _BookCycle<T> extends StatefulWidget {
  final List<T> values;
  final Widget Function(BuildContext, T) builder;
  const _BookCycle({required this.values, required this.builder});

  @override
  State<_BookCycle<T>> createState() => _BookCycleState<T>();
}

class _BookCycleState<T> extends State<_BookCycle<T>> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => setState(() => _i = (_i + 1) % widget.values.length),
      child: widget.builder(context, widget.values[_i]),
    );
  }
}

/// A visible box, so widgets that are pure layout (`ExpandFade`, `PressScale`,
/// `Shimmer`) have something to move.
class _BookSwatch extends StatelessWidget {
  final String text;
  const _BookSwatch(this.text);

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.s3, vertical: Sp.s2h),
      decoration: SatBox.d(
        color: sc.bg2,
        borderRadius: SatR.a(10),
        border: SatB.all(color: sc.border1),
      ),
      child: Text(text, style: SatType.bodyM(color: sc.textMd)),
    );
  }
}

/// Button that opens a sheet. Sheets are entry points, not widgets, so the book
/// launches them rather than rendering them inline.
class _BookLaunch extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _BookLaunch(this.label, this.onTap);

  @override
  Widget build(BuildContext context) =>
      FilledButton(onPressed: onTap, child: Text(label));
}

/// Toggles a child in and out, for the widgets whose whole job is that
/// transition.
class _BookToggle extends StatefulWidget {
  final Widget Function(BuildContext, bool) builder;
  const _BookToggle(this.builder);

  @override
  State<_BookToggle> createState() => _BookToggleState();
}

class _BookToggleState extends State<_BookToggle> {
  bool _on = true;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextButton(
        onPressed: () => setState(() => _on = !_on),
        child: Text(_on ? 'hide' : 'show'),
      ),
      widget.builder(context, _on),
    ],
  );
}

/// Adds and removes list rows, for `AnimatedReflow`.
class _BookGrow extends StatefulWidget {
  final Widget Function(BuildContext, int) builder;
  const _BookGrow(this.builder);

  @override
  State<_BookGrow> createState() => _BookGrowState();
}

class _BookGrowState extends State<_BookGrow> {
  int _n = 2;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          TextButton(
            onPressed: () => setState(() => _n = (_n + 1).clamp(0, 6)),
            child: const Text('add'),
          ),
          TextButton(
            onPressed: () => setState(() => _n = (_n - 1).clamp(0, 6)),
            child: const Text('remove'),
          ),
        ],
      ),
      widget.builder(context, _n),
    ],
  );
}

// ── The catalogue ───────────────────────────────────────────────────────────

const _gMotion = 'Motion';
const _gChrome = 'Chrome';
const _gContent = 'Content';
const _gLoading = 'Loading';
const _gSheets = 'Sheets';

/// Every widget in `lib/ui/core/widgets/`, per `CATALOG.md`.
///
/// Coverage rule, applied per entry: one state for each enum value the widget
/// accepts, one for each meaningful boolean, plus a stress state carrying the
/// longest realistic Indonesian copy. Add an entry here in the same commit as a
/// new shared widget.
List<BookEntry> bookEntries() => [
  // ── Motion ────────────────────────────────────────────────────────────────
  BookEntry(
    name: 'Reveal',
    group: _gMotion,
    note: 'Press ↻ in the app bar to replay every entrance on this page.',
    states: [
      BookState('index: 0', (c, r) => const Reveal(child: _BookSwatch('one'))),
      BookState(
        'staggered index 0…3 (55ms/step)',
        (c, r) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < 4; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: Sp.s1),
                child: Reveal(index: i, child: _BookSwatch('row $i')),
              ),
          ],
        ),
      ),
      BookState(
        'animKey — fires once, ever',
        (c, r) => const Reveal(
          animKey: 'book-reveal-once',
          child: _BookSwatch('scroll-back safe'),
        ),
        note:
            'Replay will not re-animate this one: the key is already in '
            "Reveal's seen-set, which is exactly what stops a recycled "
            'ListView row re-triggering on scroll-back.',
      ),
    ],
  ),
  BookEntry(
    name: 'ExpandFade',
    group: _gMotion,
    states: [
      BookState(
        'toggle present / absent',
        (c, r) => _BookToggle(
          (c, on) => ExpandFade(
            child: on
                ? const _BookSwatch('conditional block')
                : const SizedBox.shrink(),
          ),
        ),
      ),
    ],
  ),
  BookEntry(
    name: 'AnimatedReflow',
    group: _gMotion,
    states: [
      BookState(
        'rows added / removed',
        (c, r) => _BookGrow(
          (c, n) => AnimatedReflow(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < n; i++)
                  Padding(
                    key: ValueKey(i),
                    padding: const EdgeInsets.only(bottom: Sp.s1),
                    child: _BookSwatch('row $i'),
                  ),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
  BookEntry(
    name: 'AnimatedBarFill',
    group: _gMotion,
    states: [
      BookState(
        'factor 0.0 / 0.35 / 1.0',
        (c, r) => Column(
          children: [
            for (final f in const [0.0, 0.35, 1.0])
              Padding(
                padding: const EdgeInsets.only(bottom: Sp.s2),
                child: AnimatedBarFill(
                  factor: f,
                  color: c.sat.accent,
                  track: c.sat.bg3,
                ),
              ),
          ],
        ),
      ),
      BookState(
        'tap to cycle',
        (c, r) => _BookCycle<double>(
          values: const [0.1, 0.5, 0.9, 0.25],
          builder: (c, f) => AnimatedBarFill(
            factor: f,
            color: c.sat.success,
            track: c.sat.bg3,
          ),
        ),
      ),
      BookState(
        'over 1.0 — clamped',
        (c, r) =>
            AnimatedBarFill(factor: 1.8, color: c.sat.urgent, track: c.sat.bg3),
      ),
    ],
  ),
  BookEntry(
    name: 'GrowBarV',
    group: _gMotion,
    states: [
      BookState(
        'mini chart, mixed heights',
        (c, r) => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final h in const [8.0, 26.0, 44.0, 18.0, 52.0, 4.0])
              Padding(
                padding: const EdgeInsets.only(right: Sp.s1),
                child: GrowBarV(
                  height: h,
                  width: Sp.s3,
                  color: c.sat.accent,
                  radius: SatR.a(3),
                ),
              ),
          ],
        ),
      ),
      BookState(
        'zero height',
        (c, r) => GrowBarV(
          height: 0,
          width: Sp.s3,
          color: c.sat.accent,
          radius: SatR.a(3),
        ),
      ),
    ],
  ),
  BookEntry(
    name: 'PressScale',
    group: _gMotion,
    states: [
      BookState(
        'default dip (0.97)',
        (c, r) => const PressScale(child: _BookSwatch('press and hold me')),
      ),
      BookState(
        'exaggerated (0.85)',
        (c, r) => const PressScale(
          pressedScale: 0.85,
          child: _BookSwatch('press and hold me'),
        ),
      ),
    ],
  ),
  BookEntry(
    name: 'AnimatedCount',
    group: _gMotion,
    states: [
      BookState(
        'tap to roll',
        (c, r) => _BookCycle<int>(
          values: const [0, 7, 128, 4210],
          builder: (c, v) => AnimatedCount(
            value: v,
            builder: (c, n) =>
                Text('$n', style: SatType.h1(color: c.sat.textHi)),
          ),
        ),
      ),
    ],
  ),

  // ── Chrome ────────────────────────────────────────────────────────────────
  BookEntry(
    name: 'SatAppBar',
    group: _gChrome,
    note:
        'Each state carries its own auth + WS scope, so connected and '
        'disconnected render together.',
    states: [
      BookState(
        'title, waiter, connected',
        (c, r) => _scope([
          _auth(BookStubs.waiterAuth),
          _ws(WsConnState.open),
        ], const SatAppBar(title: 'Meja')),
      ),
      BookState(
        'connecting',
        (c, r) => _scope([
          _auth(BookStubs.waiterAuth),
          _ws(WsConnState.connecting),
        ], const SatAppBar(title: 'Meja')),
      ),
      BookState(
        'closed',
        (c, r) => _scope([
          _auth(BookStubs.waiterAuth),
          _ws(WsConnState.closed),
        ], const SatAppBar(title: 'Meja')),
      ),
      BookState(
        'admin — network pill visible',
        (c, r) => _scope([
          _auth(BookStubs.adminAuth),
          _ws(WsConnState.closed),
        ], const SatAppBar(title: 'Venue')),
        note:
            'The pill only renders for an admin; a waiter gets the dot alone.',
      ),
      BookState(
        'crumbs + back',
        (c, r) => _scope(
          [_auth(BookStubs.waiterAuth), _ws(WsConnState.open)],
          SatAppBar(
            onBack: () {},
            crumbs: const ['Teras', 'Meja 5', 'Pesanan'],
          ),
        ),
      ),
      BookState(
        'trailing pills',
        (c, r) => _scope(
          [_auth(BookStubs.waiterAuth), _ws(WsConnState.open)],
          const SatAppBar(
            title: 'Dapur',
            trailingPills: [
              SatAppBarPill(icon: Icons.timer_outlined, label: 'T+0:45'),
              SatAppBarPill(label: '12 antre'),
            ],
          ),
        ),
      ),
      BookState(
        'no avatar',
        (c, r) => _scope([
          _auth(BookStubs.waiterAuth),
          _ws(WsConnState.open),
        ], const SatAppBar(title: 'Meja', showAvatar: false)),
      ),
      BookState(
        'signed out',
        (c, r) => _scope([
          _auth(BookStubs.signedOut),
          _ws(WsConnState.closed),
        ], const SatAppBar(title: 'Masuk')),
      ),
      BookState(
        'stress — long title, deep crumbs, three pills',
        (c, r) => _scope(
          [_auth(BookStubs.adminAuth), _ws(WsConnState.connecting)],
          const SatAppBar(
            crumbs: [
              'Lantai Atas Teras Belakang',
              'Meja 24 Gabungan',
              BookStubs.longName,
            ],
            trailingPills: [
              SatAppBarPill(icon: Icons.timer_outlined, label: 'T+12:45'),
              SatAppBarPill(label: '128 antre'),
              SatAppBarPill(label: 'Mode offline'),
            ],
          ),
        ),
      ),
    ],
  ),
  BookEntry(
    name: 'SatAppBarPill',
    group: _gChrome,
    states: [
      BookState('label only', (c, r) => const SatAppBarPill(label: '12 antre')),
      BookState(
        'with icon',
        (c, r) =>
            const SatAppBarPill(icon: Icons.timer_outlined, label: 'T+0:45'),
      ),
      BookState(
        'tinted urgent',
        (c, r) => SatAppBarPill(
          icon: Icons.priority_high_rounded,
          label: 'Lewat target',
          tint: c.sat.urgent,
        ),
      ),
      BookState(
        'stress — long label',
        (c, r) => const SatAppBarPill(label: BookStubs.longName),
      ),
    ],
  ),
  BookEntry(
    name: 'LoginClock',
    group: _gChrome,
    states: [
      BookState('default', (c, r) => const LoginClock()),
      BookState('tinted', (c, r) => LoginClock(textColor: c.sat.accentText)),
    ],
  ),
  BookEntry(
    name: 'SatBackButton',
    group: _gChrome,
    states: [
      BookState('default arrow', (c, r) => SatBackButton(onTap: () {})),
      BookState(
        'close glyph, own label',
        (c, r) => SatBackButton(
          onTap: () {},
          icon: Icons.close_rounded,
          semanticLabel: 'Tutup',
        ),
      ),
    ],
  ),
  BookEntry(
    name: 'TabletSideRail',
    group: _gChrome,
    note:
        'Tapping a rail item navigates for real and leaves the book. Flip the '
        'width control to ▭ so it renders at its intended breakpoint.',
    states: [
      BookState(
        'waiter — tables active',
        (c, r) => _scope(
          [_auth(BookStubs.waiterAuth)],
          const SizedBox(
            height: _railHeight,
            child: TabletSideRail(
              active: 'tables',
              readyCount: 0,
              kitchenCount: 0,
            ),
          ),
        ),
      ),
      BookState(
        'admin — every tab, badges lit',
        (c, r) => _scope(
          [_auth(BookStubs.adminAuth)],
          const SizedBox(
            height: _railHeight,
            child: TabletSideRail(
              active: 'venue',
              readyCount: 3,
              kitchenCount: 12,
              showKasir: true,
              showGuest: true,
              guestCount: 2,
            ),
          ),
        ),
      ),
      BookState(
        'stress — three-digit badges',
        (c, r) => _scope(
          [_auth(BookStubs.adminAuth)],
          const SizedBox(
            height: _railHeight,
            child: TabletSideRail(
              active: 'kitchen',
              readyCount: 147,
              kitchenCount: 268,
              showKasir: true,
              showGuest: true,
              guestCount: 99,
            ),
          ),
        ),
      ),
    ],
  ),
  BookEntry(
    name: 'TabletShell',
    group: _gChrome,
    states: [
      BookState(
        'rail + content',
        (c, r) => _scope(
          [_auth(BookStubs.adminAuth), _ws(WsConnState.open)],
          const SizedBox(
            height: _shellHeight,
            child: TabletShell(
              activeTab: 'venue',
              readyCount: 2,
              kitchenCount: 5,
              showKasir: true,
              crumbs: ['Venue', 'Ringkasan'],
              child: Center(child: _BookSwatch('page content')),
            ),
          ),
        ),
        note: 'Boxed to a fixed height — the real one owns the whole screen.',
      ),
    ],
  ),
  BookEntry(
    name: 'TabletSectionHead',
    group: _gChrome,
    states: [
      BookState(
        'title only',
        (c, r) => const TabletSectionHead(title: 'Ringkasan hari ini'),
      ),
      BookState(
        'title + sub',
        (c, r) => const TabletSectionHead(
          title: 'Ringkasan hari ini',
          sub: '07:00 – sekarang',
        ),
      ),
      BookState(
        'with trailing',
        (c, r) => const TabletSectionHead(
          title: 'Staf aktif',
          sub: '4 orang',
          trailing: SatAppBarPill(label: 'Shift malam'),
        ),
      ),
      BookState(
        'stress — long title and sub',
        (c, r) => const TabletSectionHead(
          title: BookStubs.longName,
          sub: BookStubs.longNote,
          trailing: SatAppBarPill(label: 'Lihat semua'),
        ),
      ),
    ],
  ),
  BookEntry(
    name: 'TabletCard',
    group: _gChrome,
    states: [
      BookState(
        'no header',
        (c, r) => const TabletCard(child: _BookSwatch('body')),
      ),
      BookState(
        'with header',
        (c, r) =>
            const TabletCard(header: 'Penjualan', child: _BookSwatch('body')),
      ),
      BookState(
        'header + trailing',
        (c, r) => const TabletCard(
          header: 'Penjualan',
          headerTrailing: SatAppBarPill(label: 'Hari ini'),
          child: _BookSwatch('body'),
        ),
      ),
      BookState(
        'stress — long header, tall body',
        (c, r) => const TabletCard(
          header: BookStubs.longName,
          headerTrailing: SatAppBarPill(label: '30 hari terakhir'),
          child: Text(BookStubs.longNote),
        ),
      ),
    ],
  ),
  BookEntry(
    name: 'TabletStatTile',
    group: _gChrome,
    states: [
      BookState(
        'plain',
        (c, r) => const TabletStatTile(value: 'Rp 4,2jt', label: 'Omzet'),
      ),
      BookState(
        'tinted value',
        (c, r) => TabletStatTile(
          value: '−Rp 180rb',
          label: 'Dibatalkan',
          valueColor: c.sat.urgent,
        ),
      ),
      BookState(
        'tinted background',
        (c, r) => TabletStatTile(
          value: '18',
          label: 'Meja terisi',
          bg: c.sat.accentSoft,
          valueColor: c.sat.accentText,
        ),
      ),
      BookState(
        'stress — long value and label',
        (c, r) => const TabletStatTile(
          value: 'Rp 1.284.500.000',
          label: 'Total pendapatan kotor sebelum pajak dan layanan',
        ),
      ),
    ],
  ),
  BookEntry(
    name: 'AdminGraceBanner',
    group: _gChrome,
    states: [
      BookState(
        'no grace — renders nothing',
        (c, r) => _scope([_grace(null)], const AdminGraceBanner()),
      ),
      BookState(
        'warn — days remaining',
        (c, r) =>
            _scope([_grace(BookStubs.graceWarn)], const AdminGraceBanner()),
      ),
      BookState(
        'critical — under 24h',
        (c, r) =>
            _scope([_grace(BookStubs.graceCritical)], const AdminGraceBanner()),
      ),
      BookState(
        'expired — already past',
        (c, r) => _scope([
          _grace(const AdminGrace(Duration(hours: -2))),
        ], const AdminGraceBanner()),
      ),
    ],
  ),
  BookEntry(
    name: 'ExitGuard',
    group: _gChrome,
    note:
        'Structural, not visual: a PopScope that turns the second back press '
        'into an exit. Nothing to render — check it by backing out of the app.',
    states: [
      BookState(
        'wraps its child unchanged',
        (c, r) => const ExitGuard(child: _BookSwatch('child')),
      ),
    ],
  ),
  BookEntry(
    name: 'AlertHost',
    group: _gChrome,
    note:
        'Deliberately not mounted here. It is a mount point, not a visual — it '
        'keeps the alert sound service alive and hosts ReadyToast. Mounting it '
        'in the book would make the gallery beep and hold a live router. Its '
        'visible half is the ReadyToast and ReadyBanner entries.',
    states: const [],
  ),

  // ── Content ───────────────────────────────────────────────────────────────
  BookEntry(
    name: 'OrderLineCard',
    group: _gContent,
    note: 'Canonical sent-line card (ADR-0026). Tags resolve off a stub menu.',
    states: [
      for (final s in TicketStatus.values)
        BookState(
          s.name,
          (c, r) => _scope(
            _menu,
            OrderLineCard(
              ticket: BookStubs.ticket(
                status: s,
                ageMinutes: s == TicketStatus.prep ? 22 : 3,
                voidReason: s == TicketStatus.voided
                    ? 'Tamu berubah pikiran'
                    : null,
              ),
              onTap: () {},
              onMarkServed: (_) {},
            ),
          ),
        ),
      BookState(
        'readOnly — no mark-served',
        (c, r) => _scope(
          _menu,
          OrderLineCard(
            ticket: BookStubs.ticket(status: TicketStatus.ready),
            onTap: () {},
            onMarkServed: (_) {},
            readOnly: true,
          ),
        ),
      ),
      BookState(
        'variant + modifiers + note',
        (c, r) => _scope(
          _menu,
          OrderLineCard(
            ticket: BookStubs.ticket(
              status: TicketStatus.sent,
              variantName: 'Porsi Besar',
              qty: 2,
              modifiers: BookStubs.manyModifiers.take(3).toList(),
              note: 'Tanpa sambal.',
            ),
            onTap: () {},
            onMarkServed: (_) {},
          ),
        ),
      ),
      BookState(
        'no orderer — guest self-order',
        (c, r) => _scope(
          _menu,
          OrderLineCard(
            ticket: BookStubs.ticket(
              status: TicketStatus.pendingReview,
              createdBy: null,
            ),
            onTap: () {},
            onMarkServed: (_) {},
          ),
        ),
      ),
      BookState(
        'stress — long name, ×99, 6 modifiers, 2-line note',
        (c, r) => _scope(
          _menu,
          OrderLineCard(
            ticket: BookStubs.stressTicket,
            onTap: () {},
            onMarkServed: (_) {},
          ),
        ),
      ),
    ],
  ),
  BookEntry(
    name: 'StatusChip',
    group: _gContent,
    states: [
      for (final s in TicketStatus.values)
        BookState(s.name, (c, r) => StatusChip(status: s)),
      BookState(
        'tap to cycle — cross-fade on change',
        (c, r) => _BookCycle<TicketStatus>(
          values: TicketStatus.values,
          builder: (c, s) => StatusChip(status: s),
        ),
        note: 'The morph is what a WS push looks like under your thumb.',
      ),
    ],
  ),
  BookEntry(
    name: 'ElapsedPill',
    group: _gContent,
    note:
        'Escalates at the venue default prepTargetMins (15). Driven by the '
        "ticket's age, not a provider override.",
    states: [
      BookState(
        'under a minute',
        (c, r) => ElapsedPill(
          sentAtTime: DateTime.now(),
          sentAtClock: '19:04',
          terminal: false,
        ),
      ),
      BookState(
        'live, within target (3m)',
        (c, r) => ElapsedPill(
          sentAtTime: DateTime.now().subtract(const Duration(minutes: 3)),
          sentAtClock: '19:01',
          terminal: false,
        ),
      ),
      BookState(
        'overdue (42m) — urgent',
        (c, r) => ElapsedPill(
          sentAtTime: DateTime.now().subtract(const Duration(minutes: 42)),
          sentAtClock: '18:22',
          terminal: false,
        ),
      ),
      BookState(
        'terminal — frozen clock',
        (c, r) => ElapsedPill(
          sentAtTime: DateTime.now().subtract(const Duration(minutes: 42)),
          sentAtClock: '18:22',
          terminal: true,
        ),
      ),
      BookState(
        'stress — over an hour',
        (c, r) => ElapsedPill(
          sentAtTime: DateTime.now().subtract(const Duration(hours: 26)),
          sentAtClock: '17:10',
          terminal: false,
        ),
      ),
    ],
  ),
  BookEntry(
    name: 'NoteLine',
    group: _gContent,
    states: [
      BookState('short', (c, r) => const NoteLine(text: 'Tanpa sambal.')),
      BookState(
        'custom label',
        (c, r) => const NoteLine(text: 'Alergi kacang.', label: 'Catatan tamu'),
      ),
      BookState(
        'empty — renders nothing',
        (c, r) => const NoteLine(text: '   '),
      ),
      BookState(
        'stress — two-line note',
        (c, r) => const NoteLine(text: BookStubs.longNote),
      ),
    ],
  ),
  BookEntry(
    name: 'TagBadgeRow',
    group: _gContent,
    note:
        'Returns a bare Flexible, so it only builds as a direct child of a Row '
        'or Column — every state here supplies that Row, and so must you.',
    states: [
      BookState(
        'allergen colouring',
        (c, r) => Row(
          children: [
            TagBadgeRow(
              ids: const ['kacang', 'gluten'],
              tagsById: BookStubs.tags,
              fg: c.sat.urgent,
              bg: c.sat.urgentSoft,
            ),
          ],
        ),
      ),
      BookState(
        'diet colouring',
        (c, r) => Row(
          children: [
            TagBadgeRow(
              ids: const ['vegan', 'halal'],
              tagsById: BookStubs.tags,
              fg: c.sat.info,
              bg: c.sat.infoSoft,
            ),
          ],
        ),
      ),
      BookState(
        'empty ids',
        (c, r) => Row(
          children: [
            TagBadgeRow(
              ids: const [],
              tagsById: BookStubs.tags,
              fg: c.sat.info,
              bg: c.sat.infoSoft,
            ),
          ],
        ),
      ),
      BookState(
        'unresolvable id — renders "?"',
        (c, r) => Row(
          children: [
            TagBadgeRow(
              ids: const ['tidak-ada'],
              tagsById: BookStubs.tags,
              fg: c.sat.urgent,
              bg: c.sat.urgentSoft,
            ),
          ],
        ),
      ),
      BookState(
        'stress — every tag, wraps',
        (c, r) => Row(
          children: [
            TagBadgeRow(
              ids: BookStubs.tags.keys.toList(),
              tagsById: BookStubs.tags,
              fg: c.sat.urgent,
              bg: c.sat.urgentSoft,
            ),
          ],
        ),
      ),
    ],
  ),
  BookEntry(
    name: 'MenuTagBadges',
    group: _gContent,
    states: [
      BookState(
        'allergens + diet, resolved live',
        (c, r) =>
            _scope(_menu, const MenuTagBadges(itemId: BookStubs.taggedItemId)),
      ),
      BookState(
        'item with no tags',
        (c, r) => _scope(
          _menu,
          const MenuTagBadges(itemId: BookStubs.untaggedItemId),
        ),
      ),
      BookState(
        'item not in the menu — shrinks',
        (c, r) => _scope(_menu, const MenuTagBadges(itemId: 'tidak-ada')),
      ),
    ],
  ),
  BookEntry(
    name: 'MenuPhoto',
    group: _gContent,
    note:
        'photoRev > 0 fetches bytes from the paired server, so in the book it '
        'resolves to the same initials fallback — which is the point of '
        'ADR-0014: never a broken image.',
    states: [
      BookState(
        'no photo — initials',
        (c, r) => const SizedBox(
          width: _photoSize,
          height: _photoSize,
          child: MenuPhoto(
            itemId: BookStubs.taggedItemId,
            name: 'Gado-Gado Siram',
            photoRev: 0,
          ),
        ),
      ),
      BookState(
        'single word name',
        (c, r) => const SizedBox(
          width: _photoSize,
          height: _photoSize,
          child: MenuPhoto(itemId: 'x', name: 'Bakso', photoRev: 0),
        ),
      ),
      BookState(
        'empty name',
        (c, r) => const SizedBox(
          width: _photoSize,
          height: _photoSize,
          child: MenuPhoto(itemId: 'x', name: '', photoRev: 0),
        ),
      ),
      BookState(
        'photoRev > 0 — unresolvable, falls back',
        (c, r) => _scope(
          _menu,
          const SizedBox(
            width: _photoSize,
            height: _photoSize,
            child: MenuPhoto(
              itemId: BookStubs.taggedItemId,
              name: 'Gado-Gado Siram',
              photoRev: 3,
            ),
          ),
        ),
      ),
      BookState(
        'stress — long name, small tile',
        (c, r) => const SizedBox(
          width: Sp.s10,
          height: Sp.s10,
          child: MenuPhoto(
            itemId: 'x',
            name: BookStubs.longName,
            photoRev: 0,
            initialsSize: 12,
          ),
        ),
      ),
    ],
  ),
  BookEntry(
    name: 'StaffAvatar',
    group: _gContent,
    states: [
      BookState('waiter', (c, r) => StaffAvatar(actor: BookStubs.waiter)),
      BookState(
        'mine — accent ring',
        (c, r) => StaffAvatar(actor: BookStubs.waiter, mine: true),
      ),
      BookState('kitchen', (c, r) => StaffAvatar(actor: BookStubs.kitchen)),
      BookState('admin', (c, r) => StaffAvatar(actor: BookStubs.admin)),
      BookState(
        'no colour set — falls back',
        (c, r) => StaffAvatar(actor: BookStubs.uncoloured),
      ),
      BookState(
        'no colour, role fallback supplied',
        (c, r) => StaffAvatar(
          actor: BookStubs.uncoloured,
          fallbackColor: c.sat.violet,
        ),
      ),
      BookState(
        'squareUnderBrutal',
        (c, r) => StaffAvatar(actor: BookStubs.admin, squareUnderBrutal: true),
        note: 'Only differs under the two neo (brutal) themes.',
      ),
      BookState(
        '.raw — view-model row',
        (c, r) => const StaffAvatar.raw(initials: 'ZZ', colorHex: null),
      ),
      BookState(
        'size ramp 22 / 32 / 48',
        (c, r) => Row(
          children: [
            for (final s in const [22.0, 32.0, 48.0])
              Padding(
                padding: const EdgeInsets.only(right: Sp.s2),
                child: StaffAvatar(
                  actor: BookStubs.waiter,
                  size: s,
                  mine: true,
                ),
              ),
          ],
        ),
      ),
    ],
  ),
  BookEntry(
    name: 'ReadyBanner',
    group: _gContent,
    states: [BookState('default', (c, r) => const ReadyBanner())],
  ),
  BookEntry(
    name: 'ReadyToast',
    group: _gContent,
    note:
        'Mounted bare here. App code must go through AlertHost — this is a '
        'stage, not a screen.',
    states: [
      BookState(
        'dine-in',
        (c, r) => ReadyToast(
          alert: BookStubs.dineInAlert,
          onView: () {},
          onDismiss: () {},
        ),
      ),
      BookState(
        'takeaway',
        (c, r) => ReadyToast(
          alert: BookStubs.takeawayAlert,
          onView: () {},
          onDismiss: () {},
        ),
      ),
    ],
  ),

  // ── Loading ───────────────────────────────────────────────────────────────
  BookEntry(
    name: 'Shimmer',
    group: _gLoading,
    states: [
      BookState(
        'over a skeleton block',
        (c, r) => const Shimmer(child: SkeletonBox(height: Sp.s12)),
      ),
      BookState(
        'over real content',
        (c, r) => const Shimmer(child: _BookSwatch('any child')),
      ),
    ],
  ),
  BookEntry(
    name: 'SkeletonBox',
    group: _gLoading,
    states: [
      BookState('full width', (c, r) => const SkeletonBox(height: Sp.s5)),
      BookState(
        'fixed width',
        (c, r) => const SkeletonBox(width: _photoSize, height: Sp.s5),
      ),
      BookState(
        'square, sharp corners',
        (c, r) =>
            const SkeletonBox(width: _photoSize, height: _photoSize, radius: 0),
      ),
    ],
  ),
  BookEntry(
    name: 'SkeletonCard',
    group: _gLoading,
    states: [
      BookState('default height (120)', (c, r) => const SkeletonCard()),
      BookState(
        'shortest that fits (86)',
        (c, r) => const SkeletonCard(height: _skeletonFloor),
        note:
            'Its inner column is fixed, so anything under ~86 overflows. Not a '
            'parameter you can take to zero.',
      ),
      BookState(
        'with margin',
        (c, r) => const SkeletonCard(
          height: _skeletonFloor,
          margin: EdgeInsets.symmetric(horizontal: Sp.s6),
        ),
      ),
    ],
  ),
  BookEntry(
    name: 'ReportsSkeleton',
    group: _gLoading,
    states: [
      BookState('KPI row + two charts', (c, r) => const ReportsSkeleton()),
    ],
  ),

  // ── Sheets ────────────────────────────────────────────────────────────────
  BookEntry(
    name: 'showPinSheet',
    group: _gSheets,
    note: 'Returns true on verify, null on dismiss.',
    states: [
      BookState(
        'plain',
        (c, r) => _BookLaunch(
          'open',
          () => showPinSheet(
            c,
            title: 'Masuk',
            subtitle: 'Masukkan PIN 6 digit',
            onSubmit: (pin) async => null,
          ),
        ),
      ),
      BookState(
        'always rejects — shake + error',
        (c, r) => _BookLaunch(
          'open',
          () => showPinSheet(
            c,
            title: 'Masuk',
            subtitle: 'Masukkan PIN 6 digit',
            onSubmit: (pin) async => 'PIN salah. Coba lagi.',
          ),
        ),
      ),
      BookState(
        'slow — busy state',
        (c, r) => _BookLaunch(
          'open',
          () => showPinSheet(
            c,
            title: 'Masuk',
            subtitle: 'Menghubungi server…',
            onSubmit: (pin) async {
              await Future<void>.delayed(const Duration(seconds: 2));
              return null;
            },
          ),
        ),
      ),
      BookState(
        'debug creds + status slot',
        (c, r) => _BookLaunch(
          'open',
          () => showPinSheet(
            c,
            title: 'Masuk',
            subtitle: 'Masukkan PIN 6 digit',
            onSubmit: (pin) async => null,
            debugCreds: const PinDebugCreds(BookStubs.debugPins),
            statusSlot: const _BookSwatch('server terjangkau'),
          ),
        ),
      ),
    ],
  ),
  BookEntry(
    name: 'showCustomRangeSheet',
    group: _gSheets,
    note: 'Returns an inclusive date-only range, or null on dismiss.',
    states: [
      BookState(
        'empty',
        (c, r) => _BookLaunch('open', () => showCustomRangeSheet(c)),
      ),
      BookState(
        'pre-filled',
        (c, r) => _BookLaunch(
          'open',
          () => showCustomRangeSheet(
            c,
            initialFrom: DateTime.now().subtract(const Duration(days: 6)),
            initialTo: DateTime.now(),
          ),
        ),
      ),
    ],
  ),
  BookEntry(
    name: 'showThemeSheet',
    group: _gSheets,
    note:
        'Lives in features/me/widgets. Picking a theme here changes the real '
        'app theme and writes it to prefs — same as the axis strip above.',
    states: [
      BookState(
        'theme + skin picker',
        (c, r) => _BookLaunch('open', () => showThemeSheet(c, r)),
      ),
    ],
  ),
  BookEntry(
    name: 'showExportSheet',
    group: _gSheets,
    note:
        'Report fetchers are overridden with empty-but-valid payloads, so an '
        'export produces a real PDF/CSV and opens the Android share sheet.',
    states: [
      BookState(
        'no snapshot — "Laporan" disabled',
        (c, r) => _scope(
          _exportFetchers,
          Consumer(
            builder: (c, r, _) => _BookLaunch(
              'open',
              () => showExportSheet(c, r, query: const ReportsQuery()),
            ),
          ),
        ),
      ),
      BookState(
        'with snapshot — every kind enabled',
        (c, r) => _scope(
          _exportFetchers,
          Consumer(
            builder: (c, r, _) => _BookLaunch(
              'open',
              () => showExportSheet(
                c,
                r,
                query: const ReportsQuery(range: ReportRange.d7),
                snapshot: BookStubs.reportsSnapshot,
              ),
            ),
          ),
        ),
      ),
    ],
  ),
];

// Fixed boxes for widgets that normally own a whole screen edge. Named so the
// spacing guard sees a constant rather than a raw layout literal.
const double _skeletonFloor = 86;
const double _railHeight = 420;
const double _shellHeight = 380;
const double _photoSize = 72;
