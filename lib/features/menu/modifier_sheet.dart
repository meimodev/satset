import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../design/colors.dart';
import '../../design/format.dart';
import '../../design/layout.dart';
import '../../design/typography.dart';
import '../../models/cart_item.dart';
import '../../models/course.dart';
import '../../models/menu_item.dart';
import '../../models/modifier_group.dart';

const _uuid = Uuid();

Future<void> showModifierSheet({
  required BuildContext context,
  required MenuItem item,
  required ValueChanged<CartItem> onAdd,
}) {
  final isTablet = SatLayout.of(context).useTabletShell;
  if (isTablet) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) {
        final sc = ctx.sat;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 700),
            child: Container(
              decoration: BoxDecoration(
                color: sc.bg1,
                border: Border.all(color: sc.border1),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 80,
                    offset: const Offset(0, 32),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
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
        );
      },
    );
  }
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: 0.5),
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

class _ModifierSheetBody extends StatefulWidget {
  final MenuItem item;
  final ValueChanged<CartItem> onAdd;
  final ScrollController scrollController;
  const _ModifierSheetBody(
      {required this.item, required this.onAdd, required this.scrollController});

  @override
  State<_ModifierSheetBody> createState() => _ModifierSheetBodyState();
}

class _ModifierSheetBodyState extends State<_ModifierSheetBody> {
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
    final labels = <String>[];
    for (final g in widget.item.modifierGroups) {
      final v = _selections[g.id];
      if (g.multi && v is List<String>) {
        for (final id in v) {
          final o = g.options.firstWhere(
            (o) => o.id == id,
            orElse: () => const ModifierOption(id: '', name: ''),
          );
          if (o.id.isNotEmpty) {
            labels.add('${o.priceDelta > 0 ? '+ ' : ''}${o.name}');
          }
        }
      } else if (v is String) {
        final o = g.options.firstWhere(
          (o) => o.id == v,
          orElse: () => const ModifierOption(id: '', name: ''),
        );
        if (o.id.isNotEmpty) labels.add(o.name);
      }
    }
    final variant = widget.item.variants.firstWhere((v) => v.id == _variantId);
    widget.onAdd(CartItem(
      id: 'C${_uuid.v4()}',
      itemId: widget.item.id,
      name: widget.item.name,
      station: widget.item.station,
      variantId: _variantId,
      variantName: variant.name,
      modifiers: labels,
      modifierIds: Map<String, dynamic>.from(_selections),
      special: _special,
      course: _course,
      qty: _qty,
      unitPrice: _unit,
      allergens: widget.item.allergens,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      decoration: BoxDecoration(
        color: sc.bg1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 4),
            child: Container(
              width: 38,
              height: 4,
              decoration:
                  BoxDecoration(color: sc.textDim, borderRadius: BorderRadius.circular(4)),
            ),
          ),
          _Head(item: widget.item, onClose: () => Navigator.of(context).pop()),
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.item.allergens.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: sc.urgentSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: sc.urgent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 14, color: sc.urgent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Mengandung ${widget.item.allergens.map((a) => allergenNames[a]!.toLowerCase()).join(', ')} — konfirmasi ke tamu',
                              style: SatType.sans(
                                size: 12,
                                weight: FontWeight.w500,
                                color: sc.urgent,
                              ),
                            ),
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
                              onTap: () => setState(() => _variantId = v.id),
                            ),
                        ],
                      ),
                    ),
                  for (final g in widget.item.modifierGroups)
                    _ModGroup(
                      title: g.name,
                      tag: g.required ? 'WAJIB' : (g.multi ? 'BEBAS PILIH' : 'OPSIONAL'),
                      tagColor: g.required ? sc.urgent : sc.textLo,
                      child: Column(
                        children: [
                          for (final o in g.options)
                            _ModOpt(
                              selected: g.multi
                                  ? (_selections[g.id] as List<String>? ?? const [])
                                      .contains(o.id)
                                  : _selections[g.id] == o.id,
                              multi: g.multi,
                              name: o.name,
                              delta: o.priceDelta == 0
                                  ? null
                                  : '${o.priceDelta > 0 ? '+ ' : '− '}${formatIDR(o.priceDelta.abs())}',
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
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  BorderSide(color: _special.isEmpty ? sc.border0 : sc.urgent),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  BorderSide(color: _special.isEmpty ? sc.border0 : sc.urgent),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: sc.accentBorder),
                            ),
                            hintText: 'mis. alergi belum tertera, catatan plating…',
                            hintStyle: SatType.sans(size: 13, color: sc.textLo),
                            counterText: '',
                          ),
                          style: SatType.sans(size: 13, color: sc.textHi),
                        ),
                        const SizedBox(height: 4),
                        Text('${_special.length} / 80 · merah di KDS',
                            style: SatType.mono(
                              size: 10,
                              color: sc.textLo,
                              letterSpacing: 0.4,
                            )),
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
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: sc.bg3,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: SatType.sans(
                      size: 19,
                      weight: FontWeight.w600,
                      letterSpacing: -0.19,
                      height: 1.15,
                      color: sc.textHi,
                    )),
                const SizedBox(height: 4),
                Text(item.description,
                    style: SatType.sans(size: 12, color: sc.textMd, height: 1.35)),
              ],
            ),
          ),
          IconButton(
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
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border ? sc.border0 : Colors.transparent)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(title,
                      style: SatType.sans(
                        size: 14,
                        weight: FontWeight.w600,
                        letterSpacing: -0.14,
                        color: sc.textHi,
                      )),
                ),
                Text(tag,
                    style: SatType.mono(
                      size: 10,
                      weight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: tagColor,
                    )),
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
  const _ModOpt({
    required this.selected,
    required this.multi,
    required this.name,
    required this.delta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? sc.accentSoft : sc.bg2,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? sc.accentBorder : sc.border0),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: selected ? sc.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(multi ? 6 : 999),
                    border: Border.all(
                      color: selected ? sc.accent : sc.border2,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: selected
                      ? Icon(Icons.check, size: 14, color: sc.accentInk)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(name,
                      style: SatType.sans(size: 14, color: sc.textHi)),
                ),
                if (delta != null)
                  Text(delta!,
                      style: SatType.mono(
                        size: 12,
                        weight: FontWeight.w500,
                        color: selected ? sc.accent : sc.textMd,
                        letterSpacing: 0,
                      )),
              ],
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
  const _CourseChip(
      {required this.course, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? sc.bg4 : sc.bg2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? sc.border2 : sc.border0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: course.color(sc)),
            ),
            const SizedBox(width: 8),
            Text(course.name,
                style: SatType.sans(
                  size: 13,
                  color: selected ? sc.textHi : sc.textMd,
                )),
          ],
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
      decoration: BoxDecoration(
        color: sc.bg1,
        border: Border(top: BorderSide(color: sc.border0)),
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: sc.bg2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: sc.border0),
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
          const SizedBox(width: 12),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(valid ? 'Tambah ke pesanan' : 'Pilih wajib',
                        style: SatType.sans(
                          size: 15,
                          weight: FontWeight.w600,
                          color: sc.accentInk,
                        )),
                    if (valid) ...[
                      const SizedBox(width: 10),
                      Text(totalLabel,
                          style: SatType.mono(
                            size: 14,
                            weight: FontWeight.w500,
                            color: sc.accentInk.withValues(alpha: 0.7),
                            letterSpacing: 0,
                          )),
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
  const _StepperBtn(
      {required this.label, required this.onTap, required this.disabled});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return SizedBox(
      width: 38,
      height: double.infinity,
      child: TextButton(
        onPressed: disabled ? null : onTap,
        style: TextButton.styleFrom(
          foregroundColor: sc.textHi,
          disabledForegroundColor: sc.textDim,
          padding: EdgeInsets.zero,
        ),
        child: Text(label,
            style: SatType.sans(
              size: 20,
              color: disabled ? sc.textDim : sc.textHi,
            )),
      ),
    );
  }
}
