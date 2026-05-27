import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
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

class VenueHubScreen extends StatelessWidget {
  const VenueHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.layout;
    if (l.useTabletShell) {
      return AdminPage(
        title: 'Venue',
        sub: 'Konfigurasi · lantai · menu · sistem · staf',
        children: [
          for (var i = 0; i < _sections.length; i++) ...[
            _HubRow(section: _sections[i], big: true),
            if (i != _sections.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }
    return _PhoneHub(sections: _sections);
  }
}

class _PhoneHub extends StatelessWidget {
  final List<_Section> sections;
  const _PhoneHub({required this.sections});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l = context.layout;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, l.topInset, 16, l.bottomInset + 40),
      children: [
        Padding(
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
        const SizedBox(height: 4),
        Padding(
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
        for (var i = 0; i < sections.length; i++) ...[
          _HubRow(section: sections[i], big: false),
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
    return Material(
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
    );
  }
}

