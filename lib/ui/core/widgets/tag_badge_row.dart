import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/domain/models/menu_tag.dart';

/// One wrapping row of 2-char code badges, kind-coloured. Used on the menu
/// item card and on line items (review + table detail). Allergens render
/// `urgent`/red, diet renders `info`/blue — colour is passed by the caller
/// since it is kind-derived, not per-tag.
class TagBadgeRow extends StatelessWidget {
  final List<String> ids;
  final Map<String, MenuTag> tagsById;
  final Color fg;
  final Color bg;
  const TagBadgeRow({
    super.key,
    required this.ids,
    required this.tagsById,
    required this.fg,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final id in ids)
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(tagsById[id]?.code ?? '?',
                  style: SatType.mono(
                    size: 8,
                    weight: FontWeight.w600,
                    color: fg,
                    letterSpacing: 0,
                  )),
            ),
        ],
      ),
    );
  }
}

/// Per-line-item allergen + diet badge stack, **live-resolved** from the menu
/// snapshot by [itemId] (see ADR-0012 — tags are not frozen onto sent lines).
/// Renders the allergen row (red) then the diet row (blue). Shrinks to nothing
/// when the item has no tags or no longer resolves; callers suppress it on
/// voided lines by simply not mounting it.
class MenuTagBadges extends ConsumerWidget {
  final String itemId;

  /// Gap above the first row, so the badges sit just under the dish name.
  final double topGap;
  const MenuTagBadges({super.key, required this.itemId, this.topGap = 4});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final item = ref
        .watch(menuItemsProvider)
        .where((i) => i.id == itemId)
        .firstOrNull;
    if (item == null) return const SizedBox.shrink();
    final allergens = item.allergens;
    final dietary = item.dietary;
    if (allergens.isEmpty && dietary.isEmpty) return const SizedBox.shrink();
    final tagsById = ref.watch(menuTagsByIdProvider);

    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (allergens.isNotEmpty)
            Row(children: [
              TagBadgeRow(
                ids: allergens,
                tagsById: tagsById,
                fg: sc.urgent,
                bg: sc.urgentSoft,
              ),
            ]),
          if (dietary.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: allergens.isNotEmpty ? 3 : 0),
              child: Row(children: [
                TagBadgeRow(
                  ids: dietary,
                  tagsById: tagsById,
                  fg: sc.info,
                  bg: sc.infoSoft,
                ),
              ]),
            ),
        ],
      ),
    );
  }
}
