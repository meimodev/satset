import 'package:flutter/material.dart';
import 'package:satset/ui/core/widgets/sat_stepper.dart';
import 'package:satset/ui/core/widgets/sat_toggle.dart';
import 'package:satset/ui/core/widgets/sat_icon_button.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/shell_inset.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/domain/models/zone.dart';
import 'package:satset/ui/core/design/zone_visuals.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/zones_repository.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/motion.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/core/localization/locale_view_model.dart';

class ZoneAdminScreen extends ConsumerStatefulWidget {
  const ZoneAdminScreen({super.key});

  @override
  ConsumerState<ZoneAdminScreen> createState() => _ZoneAdminScreenState();
}

class _ZoneAdminScreenState extends ConsumerState<ZoneAdminScreen> {
  String? _selectedZoneId;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final zones = ref.watch(zonesProvider);
    final tables = ref.watch(tablesProvider);
    final layout = context.layout;
    final auth = ref.watch(authStateProvider);
    // The capability the server actually demands of every write this screen
    // makes (`POST`/`PATCH`/`DELETE /zones` all gate `editSettings`), not the
    // legacy `UserRole` bucket — that is a seed-and-reporting classification
    // and CONTEXT.md forbids reading it as a permission. See ADR-0132.
    final canManage = auth.has(Capability.editSettings);

    if (zones.isEmpty) {
      return SafeArea(child: _noZones(context, sc, canManage));
    }

    final selected = zones.firstWhere(
      (z) => z.id == _selectedZoneId,
      orElse: () => zones.first,
    );
    final zoneTables = tables.where((t) => t.zoneId == selected.id).toList();
    final seats = tables.fold<int>(0, (s, t) => s + t.capacity);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _ZoneAdminHeader(
            sub: context.l10n.zonAdminSub(tables.length, zones.length, seats),
            canManage: canManage,
            onManageZones: () => _showZones(context),
          ),
          _ZoneBar(
            zones: zones,
            tables: tables,
            selectedId: selected.id,
            onSelect: (id) => setState(() => _selectedZoneId = id),
            onAdd: () => _editTable(context, null, selected.id),
          ),
          Expanded(
            child: zoneTables.isEmpty
                ? _emptyZone(context, sc, selected)
                : ReorderableListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      layout.gutter,
                      14,
                      layout.gutter,
                      context.shellInset,
                    ),
                    buildDefaultDragHandles: false,
                    proxyDecorator: (child, _, _) => _DragProxy(child: child),
                    itemCount: zoneTables.length,
                    onReorder: (o, n) => ref
                        .read(tablesProvider.notifier)
                        .reorderTable(selected.id, o, n),
                    itemBuilder: (ctx, i) {
                      final t = zoneTables[i];
                      return _TableRow(
                        key: ValueKey(t.id),
                        index: i,
                        table: t,
                        onTap: () => _editTable(context, t, selected.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyZone(BuildContext context, SatColors sc, Zone zone) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Sp.s6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.table_restaurant_outlined, size: 40, color: sc.textDim),
            const SizedBox(height: Sp.s3),
            Text(
              '${context.l10n.zoneAdminEmptyZone} ${zone.name}',
              style: SatType.bodyM(color: sc.textMd),
            ),
            const SizedBox(height: Sp.s4),
            SatButton.primary(
              label: context.l10n.zoneAdminAddTable,
              icon: Icons.add,
              onTap: () => _editTable(context, null, zone.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noZones(BuildContext context, SatColors sc, bool canManage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Sp.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.layers_outlined, size: 44, color: sc.textDim),
            const SizedBox(height: Sp.s3h),
            Text(
              context.l10n.zoneAdminNoZones,
              style: SatType.h3(color: sc.textHi),
            ),
            const SizedBox(height: Sp.s1h),
            Text(
              canManage
                  ? context.l10n.zoneAdminNoZonesCreate
                  : context.l10n.zoneAdminNoZonesCreateRequest,
              textAlign: TextAlign.center,
              style: SatType.bodyM(color: sc.textMd),
            ),
            if (canManage) ...[
              const SizedBox(height: Sp.s4h),
              SatButton.primary(
                label: context.l10n.zoneAdminAddZone,
                onTap: () => _showZones(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showZones(BuildContext context) {
    _present(context, const _ZonesEditor());
  }

  void _editTable(BuildContext context, VenueTable? table, String zoneId) {
    _present(context, _TableEditor(table: table, zoneId: zoneId));
  }
}

class _ZoneAdminHeader extends StatelessWidget {
  final String sub;
  final bool canManage;
  final VoidCallback onManageZones;
  const _ZoneAdminHeader({
    required this.sub,
    required this.canManage,
    required this.onManageZones,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
      decoration: SatBox.d(
        border: Border(bottom: SatB.side(color: sc.border0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.zoneAdminTitle,
                  style: SatType.h2(color: sc.textHi),
                ),
                const SizedBox(height: Sp.s1),
                Text(sub.toUpperCase(), style: SatType.monoS(color: sc.textLo)),
              ],
            ),
          ),
          if (canManage)
            SatButton.outline(
              icon: Icons.dashboard_customize_outlined,
              label: context.l10n.zoneAdminZonePill,
              onTap: onManageZones,
            )
          else
            SatChip.tag(
              label: context.l10n.zoneAdminZonePill,
              icon: Icons.lock_outline,
            ),
        ],
      ),
    );
  }
}

class _ZoneBar extends StatelessWidget {
  final List<Zone> zones;
  final List<VenueTable> tables;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdd;
  const _ZoneBar({
    required this.zones,
    required this.tables,
    required this.selectedId,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      // ponytail: no fixed bar height — a horizontal ListView hands its children
      // a tight cross-axis constraint, so a 60px bar minus 26px of padding left
      // 34px for a chip that needs ~37 and clipped it (worse at text scale). A
      // scroll view sizes to the chip instead. Eager children, but a venue has
      // a handful of zones.
      decoration: SatBox.d(
        border: Border(bottom: SatB.side(color: sc.border0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(Sp.s4, Sp.s2h, Sp.s2, Sp.s2h),
              child: Row(
                children: [
                  for (final (i, z) in zones.indexed) ...[
                    if (i > 0) const SizedBox(width: Sp.s2),
                    SatChip.select(
                      label: z.name,
                      icon: z.icon,
                      dot: z.color,
                      count: tables.where((t) => t.zoneId == z.id).length,
                      selected: z.id == selectedId,
                      onTap: () => onSelect(z.id),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 14, 0),
            child: SatButton.primary(
              label: context.l10n.zoneAdminAddTable,
              icon: Icons.add,
              onTap: onAdd,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final int index;
  final VenueTable table;
  final VoidCallback onTap;
  const _TableRow({
    super.key,
    required this.index,
    required this.table,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final inactive = !table.active;
    final nameColor = inactive ? sc.textLo : sc.textHi;

    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.s2),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 10, 12, 10),
          decoration: SatBox.d(
            color: sc.bg2,
            border: SatB.all(color: sc.border1),
            borderRadius: SatR.a(14),
          ),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Sp.s1h),
                  child: Icon(
                    Icons.drag_indicator,
                    size: 22,
                    color: sc.textDim,
                  ),
                ),
              ),
              const SizedBox(width: Sp.s2h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      table.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SatType.labelL(color: nameColor),
                    ),
                    const SizedBox(height: Sp.sHair),
                    Text(
                      context.l10n.zonSeatsCount(table.capacity),
                      style: SatType.monoS(color: sc.textLo),
                    ),
                  ],
                ),
              ),
              if (inactive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Sp.s2h,
                    vertical: Sp.s1,
                  ),
                  decoration: SatBox.d(
                    color: sc.urgentSoft,
                    borderRadius: SatR.a(999),
                  ),
                  child: Text(
                    context.l10n.inactive,
                    style: SatType.labelS(color: sc.urgent),
                  ),
                ),
              const SizedBox(width: Sp.s1h),
              Icon(Icons.chevron_right, size: 20, color: sc.textDim),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragProxy extends StatelessWidget {
  final Widget child;
  const _DragProxy({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Transform.scale(scale: 1.02, child: child),
    );
  }
}

class _TableEditor extends ConsumerStatefulWidget {
  final VenueTable? table;
  final String zoneId;
  const _TableEditor({required this.table, required this.zoneId});

  @override
  ConsumerState<_TableEditor> createState() => _TableEditorState();
}

class _TableEditorState extends ConsumerState<_TableEditor> {
  late final TextEditingController _name;
  late int _capacity;
  late String _zoneId;
  late bool _active;

  bool get _isNew => widget.table == null;

  @override
  void initState() {
    super.initState();
    final t = widget.table;
    _name = TextEditingController(text: t?.label ?? '');
    _capacity = t?.capacity ?? 2;
    _zoneId = t?.zoneId ?? widget.zoneId;
    _active = t?.active ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final n = ref.read(tablesProvider.notifier);
    var label = _name.text.trim();
    if (label.isEmpty) {
      final existing = ref
          .read(tablesProvider)
          .where((t) => t.zoneId == _zoneId)
          .length;
      label = 'T${existing + 1}';
    }
    if (_isNew) {
      n.addTable(zoneId: _zoneId, label: label, capacity: _capacity);
    } else {
      n.configureTable(
        widget.table!.id,
        label: label,
        capacity: _capacity,
        zoneId: _zoneId,
        active: _active,
      );
    }
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await _confirm(
      context,
      context.l10n.zoneAdminDeleteTableConfirmTitle,
      '${widget.table!.displayName} ${context.l10n.zoneAdminDeleteTableConfirmSub}',
    );
    if (ok != true) return;
    ref.read(tablesProvider.notifier).removeTable(widget.table!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final zones = ref.watch(zonesProvider);

    return _SheetShell(
      title: _isNew
          ? context.l10n.zoneAdminNewTable
          : '${context.l10n.zoneAdminEditTable} ${widget.table!.displayName}',
      body: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        children: [
          _label(sc, context.l10n.zoneAdminTableName),
          const SizedBox(height: Sp.s2),
          SatField.text(
            controller: _name,
            hint: context.l10n.zoneAdminTableNameHint,
          ),
          const SizedBox(height: Sp.s5),
          _label(sc, context.l10n.zoneAdminMaxCapacity),
          const SizedBox(height: Sp.s2),
          SatStepper(
            value: _capacity,
            min: 1,
            max: 20,
            semanticLabel: context.l10n.zoneAdminMaxCapacity,
            onChanged: (v) => setState(() => _capacity = v),
          ),
          const SizedBox(height: Sp.s5),
          _label(sc, context.l10n.zoneAdminZonePill),
          const SizedBox(height: Sp.s2),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final z in zones)
                SatChip.select(
                  label: z.name,
                  icon: z.icon,
                  dot: z.color,
                  selected: z.id == _zoneId,
                  onTap: () => setState(() => _zoneId = z.id),
                ),
            ],
          ),
          if (!_isNew) ...[
            const SizedBox(height: Sp.s5),
            _ActiveRow(
              active: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
          ],
        ],
      ),
      footer: Row(
        children: [
          if (!_isNew) ...[
            SatButton.danger(label: context.l10n.delete, onTap: _delete),
            const SizedBox(width: Sp.s2h),
          ],
          Expanded(
            child: SatButton.primary(
              label: _isNew
                  ? context.l10n.zoneAdminAddTable
                  : context.l10n.save,
              onTap: _save,
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(SatColors sc, String text) =>
      Text(text.toUpperCase(), style: SatType.caption(color: sc.textLo));
}

class _ActiveRow extends StatelessWidget {
  final bool active;
  final ValueChanged<bool> onChanged;
  const _ActiveRow({required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return GestureDetector(
      onTap: () => onChanged(!active),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Sp.s4,
          vertical: Sp.s3h,
        ),
        decoration: SatBox.d(
          color: sc.bg2,
          border: SatB.all(color: sc.border1),
          borderRadius: SatR.a(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.zoneAdminTableActive,
                    style: SatType.labelM(color: sc.textHi),
                  ),
                  const SizedBox(height: Sp.sHair),
                  Text(
                    context.l10n.zoneAdminTableActiveSub,
                    style: SatType.bodyS(color: sc.textMd),
                  ),
                ],
              ),
            ),
            SatToggle(
              value: active,
              semanticLabel: context.l10n.zoneAdminTableActive,
              onChanged: (v) => onChanged(v),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZonesEditor extends ConsumerWidget {
  const _ZonesEditor();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final zones = ref.watch(zonesProvider);
    final tables = ref.watch(tablesProvider);
    final zonesN = ref.read(zonesProvider.notifier);
    final seats = tables.fold<int>(0, (s, t) => s + t.capacity);

    return _SheetShell(
      title: context.l10n.zoneAdminManageZones,
      subtitle: context.l10n.zoneAdminSummary(
        zones.length,
        tables.length,
        seats,
      ),
      body: zones.isEmpty
          ? Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Text(
                context.l10n.zoneAdminEmpty,
                style: SatType.bodyM(color: sc.textMd),
              ),
            )
          : ReorderableListView.builder(
              shrinkWrap: true,
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              itemCount: zones.length,
              onReorder: zonesN.reorder,
              itemBuilder: (ctx, i) {
                final z = zones[i];
                final count = tables.where((t) => t.zoneId == z.id).length;
                return _ZoneAdminRow(
                  key: ValueKey(z.id),
                  index: i,
                  zone: z,
                  tableCount: count,
                  onEdit: () => _present(
                    context,
                    _ZoneEditor(zone: z, tableCount: count),
                  ),
                  onDelete: () async {
                    if (count > 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.l10n.zoneAdminMoveTablesFirst(count),
                          ),
                        ),
                      );
                      return;
                    }
                    final ok = await _confirm(
                      context,
                      context.l10n.zoneAdminDeleteZoneTitle,
                      context.l10n.zoneAdminDeleteZoneBody(z.name),
                    );
                    if (ok == true) zonesN.remove(z.id);
                  },
                );
              },
            ),
      footer: SatButton.primary(
        label: context.l10n.zoneAdminAddZone,
        icon: Icons.add,
        onTap: () => _present(context, const _ZoneEditor()),
      ),
    );
  }
}

class _ZoneAdminRow extends StatelessWidget {
  final int index;
  final Zone zone;
  final int tableCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ZoneAdminRow({
    super.key,
    required this.index,
    required this.zone,
    required this.tableCount,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final locked = tableCount > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: Sp.s2),
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      decoration: SatBox.d(
        color: sc.bg2,
        border: SatB.all(color: sc.border1),
        borderRadius: SatR.a(14),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.s1h),
              child: Icon(Icons.drag_indicator, size: 20, color: sc.textDim),
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: SatBox.d(
              color: zone.color.withValues(alpha: 0.16),
              borderRadius: SatR.a(10),
            ),
            child: Icon(zone.icon, size: 20, color: zone.color),
          ),
          const SizedBox(width: Sp.s3),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onEdit,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(zone.name, style: SatType.labelM(color: sc.textHi)),
                  const SizedBox(height: Sp.sHair),
                  Text(
                    context.l10n.zonTablesCount(tableCount),
                    style: SatType.monoS(color: sc.textLo),
                  ),
                ],
              ),
            ),
          ),
          SatIconButton.outline(
            icon: Icons.tune,
            tooltip: context.l10n.a11yEdit,
            size: 36,
            onTap: onEdit,
          ),
          const SizedBox(width: Sp.s1),
          if (locked)
            SatIconButton.outline(
              icon: Icons.delete_outline,
              tooltip: context.l10n.delete,
              size: 36,
              onTap: null,
            )
          else
            SatIconButton.danger(
              icon: Icons.delete_outline,
              tooltip: context.l10n.delete,
              size: 36,
              onTap: onDelete,
            ),
        ],
      ),
    );
  }
}

class _ZoneEditor extends ConsumerStatefulWidget {
  final Zone? zone;
  final int tableCount;
  const _ZoneEditor({this.zone, this.tableCount = 0});

  @override
  ConsumerState<_ZoneEditor> createState() => _ZoneEditorState();
}

class _ZoneEditorState extends ConsumerState<_ZoneEditor> {
  late final TextEditingController _name;
  late Color _color;
  late IconData _icon;

  bool get _isNew => widget.zone == null;

  @override
  void initState() {
    super.initState();
    final z = widget.zone;
    _name = TextEditingController(text: z?.name ?? '');
    _color = z?.color ?? zoneColorPresets.first;
    _icon = z?.icon ?? zoneIconPresets.first;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final n = ref.read(zonesProvider.notifier);
    if (_isNew) {
      n.add(
        name,
        colorHex: _color.toARGB32(),
        iconKey: zoneIconKeyFromIcon(_icon),
      );
    } else {
      n.update(
        widget.zone!.id,
        name: name,
        colorHex: _color.toARGB32(),
        iconKey: zoneIconKeyFromIcon(_icon),
      );
    }
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (widget.tableCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.zoneAdminMoveTablesFirst(widget.tableCount),
          ),
        ),
      );
      return;
    }
    final ok = await _confirm(
      context,
      context.l10n.zoneAdminDeleteZoneTitle,
      context.l10n.zoneAdminDeleteZoneBody(widget.zone!.name),
    );
    if (ok != true) return;
    ref.read(zonesProvider.notifier).remove(widget.zone!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return _SheetShell(
      title: _isNew
          ? context.l10n.zoneAdminNewZone
          : context.l10n.zoneAdminEditZone(widget.zone!.name),
      body: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        children: [
          _ZonePreview(name: _name.text, color: _color, icon: _icon),
          const SizedBox(height: Sp.s5),
          _fieldLabel(sc, context.l10n.zoneAdminZoneName),
          const SizedBox(height: Sp.s2),
          SatField.text(
            controller: _name,
            hint: context.l10n.zoneAdminZoneNameHint,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Sp.s5),
          _fieldLabel(sc, context.l10n.zoneAdminColor),
          const SizedBox(height: Sp.s2h),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in zoneColorPresets)
                _ColorDot(
                  color: c,
                  selected: c.toARGB32() == _color.toARGB32(),
                  onTap: () => setState(() => _color = c),
                ),
            ],
          ),
          const SizedBox(height: Sp.s5),
          _fieldLabel(sc, context.l10n.zoneAdminIcon),
          const SizedBox(height: Sp.s2h),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final i in zoneIconPresets)
                _IconTile(
                  icon: i,
                  color: _color,
                  selected: i.codePoint == _icon.codePoint,
                  onTap: () => setState(() => _icon = i),
                ),
            ],
          ),
          if (!_isNew) ...[
            const SizedBox(height: Sp.s6),
            _MetaRow(tableCount: widget.tableCount),
          ],
        ],
      ),
      footer: Row(
        children: [
          if (!_isNew) ...[
            SatButton.danger(label: context.l10n.delete, onTap: _delete),
            const SizedBox(width: Sp.s2h),
          ],
          Expanded(
            child: SatButton.primary(
              label: _isNew ? context.l10n.zoneAdminAddZone : context.l10n.save,
              onTap: _save,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(SatColors sc, String text) =>
      Text(text.toUpperCase(), style: SatType.caption(color: sc.textLo));
}

class _ZonePreview extends StatelessWidget {
  final String name;
  final Color color;
  final IconData icon;
  const _ZonePreview({
    required this.name,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final shown = name.trim().isEmpty ? context.l10n.zoneAdminNewZone : name;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
      decoration: SatBox.d(
        color: color.withValues(alpha: 0.12),
        border: SatB.all(color: color.withValues(alpha: 0.45)),
        borderRadius: SatR.a(16),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: SatBox.d(
              color: color.withValues(alpha: 0.22),
              borderRadius: SatR.a(12),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: Sp.s3h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shown,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SatType.labelL(color: sc.textHi),
                ),
                const SizedBox(height: Sp.sHair),
                Text(
                  context.l10n.zoneAdminPreview,
                  style: SatType.monoS(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Semantics(
      button: true,
      selected: selected,
      label: context.l10n.a11yPickColor,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: satMotion(context, 130),
          width: 38,
          height: 38,
          decoration: SatBox.d(
            color: color.withValues(alpha: selected ? 0.95 : 0.2),
            border: SatB.all(
              color: selected ? color : sc.border1,
              width: selected ? 2 : 1,
            ),
            shape: BoxShape.circle,
          ),
          child: selected
              ? Icon(Icons.check, size: 18, color: sc.accentInk)
              : null,
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _IconTile({
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Semantics(
      button: true,
      selected: selected,
      label: context.l10n.zoneAdminIcon,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: satMotion(context, 130),
          width: 46,
          height: 46,
          decoration: SatBox.d(
            color: selected ? color.withValues(alpha: 0.18) : sc.bg2,
            border: SatB.all(
              color: selected ? color : sc.border1,
              width: selected ? 1.4 : 1,
            ),
            borderRadius: SatR.a(12),
          ),
          child: Icon(icon, size: 22, color: selected ? color : sc.textMd),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final int tableCount;
  const _MetaRow({required this.tableCount});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.s3h, vertical: Sp.s3),
      decoration: SatBox.d(
        color: sc.bg2,
        border: SatB.all(color: sc.border1),
        borderRadius: SatR.a(14),
      ),
      child: Row(
        children: [
          Icon(Icons.table_restaurant_outlined, size: 18, color: sc.textMd),
          const SizedBox(width: Sp.s2h),
          Expanded(
            child: Text(
              tableCount == 0
                  ? context.l10n.zoneAdminNoTablesHere
                  : context.l10n.zoneAdminTablesHere(tableCount),
              style: SatType.bodyM(color: sc.textMd),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final Widget footer;
  const _SheetShell({
    required this.title,
    this.subtitle,
    required this.body,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      decoration: SatBox.d(
        color: sc.bg1,
        border: SatB.all(color: sc.border1),
        borderRadius: SatR.a(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: Sp.s2h),
          Container(
            width: 38,
            height: 4,
            decoration: SatBox.d(color: sc.border2, borderRadius: SatR.a(999)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: SatType.h3(color: sc.textHi)),
                      if (subtitle != null) ...[
                        const SizedBox(height: Sp.sHair),
                        Text(
                          subtitle!.toUpperCase(),
                          style: SatType.monoS(color: sc.textLo),
                        ),
                      ],
                    ],
                  ),
                ),
                SatIconButton.outline(
                  icon: Icons.close,
                  tooltip: context.l10n.close,
                  size: 36,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Flexible(child: body),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: SatBox.d(
              border: Border(top: SatB.side(color: sc.border0)),
            ),
            child: SafeArea(top: false, child: footer),
          ),
        ],
      ),
    );
  }
}

Future<void> _present(BuildContext context, Widget child) {
  return showSatSheet(
    context,
    bare: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
        left: Sp.s2,
        right: Sp.s2,
        top: 60,
      ),
      child: child,
    ),
  );
}

Widget _sheetHandle(SatColors sc) => Container(
  width: 40,
  height: 4,
  decoration: SatBox.d(color: sc.border1, borderRadius: SatR.a(2)),
);

Future<bool?> _confirm(BuildContext context, String title, String message) {
  return showSatSheet<bool>(
    context,
    builder: (ctx) {
      final sc = ctx.sat;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: _sheetHandle(sc)),
              const SizedBox(height: Sp.s4h),
              Text(title, style: SatType.labelL(color: sc.textHi)),
              const SizedBox(height: Sp.s2),
              Text(message, style: SatType.bodyM(color: sc.textMd)),
              const SizedBox(height: Sp.s4h),
              Row(
                children: [
                  Expanded(
                    child: SatButton.outline(
                      label: context.l10n.cancel,
                      onTap: () => Navigator.of(ctx).pop(false),
                    ),
                  ),
                  const SizedBox(width: Sp.s2h),
                  Expanded(
                    child: SatButton.danger(
                      label: context.l10n.delete,
                      onTap: () => Navigator.of(ctx).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
