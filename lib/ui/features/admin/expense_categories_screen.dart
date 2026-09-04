/// The owner's [[Pengeluaran kunjungan]] category catalogue (ADR-0130).
/// Reached from Venue Settings and gated by `editSettings`.
///
/// Shaped after the [[Preset diskon]] editor, with one deliberate difference:
/// **there is no delete.** A preset's name is snapshotted onto every discount
/// it applied, so deleting one cannot corrupt settled history; a category's is
/// not, so removing one would orphan every expense filed under it and leave a
/// closed month rendering an id where a word should be. `active` parks a
/// category the venue has stopped using.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/data/models/visit_expense_dto.dart';
import 'package:satset/data/repositories/visit_expense_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_app_bar.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_card.dart';
import 'package:satset/ui/core/widgets/sat_empty.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/ui/core/widgets/sat_sheet_header.dart';
import 'package:satset/ui/core/widgets/sat_toggle.dart';

class ExpenseCategoriesScreen extends ConsumerWidget {
  const ExpenseCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final l10n = context.l10n;
    final cats = [...ref.watch(expenseCategoriesRepositoryProvider)]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final repo = ref.read(expenseCategoriesRepositoryProvider.notifier);

    return Scaffold(
      backgroundColor: sc.bg0,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, null, repo: repo, nextOrder: cats.length),
        icon: const Icon(Icons.add),
        label: Text(l10n.expCatNew),
      ),
      body: Column(
        children: [
          SatAppBar(
            onBack: () => context.pop(),
            crumbs: [l10n.tabVenue, l10n.expCatCrumb],
          ),
          Expanded(
            child: cats.isEmpty
                ? SatEmpty(
                    icon: Icons.shopping_bag_outlined,
                    title: l10n.expCatEmpty,
                    body: l10n.expCatEmptyBody,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(Sp.s4),
                    itemCount: cats.length,
                    separatorBuilder: (_, _) => const SizedBox(height: Sp.s2),
                    itemBuilder: (_, i) => _CategoryTile(
                      category: cats[i],
                      onTap: () => _edit(
                        context,
                        cats[i],
                        repo: repo,
                        nextOrder: cats.length,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _edit(
    BuildContext context,
    VisitExpenseCategoryDto? existing, {
    required ExpenseCategoriesRepository repo,
    required int nextOrder,
  }) {
    showSatSheet<void>(
      context,
      builder: (_) => _CategorySheet(
        existing: existing,
        repo: repo,
        nextOrder: nextOrder,
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final VisitExpenseCategoryDto category;
  final VoidCallback onTap;
  const _CategoryTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return SatCard.tappable(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Text(
              // Venue-authored content, so it is ARB-exempt.
              category.name,
              style: SatType.bodyL(
                color: category.active ? sc.textHi : sc.textDim,
              ),
            ),
          ),
          if (!category.active)
            Text(
              context.l10n.expCatParked,
              style: SatType.labelS(color: sc.textDim),
            ),
        ],
      ),
    );
  }
}

class _CategorySheet extends StatefulWidget {
  final VisitExpenseCategoryDto? existing;
  final ExpenseCategoriesRepository repo;
  final int nextOrder;
  const _CategorySheet({
    required this.existing,
    required this.repo,
    required this.nextOrder,
  });

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  late final _name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late bool _active = widget.existing?.active ?? true;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || _name.text.trim().isEmpty) return;
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    await widget.repo.save(
      id: widget.existing?.id,
      name: _name.text.trim(),
      active: _active,
      sortOrder: widget.existing?.sortOrder ?? widget.nextOrder,
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Padding(
        padding: const EdgeInsets.only(
          left: Sp.s4,
          right: Sp.s4,
          bottom: Sp.s4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SatSheetHeader(
              padding: const EdgeInsets.only(top: Sp.s3, bottom: Sp.s2),
              onClose: () => Navigator.of(context).pop(),
              child: Text(
                widget.existing == null ? l10n.expCatNew : l10n.expCatEdit,
                style: SatType.h3(color: sc.textHi),
              ),
            ),
            SatField.text(
              controller: _name,
              label: l10n.expCatName,
              hint: '',
              autofocus: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Sp.s3),
            // The only lifecycle a category has. Nothing deletes one — see the
            // library comment.
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.expCatActive,
                    style: SatType.bodyM(color: sc.textHi),
                  ),
                ),
                SatToggle(
                  value: _active,
                  semanticLabel: l10n.expCatActive,
                  onChanged: (v) => setState(() => _active = v),
                ),
              ],
            ),
            const SizedBox(height: Sp.s2),
            Text(
              l10n.expCatNoDelete,
              style: SatType.bodyS(color: sc.textDim),
            ),
            const SizedBox(height: Sp.s4),
            SatButton.primary(
              label: l10n.save,
              icon: Icons.check_rounded,
              onTap: _name.text.trim().isEmpty || _busy ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
