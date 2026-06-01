import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';

/// Renders a [MenuItem]'s photo, or its initials avatar when it has none.
///
/// Fills its parent and crops with `BoxFit.cover`, so the same widget serves
/// both the customer card banner (1.15:1) and the admin editor square. Bytes
/// are fetched over the pinned client and cached by `(id, photoRev)` — see
/// docs/adr/0014-menu-photo-blob-and-pinned-byte-fetch.md. While loading, on
/// error, or when [photoRev] is 0, the initials avatar shows — never a broken
/// image or empty box.
class MenuPhoto extends ConsumerWidget {
  final String itemId;
  final String name;
  final int photoRev;
  final BorderRadius borderRadius;
  final double initialsSize;

  const MenuPhoto({
    super.key,
    required this.itemId,
    required this.name,
    required this.photoRev,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.initialsSize = 22,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (photoRev <= 0) return _avatar(context);
    final async =
        ref.watch(menuPhotoBytesProvider((id: itemId, rev: photoRev)));
    return ClipRRect(
      borderRadius: borderRadius,
      child: async.when(
        data: (bytes) => bytes == null
            ? _avatar(context)
            : Image.memory(
                bytes,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                gaplessPlayback: true,
              ),
        loading: () => _avatar(context),
        error: (err, stack) => _avatar(context),
      ),
    );
  }

  Widget _avatar(BuildContext context) {
    final sc = context.sat;
    final trimmed = name.trim();
    final initials = trimmed.isEmpty
        ? '?'
        : trimmed
            .split(RegExp(r'\s+'))
            .take(2)
            .map((w) => w[0])
            .join()
            .toUpperCase();
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [sc.bg3, sc.bg4],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: SatType.sans(
          size: initialsSize,
          weight: FontWeight.w600,
          letterSpacing: -0.4,
          color: sc.textMd,
        ),
      ),
    );
  }
}
