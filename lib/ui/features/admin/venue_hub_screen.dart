import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/ui/features/admin/widgets/seed_data_dialog.dart';
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
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/anim.dart';
import 'package:satset/ui/features/admin/alerts_screen.dart';
import '_common.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/l10n/app_localizations.dart';

class _HubSection {
  final String label;
  final String sub;
  final IconData icon;
  final String route;
  final Color Function(SatColors) tint;
  final String Function(WidgetRef ref)? badgeBuilder;

  /// Badge shown instead of [badgeBuilder]'s on a phone. Only set where the
  /// destination is genuinely tablet-shaped, so the card can say so before the
  /// tap rather than after it.
  final String? phoneBadge;
  final bool Function(WidgetRef ref)? hasAlert;

  const _HubSection({
    required this.label,
    required this.sub,
    required this.icon,
    required this.route,
    required this.tint,
    this.badgeBuilder,
    this.phoneBadge,
    this.hasAlert,
  });
}

/// Built per-call rather than held in a top-level `final`: every label and
/// subtitle is a localised string now, so the list cannot outlive a locale
/// change. ADR-0083.
List<_HubSection> _sectionsFor(AppL10n l10n) => <_HubSection>[
  _HubSection(
    label: l10n.venueHubSectionZona,
    sub: l10n.venueHubSectionZonaSub,
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
    label: l10n.venueHubSectionMenu,
    sub: l10n.venueHubSectionMenuSub,
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
    label: l10n.venueHubSectionStock,
    sub: l10n.venueHubSectionStockSub,
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
    label: l10n.venueHubSectionVenue,
    sub: l10n.venueHubSectionVenueSub,
    icon: Icons.storefront_outlined,
    route: '/venue-settings',
    tint: (sc) => sc.violet,
    badgeBuilder: (ref) {
      final v = ref.watch(venueSettingsProvider);
      final tax = (v.taxRateBps / 100.0).toStringAsFixed(0);
      final svc = (v.serviceRateBps / 100.0).toStringAsFixed(0);
      return ref.read(l10nProvider).venueHubBadgeVenue(tax, svc);
    },
  ),
  _HubSection(
    label: l10n.venueHubSectionAlerts,
    sub: l10n.venueHubSectionAlertsSub,
    icon: Icons.notifications_active_outlined,
    route: '/alerts',
    tint: (sc) => sc.urgent,
    badgeBuilder: (ref) =>
        alertsSummary(ref.read(l10nProvider), ref.watch(venueSettingsProvider)),
  ),
  _HubSection(
    label: l10n.venueHubSectionSystem,
    sub: l10n.venueHubSectionSystemSub,
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
    label: l10n.venueHubSectionStaff,
    sub: l10n.venueHubSectionStaffSub,
    icon: Icons.person_outline_rounded,
    route: '/staff',
    tint: (sc) => sc.success,
    badgeBuilder: (ref) {
      final st = ref.watch(staffRepositoryProvider);
      return ref.read(l10nProvider).venueHubBadgeStaff(st.length);
    },
  ),
  _HubSection(
    label: l10n.venueHubSectionReports,
    sub: l10n.venueHubSectionReportsSub,
    icon: Icons.auto_awesome_outlined,
    route: '/reports',
    tint: (sc) => sc.urgent,
    badgeBuilder: (ref) => ref.read(l10nProvider).venueHubShiftReport,
  ),
  _HubSection(
    label: l10n.kasTitle,
    sub: l10n.kasHubSubtitle,
    icon: Icons.savings_outlined,
    route: '/kas',
    // Info, not success: green on a money tile reads as takings, and the box is
    // deliberately not revenue (ADR-0089).
    tint: (sc) => sc.info,
    badgeBuilder: (ref) => formatIDR(ref.watch(cashProvider).balance),
    phoneBadge: l10n.kasPhoneOnly,
  ),
  _HubSection(
    label: l10n.venueHubSectionAudit,
    sub: l10n.venueHubSectionAuditSub,
    icon: Icons.history,
    route: '/audit',
    tint: (sc) => sc.info,
    badgeBuilder: (ref) {
      final n = ref
          .watch(venueAuditProvider)
          .summary
          .values
          .fold<int>(0, (a, t) => a + t.count);
      return l10n.auditEventCount(n);
    },
    // The log is a tablet screen (six columns at a glance), so the phone card
    // says so before the tap rather than after it. The card still navigates —
    // a manager on a handset should learn the feature exists and where to find
    // it, not meet a dead control.
    phoneBadge: l10n.auditTabletOnlyBadge,
  ),
];

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

    if (l.useTabletShell) {
      return AdminPage(
        title: context.l10n.venueHubTitle,
        sub: context.l10n.venueHubSubtitle,
        children: [
          const Reveal(index: 0, child: _VenueHeroStrip()),
          const SizedBox(height: Sp.s4),
          _HubGrid(
            sections: _sectionsFor(context.l10n),
            seedOffset: 1,
            big: true,
          ),
        ],
      );
    }

    return _PhoneHub(sections: _sectionsFor(context.l10n));
  }
}

class _VenueHeroStrip extends ConsumerWidget {
  const _VenueHeroStrip();

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
                          : context.l10n.venueHubSubtitle,
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
  const _PhoneHub({required this.sections});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l = context.layout;
    return ListView(
      // Not `l.topInset` — that token clears a status bar for screens with no
      // chrome above them, and this one always renders under SatAppBar.
      padding: EdgeInsets.fromLTRB(16, Sp.s6, 16, l.bottomInset + 40),
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
        const Reveal(index: 2, child: _VenueHeroStrip()),
        const SizedBox(height: Sp.s3h),
        _HubGrid(sections: sections, seedOffset: 3),
      ],
    );
  }
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

    final badgeText =
        (!context.layout.useTabletShell && section.phoneBadge != null)
        ? section.phoneBadge
        : section.badgeBuilder?.call(ref);
    final hasAlert = section.hasAlert?.call(ref) ?? false;

    return PressScale(
      child: Material(
        color: sc.bg2,
        borderRadius: SatR.a(radius),
        child: InkWell(
          onTap: () => context.push(section.route),
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
                      child: Icon(section.icon, size: iconSize, color: tint),
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
                  section.label,
                  style: big
                      ? SatType.labelL(color: sc.textHi)
                      : SatType.labelM(color: sc.textHi),
                ),
                const SizedBox(height: Sp.s1),
                Text(
                  section.sub,
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
