import 'package:flutter/material.dart';
import 'package:satset/ui/core/widgets/sat_sheet_header.dart';
import 'package:satset/ui/core/widgets/sat_stepper.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/domain/models/venue_module.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/domain/models/cart_item.dart';
import 'package:satset/domain/models/course.dart';
import 'package:satset/domain/models/menu_item.dart';
import 'package:satset/domain/models/menu_tag.dart';
import 'package:satset/domain/models/modifier_group.dart';
import 'package:satset/domain/models/ticket_modifier.dart';
import 'package:satset/ui/core/design/course_visuals.dart';
import 'package:satset/ui/core/widgets/menu_photo.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/core/localization/labels.dart';
import 'package:satset/core/localization/locale_view_model.dart';

const _uuid = Uuid();

/// Ceiling for one trip through the sheet. Repeated adds stack past this on
/// the cart line itself, up to `kCartLineMaxQty` (ADR-0060).
const int _kMaxPerAdd = 20;

/// Opens the item configurator. Pass [editing] to reopen it over a line that
/// is already in the cart — the sheet seeds itself from that line and the foot
/// button says "Simpan". Same sheet either way: one place owns the modifier
/// rendering, the price math and the required-group validation (ADR-0060).
Future<void> showModifierSheet({
  required BuildContext context,
  required MenuItem item,
  required ValueChanged<CartItem> onAdd,
  CartItem? editing,
}) {
  final l = context.layout;
  if (l.useTabletShell) {
    return showSatDialog(
      context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: Sp.s10,
          vertical: Sp.s6,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ClipRRect(
            borderRadius: SatR.a(28),
            child: Container(
              color: ctx.sat.bg1,
              child: _ModifierSheetBody(
                item: item,
                editing: editing,
                scrollController: ScrollController(),
                onAdd: (ci) {
                  onAdd(ci);
                  Navigator.of(ctx).pop();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  return showSatSheet(
    context,
    bare: true,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scroll) => _ModifierSheetBody(
        item: item,
        editing: editing,
        scrollController: scroll,
        onAdd: (ci) {
          onAdd(ci);
          Navigator.of(ctx).pop();
        },
      ),
    ),
  );
}

class _ModifierSheetBody extends ConsumerStatefulWidget {
  final MenuItem item;
  final ValueChanged<CartItem> onAdd;
  final ScrollController scrollController;

  /// The cart line being re-configured, or null when adding a new one.
  final CartItem? editing;

  const _ModifierSheetBody({
    required this.item,
    required this.onAdd,
    required this.scrollController,
    this.editing,
  });

  @override
  ConsumerState<_ModifierSheetBody> createState() => _ModifierSheetBodyState();
}

class _ModifierSheetBodyState extends ConsumerState<_ModifierSheetBody> {
  late String _variantId;
  final Map<String, dynamic> _selections = {};
  String _special = '';
  late CourseId _course;
  int _qty = 1;

  late final TextEditingController _noteCtl;

  @override
  void initState() {
    super.initState();
    final edit = widget.editing;
    // A variant can be retired from the menu while the line sits in the cart;
    // fall back rather than throw on a `firstWhere` that finds nothing.
    final variantIds = widget.item.variants.map((v) => v.id).toSet();
    _variantId = edit != null && variantIds.contains(edit.variantId)
        ? edit.variantId
        : widget.item.variants.first.id;
    for (final g in widget.item.modifierGroups) {
      final chosen = edit == null
          ? const <String>[]
          : [
              for (final m in edit.selectedModifiers)
                if (m.groupId == g.id) m.optionId,
            ];
      _selections[g.id] = g.multi
          ? chosen.toList()
          : (chosen.isEmpty ? null : chosen.first);
    }
    _special = edit?.note ?? '';
    _noteCtl = TextEditingController(text: _special);
    // [[Kedai]] switch `simpleKds` (ADR-0109): a counter has one pace, "now".
    // Forced at the source rather than filtered at the KDS, because a line that
    // was never paced is a line no one has to un-pace — the alternative leaves
    // `held` tickets sitting behind a fire button the counter's rail no longer
    // shows. An **edited** line keeps whatever course it already carries: the
    // switch changes what gets typed next, never what is already in the cart.
    // [[Tanpa antrian persiapan]] (ADR-0115) collapses the pace for the same
    // reason and one step harder: there is no queue to pace *into*, so every
    // line is "now" whether or not the venue is a counter shop.
    final s = ref.read(venueSettingsProvider);
    _course = edit?.course ??
        (s.counterOn(counterSimpleKds) || s.bypassKds
            ? CourseId.fireNow
            : Courses.fromCategory(widget.item.categoryId));
    _qty = edit?.qty ?? 1;
  }

  @override
  void dispose() {
    _noteCtl.dispose();
    super.dispose();
  }

  bool get _valid {
    for (final g in widget.item.modifierGroups) {
      if (!g.required) continue;
      final v = _selections[g.id];
      if (g.multi) {
        if (v is! List || v.isEmpty) return false;
      } else {
        if (v == null) return false;
      }
    }
    return true;
  }

  int get _unit {
    final variant = widget.item.variants.firstWhere((v) => v.id == _variantId);
    var p = variant.price;
    for (final g in widget.item.modifierGroups) {
      final v = _selections[g.id];
      if (g.multi && v is List<String>) {
        for (final id in v) {
          final o = g.options.firstWhere(
            (o) => o.id == id,
            orElse: () => const ModifierOption(id: '', name: ''),
          );
          p += o.priceDelta;
        }
      } else if (v is String) {
        final o = g.options.firstWhere(
          (o) => o.id == v,
          orElse: () => const ModifierOption(id: '', name: ''),
        );
        p += o.priceDelta;
      }
    }
    return p;
  }

  void _toggle(ModifierGroup g, String optId) {
    setState(() {
      if (g.multi) {
        final arr = List<String>.from(_selections[g.id] as List? ?? const []);
        if (arr.contains(optId)) {
          arr.remove(optId);
        } else {
          arr.add(optId);
        }
        _selections[g.id] = arr;
      } else {
        _selections[g.id] = optId;
      }
    });
  }

  void _submit() {
    // Build the structured snapshot once; the display labels derive from it
    // (clean label + sign from priceDelta). Both single- and multi-select
    // groups are captured — the old id-flatten dropped single-select. See
    // docs/adr/0011-ticket-modifier-snapshot.md.
    final selected = <TicketModifier>[];
    for (final g in widget.item.modifierGroups) {
      final v = _selections[g.id];
      final ids = g.multi && v is List<String>
          ? v
          : (v is String ? [v] : const <String>[]);
      for (final id in ids) {
        final o = g.options.firstWhere(
          (o) => o.id == id,
          orElse: () => const ModifierOption(id: '', name: ''),
        );
        if (o.id.isEmpty) continue;
        selected.add(
          TicketModifier(
            groupId: g.id,
            optionId: o.id,
            label: o.name,
            priceDelta: o.priceDelta,
          ),
        );
      }
    }
    final variant = widget.item.variants.firstWhere((v) => v.id == _variantId);
    widget.onAdd(
      CartItem(
        // Keeps the line's identity when re-configuring, so the cart replaces
        // rather than orphans it.
        id: widget.editing?.id ?? 'C${_uuid.v4()}',
        itemId: widget.item.id,
        name: widget.item.name,
        variantId: _variantId,
        variantName: variant.name,
        modifiers: [for (final m in selected) m.display],
        selectedModifiers: selected,
        note: _special,
        course: _course,
        qty: _qty,
        unitPrice: _unit,
        allergens: widget.item.allergens,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l = context.layout;
    final tagsById = ref.watch(menuTagsByIdProvider);
    final isTablet = l.useTabletShell;
    return Container(
      decoration: SatBox.d(
        color: sc.bg1,
        borderRadius: isTablet
            ? SatR.a(28)
            : BorderRadius.vertical(top: SatR.c(28)),
      ),
      child: Column(
        children: [
          if (!isTablet)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 4),
              child: Container(
                width: 38,
                height: 4,
                decoration: SatBox.d(
                  color: sc.textDim,
                  borderRadius: SatR.a(4),
                ),
              ),
            ),
          _ModifierHead(
            item: widget.item,
            onClose: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              padding: const EdgeInsets.only(bottom: Sp.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.item.allergens.isNotEmpty ||
                      widget.item.dietary.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: Sp.s3,
                        vertical: Sp.s2h,
                      ),
                      decoration: SatBox.d(
                        color: sc.bg2,
                        borderRadius: SatR.a(12),
                        border: SatB.all(color: sc.border0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.item.dietary.isNotEmpty)
                            _TagLine(
                              icon: Icons.eco_outlined,
                              color: sc.info,
                              text: context.l10n.modDietaryLine(
                                _tagNames(widget.item.dietary, tagsById),
                              ),
                            ),
                          if (widget.item.allergens.isNotEmpty &&
                              widget.item.dietary.isNotEmpty)
                            const SizedBox(height: Sp.s2),
                          if (widget.item.allergens.isNotEmpty)
                            _TagLine(
                              icon: Icons.warning_amber_rounded,
                              color: sc.urgent,
                              text: context.l10n.modAllergenLine(
                                _tagNames(widget.item.allergens, tagsById),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (widget.item.variants.length > 1)
                    _ModGroup(
                      title: context.l10n.modSize,
                      tag: context.l10n.modTagRequired,
                      tagColor: sc.urgent,
                      child: Column(
                        children: [
                          for (final v in widget.item.variants)
                            _ModOpt(
                              selected: _variantId == v.id,
                              multi: false,
                              name: v.name.isEmpty ? 'Reguler' : v.name,
                              delta: formatIDR(v.price),
                              soldOut: widget.item.isVariantSoldOut(v.id),
                              onTap: () => setState(() => _variantId = v.id),
                            ),
                        ],
                      ),
                    ),
                  for (final g in widget.item.modifierGroups)
                    _ModGroup(
                      title: g.name,
                      tag: g.required
                          ? context.l10n.modTagRequired
                          : (g.multi
                                ? context.l10n.modTagFree
                                : context.l10n.modTagOptional),
                      tagColor: g.required ? sc.urgent : sc.textLo,
                      child: Column(
                        children: [
                          for (final o in g.options)
                            _ModOpt(
                              selected: g.multi
                                  ? (_selections[g.id] as List<String>? ??
                                            const [])
                                        .contains(o.id)
                                  : _selections[g.id] == o.id,
                              multi: g.multi,
                              name: o.name,
                              delta: o.priceDelta == 0
                                  ? null
                                  : '${o.priceDelta > 0 ? '+ ' : '− '}${formatIDR(o.priceDelta.abs())}',
                              soldOut: widget.item.isOptionSoldOut(o.id),
                              onTap: () => _toggle(g, o.id),
                            ),
                        ],
                      ),
                    ),
                  if (!ref.watch(
                    venueSettingsProvider.select(
                      (v) => v.counterOn(counterSimpleKds) || v.bypassKds,
                    ),
                  ))
                  _ModGroup(
                    title: context.l10n.expColCourse,
                    tag: 'TIMING',
                    tagColor: sc.textLo,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final c in const [
                          Courses.fireNow,
                          Courses.drinksNow,
                          Courses.starters,
                          Courses.mains,
                          Courses.desserts,
                        ])
                          _CourseChip(
                            course: c,
                            selected: _course == c.id,
                            onTap: () => setState(() => _course = c.id),
                          ),
                      ],
                    ),
                  ),
                  _ModGroup(
                    title: context.l10n.tblSpecialInstruction,
                    tag: 'OPSI TERAKHIR',
                    tagColor: sc.textLo,
                    border: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SatField.text(
                          controller: _noteCtl,
                          hint: context.l10n.modNoteHint,
                          maxLength: 80,
                          minLines: 2,
                          maxLines: 3,
                          onChanged: (v) => setState(() => _special = v),
                        ),
                        const SizedBox(height: Sp.s1),
                        Text(
                          // The note still travels with the line, but with no
                          // prep queue there is no kitchen display to name
                          // (ADR-0115) — it surfaces on the order itself.
                          ref.watch(venueSettingsProvider).bypassKds
                              ? context.l10n.modSpecialCounterNoPrep(
                                  _special.length,
                                )
                              : context.l10n.modSpecialCounter(
                                  _special.length,
                                ),
                          style: SatType.monoS(color: sc.textLo),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _Foot(
            qty: _qty,
            valid: _valid,
            editing: widget.editing != null,
            totalLabel: formatIDR(_unit * _qty),
            onDec: () =>
                setState(() => _qty = (_qty - 1).clamp(1, _kMaxPerAdd)),
            onInc: () =>
                setState(() => _qty = (_qty + 1).clamp(1, _kMaxPerAdd)),
            onAdd: _submit,
          ),
        ],
      ),
    );
  }
}

/// Comma-joined, lowercased tag names, resolving ids against the snapshot.
String _tagNames(List<String> ids, Map<String, MenuTag> tagsById) => ids
    .map((id) => (tagsById[id]?.name ?? '').toLowerCase())
    .where((s) => s.isNotEmpty)
    .join(', ');

/// One coloured icon+text line in the merged diet/allergen block.
class _TagLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _TagLine({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: Sp.s2),
        Expanded(
          child: Text(text, style: SatType.bodyS(color: color)),
        ),
      ],
    );
  }
}

class _ModifierHead extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onClose;
  const _ModifierHead({required this.item, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return SatSheetHeader(
      onClose: onClose,
      padding: const EdgeInsets.fromLTRB(Sp.s5, Sp.s3, Sp.s3, Sp.s3h),
      leading: SizedBox(
        width: 64,
        height: 64,
        child: MenuPhoto(
          itemId: item.id,
          name: item.name,
          photoRev: item.photoRev,
          borderRadius: SatR.lg,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name, style: SatType.h3(color: sc.textHi)),
          const SizedBox(height: Sp.s1),
          Text(item.description, style: SatType.bodyS(color: sc.textMd)),
        ],
      ),
    );
  }
}

class _ModGroup extends StatelessWidget {
  final String title;
  final String tag;
  final Color tagColor;
  final Widget child;
  final bool border;
  const _ModGroup({
    required this.title,
    required this.tag,
    required this.tagColor,
    required this.child,
    this.border = true,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: SatBox.d(
        border: Border(
          bottom: SatB.side(color: border ? sc.border0 : Colors.transparent),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: Sp.s2h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(title, style: SatType.labelM(color: sc.textHi)),
                ),
                Text(tag, style: SatType.caption(color: tagColor)),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _ModOpt extends StatelessWidget {
  final bool selected;
  final bool multi;
  final String name;
  final String? delta;
  final VoidCallback onTap;

  /// Derived from ingredient stock (ADR-0040): this exact choice cannot be
  /// made right now, even though the dish itself may still be orderable.
  final bool soldOut;
  const _ModOpt({
    required this.selected,
    required this.multi,
    required this.name,
    required this.delta,
    required this.onTap,
    this.soldOut = false,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.s1h),
      child: Opacity(
        opacity: soldOut ? 0.45 : 1,
        child: Material(
          color: selected ? sc.accentSoft : sc.bg2,
          borderRadius: SatR.a(14),
          child: InkWell(
            onTap: soldOut ? null : onTap,
            borderRadius: SatR.a(14),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Sp.s3h,
                vertical: Sp.s3,
              ),
              decoration: SatBox.d(
                borderRadius: SatR.a(14),
                border: SatB.all(
                  color: selected ? sc.accentBorder : sc.border0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: SatBox.d(
                      color: selected ? sc.accent : Colors.transparent,
                      borderRadius: SatR.a(multi ? 6 : 999),
                      border: SatB.all(
                        color: selected ? sc.accent : sc.border2,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: selected
                        ? Icon(Icons.check, size: 14, color: sc.accentInk)
                        : null,
                  ),
                  const SizedBox(width: Sp.s3),
                  Expanded(
                    child: Text(
                      soldOut ? context.l10n.modOptionSoldOut(name) : name,
                      style: SatType.bodyM(
                        color: soldOut ? sc.textLo : sc.textHi,
                      ),
                    ),
                  ),
                  if (delta != null && !soldOut)
                    Text(
                      delta!,
                      style: SatType.monoM(
                        color: selected ? sc.accentText : sc.textMd,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A course as a filter chip. Delegates to [SatChip.select] — the only thing
/// it adds is reading the course hue off the inverted palette when Glow paints
/// the selection as a slab (ADR-0051), which is a course fact, not a chip one.
class _CourseChip extends StatelessWidget {
  final Course course;
  final bool selected;
  final VoidCallback onTap;
  const _CourseChip({
    required this.course,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final on = SatShape.glow && selected ? sc.slab : sc;
    return SatChip.select(
      label: courseLabel(context.l10n, course.serialId),
      dot: course.color(on),
      selected: selected,
      onTap: onTap,
    );
  }
}

class _Foot extends StatelessWidget {
  final int qty;
  final bool valid;
  final bool editing;
  final String totalLabel;
  final VoidCallback onDec;
  final VoidCallback onInc;
  final VoidCallback onAdd;
  const _Foot({
    required this.qty,
    required this.valid,
    required this.totalLabel,
    required this.onDec,
    required this.onInc,
    required this.onAdd,
    this.editing = false,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 18,
      ),
      decoration: SatBox.d(
        color: sc.bg1,
        border: Border(top: SatB.side(color: sc.border0)),
      ),
      child: Row(
        children: [
          SatStepper(
            value: qty,
            min: 1,
            // Was left at the default 99 while the callbacks clamped at 20, so
            // the last twenty taps of `+` did nothing visible.
            max: _kMaxPerAdd,
            size: SatStepperSize.lg,
            semanticLabel: context.l10n.quantity,
            onChanged: (v) => v > qty ? onInc() : onDec(),
          ),
          const SizedBox(width: Sp.s3),
          Expanded(
            child: SatButton.primary(
              label: valid
                  ? (editing ? context.l10n.save : context.l10n.add)
                  : context.l10n.modPickRequired,
              icon: valid ? (editing ? Icons.check : Icons.add) : null,
              size: SatButtonSize.lg,
              trailingValue: valid ? totalLabel : null,
              onTap: valid ? onAdd : null,
            ),
          ),
        ],
      ),
    );
  }
}
