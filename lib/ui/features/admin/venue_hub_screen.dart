import 'package:flutter/material.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/domain/models/venue_module.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/ui/features/admin/widgets/seed_data_dialog.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/cash_repository.dart';
import 'package:satset/data/repositories/generic_seed.dart';
import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/data/repositories/staff_repository.dart';
import 'package:satset/data/repositories/stock_repository.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/venue_audit_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/repositories/zones_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/shell_inset.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/anim.dart';
import 'package:satset/ui/features/admin/alerts_screen.dart';
import '_common.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/router/app_router.dart';

class _HubSection {
  /// Label and subtitle are resolved at render, not at construction: the list
  /// itself is now a top-level `final` (it is the one place hub membership is
  /// written down — see [venueHubRoutes]), and a list holding resolved strings
  /// could not outlive a locale change. ADR-0083.
  final String Function(AppL10n) label;
  final String Function(AppL10n) sub;
  final IconData icon;
  final String route;
  final Color Function(SatColors) tint;
  final String Function(WidgetRef ref)? badgeBuilder;

  /// Badge shown instead of [badgeBuilder]'s on a phone. Only set where the
  /// destination is genuinely tablet-shaped, so the card can say so before the
  /// tap rather than after it.
  final String Function(AppL10n)? phoneBadge;
  final bool Function(WidgetRef ref)? hasAlert;

  /// The [[Modul]] this destination needs (ADR-0107), or null when it is part of
  /// the base package. A venue that does not hold it gets a **locked tile here
  /// and nowhere else**: the owner is the person the upsell is addressed to, and
  /// a locked door in front of a waiter mid-rush is advertising inside a tool.
  final String? module;

  const _HubSection({
    required this.label,
    required this.sub,
    required this.icon,
    required this.route,
    required this.tint,
    this.badgeBuilder,
    this.phoneBadge,
    this.hasAlert,
    this.module,
  });
}

/// Every destination the Venue hub offers, in display order.
///
/// **The one list.** `venueHubRoutes` is derived from it and the router spends
/// that to decide both who may open `/venue` at all and which tiles render
/// (ADR-0134) — so adding a tile here widens the hub's own gate in the same
/// edit, and a tile can never be visible on a screen its holder cannot open.
final _sections = <_HubSection>[
  _HubSection(
    label: (l) => l.venueHubSectionZona,
    sub: (l) => l.venueHubSectionZonaSub,
    icon: Icons.place_outlined,
    route: '/zone-admin',
    tint: (sc) => sc.accentText,
    badgeBuilder: (ref) {
      final z = ref.watch(zonesProvider);
      final t = ref.watch(tablesProvider);
      return ref.read(l10nProvider).venueHubBadgeFloor(t.length, z.length);
    },
  ),
  _HubSection(
    label: (l) => l.venueHubSectionMenu,
    sub: (l) => l.venueHubSectionMenuSub,
    icon: Icons.restaurant_menu_rounded,
    route: '/menuadm',
    tint: (sc) => sc.warn,
    badgeBuilder: (ref) {
      final m = ref.watch(menuItemsProvider);
      final c = ref.watch(menuCategoriesProvider);
      return ref.read(l10nProvider).venueHubBadgeMenu(m.length, c.length);
    },
  ),
  _HubSection(
    label: (l) => l.venueHubSectionStock,
    sub: (l) => l.venueHubSectionStockSub,
    icon: Icons.inventory_2_outlined,
    route: '/stock',
    tint: (sc) => sc.success,
    badgeBuilder: (ref) {
      final s = ref.watch(ingredientsProvider).valueOrNull ?? const [];
      final low = s.where((i) => i.isLow).length;
      final l = ref.read(l10nProvider);
      return low > 0
          ? l.venueHubBadgeStockLow(low)
          : l.venueHubBadgeStockOk(s.length);
    },
    hasAlert: (ref) {
      final s = ref.watch(ingredientsProvider).valueOrNull ?? const [];
      return s.any((i) => i.isLow);
    },
  ),
  _HubSection(
    label: (l) => l.venueHubSectionVenue,
    sub: (l) => l.venueHubSectionVenueSub,
    icon: Icons.storefront_outlined,
    route: '/venue-settings',
    tint: (sc) => sc.violet,
    // The rate columns keep their value while their switch is off, so reading
    // them bare badged a venue that charges nothing with the 11% / 5% defaults
    // it had never turned on. Four keys rather than one with blanks: the two
    // switches are independent, so tax-on-service-off is a real venue, and a
    // sentence assembled from fragments here would be Indonesian in Dart
    // (ADR-0085).
    badgeBuilder: (ref) {
      final v = ref.watch(venueSettingsProvider);
      final l = ref.read(l10nProvider);
      final tax = (v.taxRateBps / 100.0).toStringAsFixed(0);
      final svc = (v.serviceRateBps / 100.0).toStringAsFixed(0);
      return switch ((v.taxEnabled, v.serviceEnabled)) {
        (true, true) => l.venueHubBadgeVenue(tax, svc),
        (true, false) => l.venueHubBadgeVenueTax(tax),
        (false, true) => l.venueHubBadgeVenueSvc(svc),
        (false, false) => l.venueHubBadgeVenueNone,
      };
    },
  ),
  _HubSection(
    label: (l) => l.venueHubSectionAlerts,
    sub: (l) => l.venueHubSectionAlertsSub,
    icon: Icons.notifications_active_outlined,
    route: '/alerts',
    tint: (sc) => sc.urgent,
    badgeBuilder: (ref) =>
        alertsSummary(ref.read(l10nProvider), ref.watch(venueSettingsProvider)),
  ),
  _HubSection(
    label: (l) => l.venueHubSectionSystem,
    sub: (l) => l.venueHubSectionSystemSub,
    icon: Icons.wifi_rounded,
    route: '/system',
    tint: (sc) => sc.info,
    badgeBuilder: (ref) {
      final cfg = ref.watch(apiConfigProvider);
      if (cfg == null) return 'Offline';
      return 'LAN · ${cfg.baseUri.host}';
    },
  ),
  _HubSection(
    label: (l) => l.venueHubSectionStaff,
    sub: (l) => l.venueHubSectionStaffSub,
    icon: Icons.person_outline_rounded,
    route: '/staff',
    tint: (sc) => sc.success,
    badgeBuilder: (ref) {
      final st = ref.watch(staffRepositoryProvider);
      return ref.read(l10nProvider).venueHubBadgeStaff(st.length);
    },
  ),
  _HubSection(
    label: (l) => l.venueHubSectionReports,
    sub: (l) => l.venueHubSectionReportsSub,
    icon: Icons.auto_awesome_outlined,
    route: '/reports',
    tint: (sc) => sc.urgent,
    badgeBuilder: (ref) => ref.read(l10nProvider).venueHubShiftReport,
  ),
  _HubSection(
    label: (l) => l.soAdminTitle,
    sub: (l) => l.soAdminSub,
    icon: Icons.qr_code_2_outlined,
    route: '/selforder-admin',
    tint: (sc) => sc.accent,
    module: moduleSelfOrder,
    // On/off, not a backlog. The queue is a nav destination with its own badge
    // now (ADR-0106); what this hub owns is whether the feature is running at
    // all, and counting pending orders here would send an owner to the wrong
    // screen for them.
    badgeBuilder: (ref) {
      final l = ref.read(l10nProvider);
      return ref.watch(venueSettingsProvider).guestOrderingEnabled
          ? l.soHubBadgeOn
          : l.soHubBadgeOff;
    },
  ),
  // Deliberately no badge. Nothing derives "is the shop open right now" from
  // the audit pair (ADR-0111), and a tile reading Buka/Tutup would be exactly
  // the state this design refused to store.
  _HubSection(
    label: (l) => l.venueHubDayTitle,
    sub: (l) => l.venueHubDaySub,
    icon: Icons.wb_twilight_rounded,
    route: '/venue-day',
    tint: (sc) => sc.success,
  ),
  _HubSection(
    label: (l) => l.kasTitle,
    sub: (l) => l.kasHubSubtitle,
    icon: Icons.savings_outlined,
    route: '/kas',
    // Info, not success: green on a money tile reads as takings, and the box is
    // deliberately not revenue (ADR-0089).
    tint: (sc) => sc.info,
    badgeBuilder: (ref) => formatIDR(ref.watch(cashProvider).balance),
    phoneBadge: (l) => l.kasPhoneOnly,
  ),
  _HubSection(
    label: (l) => l.memTitle,
    sub: (l) => l.memHubSubtitle,
    icon: Icons.badge_outlined,
    route: '/members',
    tint: (sc) => sc.violet,
    module: moduleMembers,
    // The tile stands whether or not the program runs: a venue that has not
    // opted in still needs to find out the feature exists, and the screen
    // behind it says how to switch it on.
    badgeBuilder: (ref) => ref.watch(venueSettingsProvider).membersEnabled
        ? ref.read(l10nProvider).memHubBadgeOn
        : ref.read(l10nProvider).memHubBadgeOff,
    phoneBadge: (l) => l.memPhoneOnly,
  ),
  _HubSection(
    label: (l) => l.hubMemberReport,
    sub: (l) => l.hubMemberReportSub,
    icon: Icons.insights_outlined,
    route: '/member-report',
    tint: (sc) => sc.violet,
    module: moduleMembers,
    phoneBadge: (l) => l.mrpPhoneOnly,
  ),
  _HubSection(
    label: (l) => l.opnTitle,
    sub: (l) => l.opnHubSubtitle,
    icon: Icons.inventory_2_outlined,
    route: '/opname',
    tint: (sc) => sc.warn,
    phoneBadge: (l) => l.opnPhoneOnly,
  ),
  _HubSection(
    label: (l) => l.venueHubSectionAudit,
    sub: (l) => l.venueHubSectionAuditSub,
    icon: Icons.history,
    route: '/audit',
    tint: (sc) => sc.info,
    badgeBuilder: (ref) {
      final n = ref
          .watch(venueAuditProvider)
          .summary
          .values
          .fold<int>(0, (a, t) => a + t.count);
      return ref.read(l10nProvider).auditEventCount(n);
    },
    // The log is a tablet screen (six columns at a glance), so the phone card
    // says so before the tap rather than after it. The card still navigates —
    // a manager on a handset should learn the feature exists and where to find
    // it, not meet a dead control.
    phoneBadge: (l) => l.auditTabletOnlyBadge,
  ),
];

/// The hub's subtitle: the first few destinations this viewer actually has.
///
/// Derived rather than written down (ADR-0134). The old fixed line named
/// Konfigurasi, Zona, Sistem and Staf to everyone — which, once the tiles
/// filter by capability, is a subtitle listing rooms the reader cannot enter.
/// Capped at [_subMax] because it is a sample of what is here, not an index:
/// an admin holds fifteen tiles and the line has one row to live in.
String hubSectionLine(AppL10n l10n, AuthState auth) =>
    _visibleFor(auth).take(_subMax).map((s) => s.label(l10n)).join(' · ');

/// The tiles [auth] may open, in display order — the grid and the subtitle
/// read the same list, so the line can never name a tile that is not drawn.
List<_HubSection> _visibleFor(AuthState auth) =>
    _sections.where((s) => canOpenRoute(auth, s.route)).toList();

const _subMax = 5;

/// The routes the hub offers, in display order — derived from [_sections],
/// never written down a second time. The router reads it to compute the hub's
/// own gate (ADR-0134).
final venueHubRoutes = List<String>.unmodifiable(_sections.map((s) => s.route));

class VenueHubScreen extends ConsumerStatefulWidget {
  const VenueHubScreen({super.key});

  @override
  ConsumerState<VenueHubScreen> createState() => _VenueHubScreenState();
}

class _VenueHubScreenState extends ConsumerState<VenueHubScreen> {
  bool _prompted = false;

  @override
  Widget build(BuildContext context) {
    final l = context.layout;

    // The first-run prompt is mandatory and blocking (ADR-0073): an empty
    // venue answers "muat contoh data" or "lewati" before it reaches a single
    // hub tile. `_prompted` keeps a rebuild from stacking a second dialog —
    // the *answer* is persisted server-side, so this flag only guards the
    // frame, never the promise.
    //
    // Watched, not listened. `/seed/state` is fetched when the provider is
    // first read, which on a warm navigation has already happened by the time
    // this screen mounts — a change-only listener would then never fire and
    // the mandatory prompt would silently not appear.
    final mustPrompt = ref.watch(
      genericSeedProvider.select((s) => s.mustPrompt),
    );
    if (mustPrompt && !_prompted) {
      _prompted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showSeedDataDialog(context);
      });
    }

    // A tile the signed-in user could not open is not shown (ADR-0134). The
    // predicate is the router's own, so a visible tile can never land on
    // `/forbidden` and a hidden one can never be the only door to a screen the
    // person is entitled to.
    final auth = ref.watch(authStateProvider);
    final sections = _visibleFor(auth);
    final sub = hubSectionLine(context.l10n, auth);

    if (l.useTabletShell) {
      return AdminPage(
        title: context.l10n.venueHubTitle,
        sub: sub,
        children: [
          Reveal(index: 0, child: _VenueHeroStrip(sub: sub)),
          const SizedBox(height: Sp.s4),
          _HubGrid(sections: sections, seedOffset: 1, big: true),
        ],
      );
    }

    return _PhoneHub(sections: sections, sub: sub);
  }
}

class _VenueHeroStrip extends ConsumerWidget {
  /// Shown when the venue has not filled in its legal name — the same derived
  /// section line the page title carries, never a fixed list of rooms.
  final String sub;
  const _VenueHeroStrip({required this.sub});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final venue = ref.watch(venueSettingsProvider);
    final tables = ref.watch(tablesProvider);
    final zones = ref.watch(zonesProvider);
    final menuItems = ref.watch(menuItemsProvider);
    final stockItems = ref.watch(ingredientsProvider).valueOrNull ?? const [];
    final staffList = ref.watch(staffRepositoryProvider);
    final apiConfig = ref.watch(apiConfigProvider);

    final lowStock = stockItems.where((i) => i.isLow).length;

    return Container(
      decoration: SatBox.d(
        color: sc.bg2,
        borderRadius: SatR.a(18),
        border: SatB.all(color: sc.border0),
      ),
      padding: const EdgeInsets.all(Sp.s4h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: SatBox.d(
                  color: sc.accent.withValues(alpha: 0.12),
                  borderRadius: SatR.a(12),
                  border: SatB.all(color: sc.accent.withValues(alpha: 0.25)),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.storefront_rounded,
                  size: 22,
                  color: sc.accentText,
                ),
              ),
              const SizedBox(width: Sp.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            venue.displayName.isNotEmpty
                                ? venue.displayName
                                : context.l10n.venueHubTitle,
                            style: SatType.h3(color: sc.textHi),
                          ),
                        ),
                        const SizedBox(width: Sp.s2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Sp.s2,
                            vertical: Sp.sHair,
                          ),
                          decoration: SatBox.d(
                            color: sc.successSoft,
                            borderRadius: SatR.a(20),
                            border: SatB.all(
                              color: sc.success.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: SatBox.d(
                                  color: sc.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: Sp.s1),
                              Text(
                                apiConfig != null
                                    ? context.l10n.venueHubLanActive
                                    : context.l10n.venueHubLanLocal,
                                style: SatType.caption(color: sc.success),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Sp.sHair),
                    Text(
                      venue.legalName.isNotEmpty
                          ? '${venue.legalName} · ${venue.address.isNotEmpty ? venue.address : context.l10n.venueHubOperationalMode}'
                          : sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SatType.bodyS(color: sc.textLo),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Sp.s2),
              InkWell(
                onTap: () => context.push('/venue-settings'),
                borderRadius: SatR.a(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Sp.s3,
                    vertical: Sp.s2,
                  ),
                  decoration: SatBox.d(
                    borderRadius: SatR.a(10),
                    border: SatB.all(color: sc.border1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, size: 14, color: sc.textHi),
                      const SizedBox(width: Sp.s1h),
                      Text(
                        context.l10n.vhbSettings,
                        style: SatType.labelS(color: sc.textHi),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.s3h),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _StatBadge(
                icon: Icons.place_outlined,
                text: context.l10n.venueHubTablesZones(
                  tables.length,
                  zones.length,
                ),
                color: sc.accentText,
              ),
              _StatBadge(
                icon: Icons.restaurant_menu_rounded,
                text: context.l10n.venueHubMenuItems(menuItems.length),
                color: sc.warn,
              ),
              _StatBadge(
                icon: Icons.inventory_2_outlined,
                text: lowStock > 0
                    ? context.l10n.venueHubStockLow(stockItems.length, lowStock)
                    : context.l10n.venueHubStock(stockItems.length),
                color: lowStock > 0 ? sc.warn : sc.success,
              ),
              _StatBadge(
                icon: Icons.badge_outlined,
                text: context.l10n.venueHubStaffCount(staffList.length),
                color: sc.info,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: Sp.s1),
        Text(text, style: SatType.bodyS(color: sc.textLo)),
      ],
    );
  }
}

class _HubGrid extends StatelessWidget {
  final List<_HubSection> sections;
  final int seedOffset;
  final bool big;
  const _HubGrid({
    required this.sections,
    this.seedOffset = 0,
    this.big = false,
  });

  @override
  Widget build(BuildContext context) {
    final gap = big ? 12.0 : 10.0;
    final rows = <Widget>[];
    for (var i = 0; i < sections.length; i += 2) {
      final revealIdx = (i ~/ 2) + seedOffset;
      final left = _HubCard(section: sections[i], big: big);
      final right = (i + 1 < sections.length)
          ? _HubCard(section: sections[i + 1], big: big)
          : const SizedBox.shrink();
      rows.add(
        Reveal(
          index: revealIdx,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              SizedBox(width: gap),
              Expanded(child: right),
            ],
          ),
        ),
      );
      if (i + 2 < sections.length) rows.add(SizedBox(height: gap));
    }
    return Column(children: rows);
  }
}

class _PhoneHub extends StatelessWidget {
  final List<_HubSection> sections;
  final String sub;
  const _PhoneHub({required this.sections, required this.sub});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return ListView(
      // Not `SatLayout.topInset` — that token clears a status bar for screens with no
      // chrome above them, and this one always renders under SatAppBar.
      padding: EdgeInsets.fromLTRB(16, Sp.s6, 16, context.shellInset),
      children: [
        Reveal(
          index: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
            child: Row(
              children: [
                Icon(Icons.storefront_outlined, size: 14, color: sc.textHi),
                const SizedBox(width: Sp.s1h),
                Text(
                  context.l10n.venueHubTitle,
                  style: SatType.bodyM(color: sc.textHi),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Sp.s1),
        Reveal(
          index: 1,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
            child: Text(
              context.l10n.crumbKonfigurasi,
              style: SatType.h2(color: sc.textHi),
            ),
          ),
        ),
        Reveal(index: 2, child: _VenueHeroStrip(sub: sub)),
        const SizedBox(height: Sp.s3h),
        _HubGrid(sections: sections, seedOffset: 3),
      ],
    );
  }
}

void _showLocked(BuildContext context) {
  final sc = context.sat;
  showSatDialog<void>(
    context,
    builder: (ctx) => AlertDialog(
      backgroundColor: sc.bg1,
      title: Text(
        context.l10n.venueHubLocked,
        style: SatType.h3(color: sc.textHi),
      ),
      content: Text(
        context.l10n.venueHubLockedBody,
        style: SatType.bodyM(color: sc.textMd),
      ),
      actions: [
        SatButton.ghost(
          label: context.l10n.close,
          onTap: () => Navigator.pop(ctx),
        ),
      ],
    ),
  );
}

class _HubCard extends ConsumerWidget {
  final _HubSection section;
  final bool big;
  const _HubCard({required this.section, required this.big});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final tint = section.tint(sc);
    final radius = big ? 18.0 : 16.0;
    final iconBox = big ? 46.0 : 40.0;
    final iconSize = big ? 22.0 : 20.0;

    // Locked beats every other badge: a venue that cannot open the screen does
    // not need to know how many rows are behind it.
    final settings = ref.watch(venueSettingsProvider);
    final locked =
        section.module != null && !settings.hasModule(section.module!);
    final badgeText = locked
        ? context.l10n.venueHubLocked
        : (!context.layout.useTabletShell && section.phoneBadge != null)
        ? section.phoneBadge!(context.l10n)
        : section.badgeBuilder?.call(ref);
    final hasAlert = !locked && (section.hasAlert?.call(ref) ?? false);

    return PressScale(
      child: Material(
        color: sc.bg2,
        borderRadius: SatR.a(radius),
        child: InkWell(
          // The lock is a sales surface, not a security boundary — the routes
          // behind it are gated server-side regardless (ADR-0107 §3). Tapping
          // says who to ask rather than doing nothing, which reads as broken.
          onTap: locked
              ? () => _showLocked(context)
              : () => context.push(section.route),
          borderRadius: SatR.a(radius),
          child: Container(
            padding: EdgeInsets.all(big ? 16 : 14),
            decoration: SatBox.d(
              borderRadius: SatR.a(radius),
              border: SatB.all(
                color: hasAlert ? sc.warn.withValues(alpha: 0.5) : sc.border0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: iconBox,
                      height: iconBox,
                      decoration: SatBox.d(
                        color: tint.withValues(alpha: 0.12),
                        borderRadius: SatR.a(big ? 14 : 12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        locked ? Icons.lock_outline_rounded : section.icon,
                        size: iconSize,
                        color: locked ? sc.textLo : tint,
                      ),
                    ),
                    if (badgeText != null)
                      Flexible(
                        child: Container(
                          margin: const EdgeInsets.only(left: Sp.s1h),
                          padding: const EdgeInsets.symmetric(
                            horizontal: Sp.s2,
                            vertical: Sp.s1,
                          ),
                          decoration: SatBox.d(
                            color: hasAlert ? sc.warnSoft : sc.bg1,
                            borderRadius: SatR.a(10),
                            border: SatB.all(
                              color: hasAlert ? sc.warn : sc.border0,
                            ),
                          ),
                          child: Text(
                            badgeText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SatType.caption(
                              color: hasAlert ? sc.warn : sc.textLo,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: Sp.s3h),
                Text(
                  section.label(context.l10n),
                  style: big
                      ? SatType.labelL(color: sc.textHi)
                      : SatType.labelM(color: sc.textHi),
                ),
                const SizedBox(height: Sp.s1),
                Text(
                  section.sub(context.l10n),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SatType.bodyS(color: sc.textLo),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
