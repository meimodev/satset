import 'package:flutter/material.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/widgets/anim.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
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

const _uuid = Uuid();

Future<void> showModifierSheet({
  required BuildContext context,
  required MenuItem item,
  required ValueChanged<CartItem> onAdd,
}) {
  final l = context.layout;
  if (l.useTabletShell) {
    return showDialog(
      context: context,
      useRootNavigator: true,
      barrierColor: satBarrier,
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

  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: satBarrier,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scroll) => _ModifierSheetBody(
        item: item,
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
  const _ModifierSheetBody({
    required this.item,
    required this.onAdd,
    required this.scrollController,
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

  @override
  void initState() {
    super.initState();
    _variantId = widget.item.variants.first.id;
    for (final g in widget.item.modifierGroups) {
      _selections[g.id] = g.multi ? <String>[] : null;
    }
    _course = Courses.fromCategory(widget.item.categoryId);
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
        id: 'C${_uuid.v4()}',
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
          _Head(item: widget.item, onClose: () => Navigator.of(context).pop()),
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
                              text:
                                  'Cocok untuk ${_tagNames(widget.item.dietary, tagsById)}',
                            ),
                          if (widget.item.allergens.isNotEmpty &&
                              widget.item.dietary.isNotEmpty)
                            const SizedBox(height: Sp.s2),
                          if (widget.item.allergens.isNotEmpty)
                            _TagLine(
                              icon: Icons.warning_amber_rounded,
                              color: sc.urgent,
                              text:
                                  'Mengandung ${_tagNames(widget.item.allergens, tagsById)} — konfirmasi ke tamu',
                            ),
                        ],
                      ),
                    ),
                  if (widget.item.variants.length > 1)
                    _ModGroup(
                      title: 'Ukuran',
                      tag: 'WAJIB',
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
                          ? 'WAJIB'
                          : (g.multi ? 'BEBAS PILIH' : 'OPSIONAL'),
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
                  _ModGroup(
                    title: 'Course',
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
                    title: 'Instruksi khusus',
                    tag: 'OPSI TERAKHIR',
                    tagColor: sc.textLo,
                    border: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          maxLength: 80,
                          minLines: 2,
                          maxLines: 3,
                          onChanged: (v) => setState(() => _special = v),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: sc.bg2,
                            border: OutlineInputBorder(
                              borderRadius: SatR.a(14),
                              borderSide: SatB.side(
                                color: _special.isEmpty
                                    ? sc.border0
                                    : sc.accentBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: SatR.a(14),
                              borderSide: SatB.side(
                                color: _special.isEmpty
                                    ? sc.border0
                                    : sc.accentBorder,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: SatR.a(14),
                              borderSide: SatB.side(color: sc.accentBorder),
                            ),
                            hintText:
                                'mis. alergi belum tertera, catatan plating…',
                            hintStyle: SatType.sans(size: 13, color: sc.textLo),
                            counterText: '',
                          ),
                          style: SatType.sans(size: 13, color: sc.textHi),
                        ),
                        const SizedBox(height: Sp.s1),
                        Text(
                          '${_special.length} / 80 · tampil ke dapur',
                          style: SatType.mono(
                            size: 10,
                            color: sc.textLo,
                            letterSpacing: 0.4,
                          ),
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
            totalLabel: formatIDR(_unit * _qty),
            onDec: () => setState(() => _qty = (_qty - 1).clamp(1, 20)),
            onInc: () => setState(() => _qty = (_qty + 1).clamp(1, 20)),
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
          child: Text(
            text,
            style: SatType.sans(
              size: 12,
              weight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _Head extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onClose;
  const _Head({required this.item, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: MenuPhoto(
              itemId: item.id,
              name: item.name,
              photoRev: item.photoRev,
              borderRadius: SatR.a(14),
            ),
          ),
          const SizedBox(width: Sp.s3h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: SatType.sans(
                    size: 19,
                    weight: FontWeight.w600,
                    letterSpacing: -0.19,
                    height: 1.15,
                    color: sc.textHi,
                  ),
                ),
                const SizedBox(height: Sp.s1),
                Text(
                  item.description,
                  style: SatType.sans(size: 12, color: sc.textMd, height: 1.35),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: AppStrings.close,
            onPressed: onClose,
            icon: Icon(Icons.close, size: 18, color: sc.textMd),
          ),
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
                  child: Text(
                    title,
                    style: SatType.sans(
                      size: 14,
                      weight: FontWeight.w600,
                      letterSpacing: -0.14,
                      color: sc.textHi,
                    ),
                  ),
                ),
                Text(
                  tag,
                  style: SatType.mono(
                    size: 10,
                    weight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: tagColor,
                  ),
                ),
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
                      soldOut ? '$name · habis' : name,
                      style: SatType.sans(
                        size: 14,
                        color: soldOut ? sc.textLo : sc.textHi,
                      ),
                    ),
                  ),
                  if (delta != null && !soldOut)
                    Text(
                      delta!,
                      style: SatType.mono(
                        size: 12,
                        weight: FontWeight.w500,
                        color: selected ? sc.accentText : sc.textMd,
                        letterSpacing: 0,
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
    // Glow marks the chosen course with a solid slab rather than one step up
    // the neutral ramp. Which course a line fires on is not a soft preference
    // — it is the thing the kitchen reads off the ticket — and `bg4` on a bone
    // ground is a difference you have to look for.
    final glow = SatShape.glow;
    final on = glow ? sc.slab : sc;
    return PressScale(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Sp.s3, vertical: 9),
          decoration: SatBox.d(
            color: selected ? (glow ? on.bg0 : sc.bg4) : sc.bg2,
            borderRadius: SatR.a(999),
            border: SatB.all(color: selected ? sc.border2 : sc.border0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: SatBox.d(
                  shape: BoxShape.circle,
                  // The course hues are tuned as ink on the page. On the slab
                  // they are read from the inverted palette instead, which is
                  // the whole reason `slab` is a palette and not a colour.
                  color: selected ? course.color(on) : course.color(sc),
                ),
              ),
              const SizedBox(width: Sp.s2),
              Text(
                course.name,
                style: SatType.sans(
                  size: 13,
                  weight: glow && selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? on.textHi : sc.textMd,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Foot extends StatelessWidget {
  final int qty;
  final bool valid;
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
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: Sp.s1),
            decoration: SatBox.d(
              color: sc.bg2,
              borderRadius: SatR.a(14),
              border: SatB.all(color: sc.border0),
            ),
            child: Row(
              children: [
                _StepperBtn(label: '−', onTap: onDec, disabled: qty <= 1),
                SizedBox(
                  width: 28,
                  child: Text(
                    '$qty',
                    textAlign: TextAlign.center,
                    style: SatType.mono(
                      size: 15,
                      weight: FontWeight.w600,
                      color: sc.textHi,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                _StepperBtn(label: '+', onTap: onInc, disabled: false),
              ],
            ),
          ),
          const SizedBox(width: Sp.s3),
          Expanded(
            child: Opacity(
              opacity: valid ? 1 : 0.4,
              child: ElevatedButton(
                onPressed: valid ? onAdd : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: sc.accent,
                  disabledBackgroundColor: sc.accent,
                  foregroundColor: sc.accentInk,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: SatR.a(18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (valid)
                      Icon(Icons.add, size: 22, color: sc.accentInk)
                    else
                      Text(
                        'Pilih wajib',
                        style: SatType.sans(
                          size: 15,
                          weight: FontWeight.w600,
                          color: sc.accentInk,
                        ),
                      ),
                    if (valid) ...[
                      const SizedBox(width: Sp.s2h),
                      Text(
                        totalLabel,
                        style: SatType.mono(
                          size: 14,
                          weight: FontWeight.w500,
                          color: sc.accentInk.withValues(alpha: 0.7),
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool disabled;
  const _StepperBtn({
    required this.label,
    required this.onTap,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: double.infinity,
      child: SatButton.ghost(label: label, onTap: disabled ? null : onTap),
    );
  }
}
