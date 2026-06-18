import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/data/repositories/generic_seed.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/anim.dart';
import '_common.dart';

class _Section {
  final String label;
  final String sub;
  final IconData icon;
  final String route;
  final Color Function(SatColors) tint;
  const _Section({
    required this.label,
    required this.sub,
    required this.icon,
    required this.route,
    required this.tint,
  });
}

final _sections = <_Section>[
  _Section(
    label: AppStrings.venueHubSectionZona,
    sub: AppStrings.venueHubSectionZonaSub,
    icon: Icons.place_outlined,
    route: '/zone-admin',
    tint: (sc) => sc.accent,
  ),
  _Section(
    label: AppStrings.venueHubSectionMenu,
    sub: AppStrings.venueHubSectionMenuSub,
    icon: Icons.menu_rounded,
    route: '/menuadm',
    tint: (sc) => sc.warn,
  ),
  _Section(
    label: AppStrings.venueHubSectionVenue,
    sub: AppStrings.venueHubSectionVenueSub,
    icon: Icons.storefront_outlined,
    route: '/venue-settings',
    tint: (sc) => sc.violet,
  ),
  _Section(
    label: AppStrings.venueHubSectionSystem,
    sub: AppStrings.venueHubSectionSystemSub,
    icon: Icons.wifi_rounded,
    route: '/system',
    tint: (sc) => sc.info,
  ),
  _Section(
    label: AppStrings.venueHubSectionStaff,
    sub: AppStrings.venueHubSectionStaffSub,
    icon: Icons.person_outline_rounded,
    route: '/staff',
    tint: (sc) => sc.success,
  ),
  _Section(
    label: AppStrings.venueHubSectionReports,
    sub: AppStrings.venueHubSectionReportsSub,
    icon: Icons.auto_awesome_outlined,
    route: '/reports',
    tint: (sc) => sc.urgent,
  ),
];

class VenueHubScreen extends ConsumerWidget {
  const VenueHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.layout;
    final showSeed = ref.watch(genericSeedProvider).showPrompt;
    if (l.useTabletShell) {
      return AdminPage(
        title: AppStrings.venueHubTitle,
        sub: AppStrings.venueHubSubtitle,
        children: [
          if (showSeed) ...[
            const Reveal(index: 0, child: SeedDataBanner()),
            const SizedBox(height: 16),
          ],
          _HubGrid(sections: _sections, seedOffset: showSeed ? 1 : 0, big: true),
        ],
      );
    }
    return _PhoneHub(sections: _sections, showSeed: showSeed);
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sc.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sc.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_fix_high_rounded, size: 18, color: sc.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(AppStrings.venueHubSeedTitle,
                    style: SatType.sans(
                        size: 15,
                        weight: FontWeight.w700,
                        color: sc.textHi)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.venueHubSeedBody,
            style: SatType.sans(size: 12.5, color: sc.textLo, height: 1.35),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _BannerBtn(
                  label: st.loading ? AppStrings.loading : AppStrings.venueHubSeedBtnLoad,
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
                                    content:
                                        Text(AppStrings.venueHubSeedError)),
                              );
                            }
                          }
                        },
                ),
              ),
              const SizedBox(width: 10),
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
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: filled ? null : Border.all(color: sc.border1),
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
                      strokeWidth: 2, color: sc.bg0),
                ),
                const SizedBox(width: 8),
              ],
              Text(label,
                  style: SatType.sans(
                    size: 13,
                    weight: FontWeight.w600,
                    color: filled ? sc.bg0 : sc.textHi,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

/// 2-column grid of hub cards. Wraps in rows of 2.
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
  const _PhoneHub({required this.sections, this.showSeed = false});

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
                const SizedBox(width: 6),
                Text(AppStrings.venueHubTitle,
                    style: SatType.sans(
                        size: 14,
                        weight: FontWeight.w500,
                        color: sc.textHi)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
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
        if (showSeed) ...[
          const Reveal(index: 2, child: SeedDataBanner()),
          const SizedBox(height: 12),
        ],
        _HubGrid(
          sections: sections,
          seedOffset: showSeed ? 3 : 2,
        ),
      ],
    );
  }
}

class _HubCard extends StatelessWidget {
  final _Section section;
  final bool big;
  const _HubCard({required this.section, required this.big});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final tint = section.tint(sc);
    final radius = big ? 18.0 : 16.0;
    final iconBox = big ? 48.0 : 42.0;
    final iconSize = big ? 24.0 : 20.0;
    final labelSize = big ? 15.0 : 14.0;
    final subSize = big ? 11.5 : 11.0;
    return PressScale(
      child: Material(
        color: sc.bg2,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: () => context.push(section.route),
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            padding: EdgeInsets.all(big ? 16 : 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: sc.border0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: iconBox,
                  height: iconBox,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(big ? 14 : 12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(section.icon, size: iconSize, color: tint),
                ),
                const SizedBox(height: 14),
                Text(section.label,
                    style: SatType.sans(
                      size: labelSize,
                      weight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: sc.textHi,
                    )),
                const SizedBox(height: 4),
                Text(section.sub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SatType.sans(
                        size: subSize,
                        color: sc.textLo,
                        height: 1.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
