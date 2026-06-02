import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    label: 'Lantai',
    sub: 'Atur zona, meja, dan kapasitas ruangan',
    icon: Icons.place_outlined,
    route: '/floor',
    tint: (sc) => sc.accent,
  ),
  _Section(
    label: 'Menu',
    sub: 'Kategori, item, modifier, dan harga',
    icon: Icons.menu_rounded,
    route: '/menuadm',
    tint: (sc) => sc.warn,
  ),
  _Section(
    label: 'Identitas venue',
    sub: 'Profil, lokal, pajak, dan branding struk',
    icon: Icons.storefront_outlined,
    route: '/venue-identity',
    tint: (sc) => sc.violet,
  ),
  _Section(
    label: 'Sistem',
    sub: 'Server, jaringan, printer, perangkat',
    icon: Icons.wifi_rounded,
    route: '/system',
    tint: (sc) => sc.info,
  ),
  _Section(
    label: 'Staf',
    sub: 'Akun, peran, dan PIN tim',
    icon: Icons.person_outline_rounded,
    route: '/staff',
    tint: (sc) => sc.success,
  ),
  _Section(
    label: 'Laporan',
    sub: 'Ringkasan shift, penjualan, dan ekspor',
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
        title: 'Venue',
        sub: 'Konfigurasi · lantai · menu · sistem · staf',
        children: [
          if (showSeed) ...[
            const Reveal(index: 0, child: SeedDataBanner()),
            const SizedBox(height: 12),
          ],
          for (var i = 0; i < _sections.length; i++) ...[
            Reveal(
                index: i + (showSeed ? 1 : 0),
                child: _HubRow(section: _sections[i], big: true)),
            if (i != _sections.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }
    return _PhoneHub(sections: _sections, showSeed: showSeed);
  }
}

/// First-run prompt offering to load the generic restaurant dataset. Shown on
/// the Venue Hub only while the host DB is empty and the admin hasn't
/// dismissed it this session. See ADR-0017.
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
                child: Text('Mulai cepat',
                    style: SatType.sans(
                        size: 15,
                        weight: FontWeight.w700,
                        color: sc.textHi)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Muat contoh data restoran umum: 2 zona (Dalam & Luar) dengan '
            'meja, menu lengkap, dan 2 staf (pelayan & dapur). Bisa diubah '
            'kapan saja.',
            style: SatType.sans(size: 12.5, color: sc.textLo, height: 1.35),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _BannerBtn(
                  label: st.loading ? 'Memuat…' : 'Muat contoh data',
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
                                        Text('Gagal memuat contoh data')),
                              );
                            }
                          }
                        },
                ),
              ),
              const SizedBox(width: 10),
              _BannerBtn(
                label: 'Nanti',
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
                Text('Venue',
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
              'Konfigurasi',
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
        for (var i = 0; i < sections.length; i++) ...[
          Reveal(
              index: i + (showSeed ? 3 : 2),
              child: _HubRow(section: sections[i], big: false)),
          if (i != sections.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _HubRow extends StatelessWidget {
  final _Section section;
  final bool big;
  const _HubRow({required this.section, required this.big});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final tint = section.tint(sc);
    final radius = big ? 18.0 : 14.0;
    final iconBox = big ? 52.0 : 40.0;
    final iconSize = big ? 24.0 : 18.0;
    final labelSize = big ? 17.0 : 15.0;
    final subSize = big ? 12.0 : 11.5;
    final padV = big ? 18.0 : 14.0;
    final padH = big ? 20.0 : 14.0;
    return PressScale(
      child: Material(
      color: sc.bg2,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: () => context.push(section.route),
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: sc.border0),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
              SizedBox(width: big ? 16 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(section.label,
                        style: SatType.sans(
                          size: labelSize,
                          weight: FontWeight.w600,
                          letterSpacing: -0.2,
                          color: sc.textHi,
                        )),
                    const SizedBox(height: 3),
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
              const SizedBox(width: 10),
              Icon(Icons.chevron_right_rounded,
                  size: big ? 22 : 18, color: sc.textLo),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

