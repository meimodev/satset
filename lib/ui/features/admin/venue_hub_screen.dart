import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/data/repositories/generic_seed.dart';
import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/data/repositories/staff_repository.dart';
import 'package:satset/data/repositories/stock_repository.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/repositories/zones_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/anim.dart';
import 'package:satset/ui/features/admin/alerts_screen.dart';
import '_common.dart';
import 'package:satset/ui/core/design/spacing.dart';

class _Section {
  final String label;
  final String sub;
  final IconData icon;
  final String route;
  final Color Function(SatColors) tint;
  final String Function(WidgetRef ref)? badgeBuilder;
  final bool Function(WidgetRef ref)? hasAlert;

  const _Section({
    required this.label,
    required this.sub,
    required this.icon,
    required this.route,
    required this.tint,
    this.badgeBuilder,
    this.hasAlert,
  });
}

final _sections = <_Section>[
  _Section(
    label: AppStrings.venueHubSectionZona,
    sub: AppStrings.venueHubSectionZonaSub,
    icon: Icons.place_outlined,
    route: '/zone-admin',
    tint: (sc) => sc.accentText,
    badgeBuilder: (ref) {
      final z = ref.watch(zonesProvider);
      final t = ref.watch(tablesProvider);
      return '${t.length} meja · ${z.length} zona';
    },
  ),
  _Section(
    label: AppStrings.venueHubSectionMenu,
    sub: AppStrings.venueHubSectionMenuSub,
    icon: Icons.restaurant_menu_rounded,
    route: '/menuadm',
    tint: (sc) => sc.warn,
    badgeBuilder: (ref) {
      final m = ref.watch(menuItemsProvider);
      final c = ref.watch(menuCategoriesProvider);
      return '${m.length} item · ${c.length} kategori';
    },
  ),
  _Section(
    label: AppStrings.venueHubSectionStock,
    sub: AppStrings.venueHubSectionStockSub,
    icon: Icons.inventory_2_outlined,
    route: '/stock',
    tint: (sc) => sc.success,
    badgeBuilder: (ref) {
      final s = ref.watch(ingredientsProvider).valueOrNull ?? const [];
      final low = s.where((i) => i.isLow).length;
      return low > 0 ? '$low perhatian' : '${s.length} bahan';
    },
    hasAlert: (ref) {
      final s = ref.watch(ingredientsProvider).valueOrNull ?? const [];
      return s.any((i) => i.isLow);
    },
  ),
  _Section(
    label: AppStrings.venueHubSectionVenue,
    sub: AppStrings.venueHubSectionVenueSub,
    icon: Icons.storefront_outlined,
    route: '/venue-settings',
    tint: (sc) => sc.violet,
    badgeBuilder: (ref) {
      final v = ref.watch(venueSettingsProvider);
      final tax = (v.taxRateBps / 100.0).toStringAsFixed(0);
      final svc = (v.serviceRateBps / 100.0).toStringAsFixed(0);
      return 'Pajak $tax% · Service $svc%';
    },
  ),
  _Section(
    label: AppStrings.venueHubSectionAlerts,
    sub: AppStrings.venueHubSectionAlertsSub,
    icon: Icons.notifications_active_outlined,
    route: '/alerts',
    tint: (sc) => sc.urgent,
    badgeBuilder: (ref) => alertsSummary(ref.watch(venueSettingsProvider)),
  ),
  _Section(
    label: AppStrings.venueHubSectionSystem,
    sub: AppStrings.venueHubSectionSystemSub,
    icon: Icons.wifi_rounded,
    route: '/system',
    tint: (sc) => sc.info,
    badgeBuilder: (ref) {
      final cfg = ref.watch(apiConfigProvider);
      if (cfg == null) return 'Offline';
      return 'LAN · ${cfg.baseUri.host}';
    },
  ),
  _Section(
    label: AppStrings.venueHubSectionStaff,
    sub: AppStrings.venueHubSectionStaffSub,
    icon: Icons.person_outline_rounded,
    route: '/staff',
    tint: (sc) => sc.success,
    badgeBuilder: (ref) {
      final st = ref.watch(staffRepositoryProvider);
      return '${st.length} staf';
    },
  ),
  _Section(
    label: AppStrings.venueHubSectionReports,
    sub: AppStrings.venueHubSectionReportsSub,
    icon: Icons.auto_awesome_outlined,
    route: '/reports',
    tint: (sc) => sc.urgent,
    badgeBuilder: (ref) => 'Laporan shift',
  ),
];

class VenueHubScreen extends ConsumerWidget {
  const VenueHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.layout;
    final seed = ref.watch(genericSeedProvider);
    final showSeed = seed.showPrompt;
    final showDemo = seed.canSeedDemo || seed.hasDemo;

    if (l.useTabletShell) {
      var idx = 0;
      return AdminPage(
        title: AppStrings.venueHubTitle,
        sub: AppStrings.venueHubSubtitle,
        children: [
          Reveal(index: idx++, child: const _VenueHeroStrip()),
          const SizedBox(height: Sp.s4),
          if (showSeed) ...[
            Reveal(index: idx++, child: const SeedDataBanner()),
            const SizedBox(height: Sp.s4),
          ],
          if (showDemo) ...[
            Reveal(index: idx++, child: const DemoDataBanner()),
            const SizedBox(height: Sp.s4),
          ],
          _HubGrid(sections: _sections, seedOffset: idx, big: true),
        ],
      );
    }

    return _PhoneHub(
      sections: _sections,
      showSeed: showSeed,
      showDemo: showDemo,
    );
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
                                : AppStrings.venueHubTitle,
                            style: SatType.sans(
                              size: 18,
                              weight: FontWeight.w700,
                              color: sc.textHi,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: Sp.s2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Sp.s2,
                            vertical: 2.5,
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
                                apiConfig != null ? 'LAN AKTIF' : 'LOKAL',
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
                          ? '${venue.legalName} · ${venue.address.isNotEmpty ? venue.address : 'Mode Operasional'}'
                          : AppStrings.venueHubSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SatType.sans(size: 12, color: sc.textLo),
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
                        'Pengaturan',
                        style: SatType.sans(
                          size: 12,
                          weight: FontWeight.w600,
                          color: sc.textHi,
                        ),
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
                text: '${tables.length} meja (${zones.length} zona)',
                color: sc.accentText,
              ),
              _StatBadge(
                icon: Icons.restaurant_menu_rounded,
                text: '${menuItems.length} item menu',
                color: sc.warn,
              ),
              _StatBadge(
                icon: Icons.inventory_2_outlined,
                text: lowStock > 0
                    ? '${stockItems.length} bahan ($lowStock low)'
                    : '${stockItems.length} bahan',
                color: lowStock > 0 ? sc.warn : sc.success,
              ),
              _StatBadge(
                icon: Icons.badge_outlined,
                text: '${staffList.length} staf',
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
        Text(
          text,
          style: SatType.sans(
            size: 11.5,
            weight: FontWeight.w500,
            color: sc.textLo,
          ),
        ),
      ],
    );
  }
}

/// Demo-dataset controls (ADR-0052). Offers the load action while the venue
/// has not traded, and refresh/reset once demo data is present — the live half
/// decays within minutes, so refresh is the common action, not an edge case.
class DemoDataBanner extends ConsumerWidget {
  const DemoDataBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final st = ref.watch(genericSeedProvider);
    final ctrl = ref.read(genericSeedProvider.notifier);

    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              st.canSeedDemo
                  ? AppStrings.venueHubDemoError
                  : AppStrings.venueHubDemoRefused,
            ),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(Sp.s4),
      decoration: SatBox.d(
        color: sc.info.withValues(alpha: 0.10),
        borderRadius: SatR.a(16),
        border: SatB.all(color: sc.info.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_rounded, size: 18, color: sc.info),
              const SizedBox(width: Sp.s2),
              Expanded(
                child: Text(
                  AppStrings.venueHubDemoTitle,
                  style: SatType.sans(
                    size: 15,
                    weight: FontWeight.w700,
                    color: sc.textHi,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.s1h),
          Text(
            st.demoSeeding
                ? AppStrings.venueHubDemoBodyRunning
                : st.demoIncomplete
                ? AppStrings.venueHubDemoBodyIncomplete
                : st.hasDemo
                ? AppStrings.venueHubDemoBodyLoaded
                : AppStrings.venueHubDemoBody,
            style: SatType.sans(size: 12.5, color: sc.textLo, height: 1.35),
          ),
          const SizedBox(height: Sp.s3h),
          if (st.demoSeeding) ...[
            // A month through the production order path takes minutes; a bare
            // spinner cannot be told from a hang (ADR-0053 §8).
            ClipRRect(
              borderRadius: SatR.a(999),
              child: LinearProgressIndicator(
                value: st.demoDaysDone / st.demoDaysTotal,
                minHeight: 6,
                backgroundColor: sc.bg3,
                valueColor: AlwaysStoppedAnimation(sc.info),
              ),
            ),
            const SizedBox(height: Sp.s2),
            Text(
              '${AppStrings.venueHubDemoProgress} · '
              '${st.demoDaysDone}/${st.demoDaysTotal}',
              style: SatType.monoS(color: sc.textLo),
            ),
          ] else
            Row(
              children: [
                if (st.hasDemo || st.demoIncomplete)
                  Expanded(
                    child: _BannerBtn(
                      label: AppStrings.venueHubDemoBtnReset,
                      filled: true,
                      busy: st.loading,
                      onTap: st.loading ? null : () => run(ctrl.resetDemo),
                    ),
                  )
                else
                  Expanded(
                    child: _BannerBtn(
                      label: st.loading
                          ? AppStrings.loading
                          : AppStrings.venueHubDemoBtnLoad,
                      filled: true,
                      busy: st.loading,
                      onTap: st.loading ? null : () => run(ctrl.seedDemo),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class SeedDataBanner extends ConsumerWidget {
  const SeedDataBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final st = ref.watch(genericSeedProvider);
    final ctrl = ref.read(genericSeedProvider.notifier);
    return Container(
      padding: const EdgeInsets.all(Sp.s4),
      decoration: SatBox.d(
        color: sc.accent.withValues(alpha: 0.10),
        borderRadius: SatR.a(16),
        border: SatB.all(color: sc.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_fix_high_rounded, size: 18, color: sc.accentText),
              const SizedBox(width: Sp.s2),
              Expanded(
                child: Text(
                  AppStrings.venueHubSeedTitle,
                  style: SatType.sans(
                    size: 15,
                    weight: FontWeight.w700,
                    color: sc.textHi,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.s1h),
          Text(
            AppStrings.venueHubSeedBody,
            style: SatType.sans(size: 12.5, color: sc.textLo, height: 1.35),
          ),
          const SizedBox(height: Sp.s3h),
          Row(
            children: [
              Expanded(
                child: _BannerBtn(
                  label: st.loading
                      ? AppStrings.loading
                      : AppStrings.venueHubSeedBtnLoad,
                  filled: true,
                  busy: st.loading,
                  onTap: st.loading
                      ? null
                      : () async {
                          try {
                            await ctrl.seed();
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(AppStrings.venueHubSeedError),
                                ),
                              );
                            }
                          }
                        },
                ),
              ),
              const SizedBox(width: Sp.s2h),
              _BannerBtn(
                label: AppStrings.venueHubSeedBtnLater,
                filled: false,
                onTap: st.loading ? null : ctrl.dismiss,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerBtn extends StatelessWidget {
  final String label;
  final bool filled;
  final bool busy;
  final VoidCallback? onTap;
  const _BannerBtn({
    required this.label,
    required this.filled,
    this.busy = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Material(
      color: filled ? sc.accent : Colors.transparent,
      borderRadius: SatR.a(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: SatR.a(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Sp.s4, vertical: 11),
          decoration: SatBox.d(
            borderRadius: SatR.a(10),
            border: filled ? null : SatB.all(color: sc.border1),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy) ...[
                SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: sc.bg0,
                  ),
                ),
                const SizedBox(width: Sp.s2),
              ],
              Text(
                label,
                style: SatType.sans(
                  size: 13,
                  weight: FontWeight.w600,
                  color: filled ? sc.bg0 : sc.textHi,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubGrid extends StatelessWidget {
  final List<_Section> sections;
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
  final List<_Section> sections;
  final bool showSeed;
  final bool showDemo;
  const _PhoneHub({
    required this.sections,
    this.showSeed = false,
    this.showDemo = false,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l = context.layout;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, l.topInset, 16, l.bottomInset + 40),
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
                  AppStrings.venueHubTitle,
                  style: SatType.sans(
                    size: 14,
                    weight: FontWeight.w500,
                    color: sc.textHi,
                  ),
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
              AppStrings.crumbKonfigurasi,
              style: SatType.sans(
                size: 22,
                weight: FontWeight.w600,
                letterSpacing: -0.44,
                height: 1.05,
                color: sc.textHi,
              ),
            ),
          ),
        ),
        const Reveal(index: 2, child: _VenueHeroStrip()),
        const SizedBox(height: Sp.s3h),
        if (showSeed) ...[
          const Reveal(index: 3, child: SeedDataBanner()),
          const SizedBox(height: Sp.s3),
        ],
        if (showDemo) ...[
          Reveal(index: showSeed ? 4 : 3, child: const DemoDataBanner()),
          const SizedBox(height: Sp.s3),
        ],
        _HubGrid(
          sections: sections,
          seedOffset: 3 + (showSeed ? 1 : 0) + (showDemo ? 1 : 0),
        ),
      ],
    );
  }
}

class _HubCard extends ConsumerWidget {
  final _Section section;
  final bool big;
  const _HubCard({required this.section, required this.big});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final tint = section.tint(sc);
    final radius = big ? 18.0 : 16.0;
    final iconBox = big ? 46.0 : 40.0;
    final iconSize = big ? 22.0 : 20.0;
    final labelSize = big ? 15.0 : 14.0;
    final subSize = big ? 11.5 : 11.0;

    final badgeText = section.badgeBuilder?.call(ref);
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
                  style: SatType.sans(
                    size: labelSize,
                    weight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: sc.textHi,
                  ),
                ),
                const SizedBox(height: Sp.s1),
                Text(
                  section.sub,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SatType.sans(
                    size: subSize,
                    color: sc.textLo,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
