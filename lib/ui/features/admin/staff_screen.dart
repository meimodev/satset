import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/data/repositories/roles_repository.dart';
import 'package:satset/data/repositories/staff_repository.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/role.dart';
import 'package:satset/domain/models/user.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/role_visuals.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import '_common.dart';

enum _Tab { people, roles, permissions }

class StaffScreen extends ConsumerStatefulWidget {
  const StaffScreen({super.key});

  @override
  ConsumerState<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends ConsumerState<StaffScreen> {
  _Tab _tab = _Tab.people;
  String _query = '';
  String? _roleFilter; // null = All
  bool _onDutyOnly = false;

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(staffRepositoryProvider);
    final roles = ref.watch(rolesRepositoryProvider);
    final onDuty = users.where((u) => u.onDuty && !u.disabled).length;
    final approvers = users
        .where((u) => !u.disabled && _isAdmin(u, roles))
        .length;

    if (!context.layout.useTabletShell) {
      return _phoneLayout(users, roles);
    }

    return AdminPage(
      title: 'Staff & accounts',
      sub: '${users.length} members · $onDuty on-duty · $approvers admins',
      topTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tabBtn('People', _Tab.people),
          const SizedBox(width: 6),
          _tabBtn('Roles', _Tab.roles),
          const SizedBox(width: 6),
          _tabBtn('Permissions', _Tab.permissions),
        ],
      ),
      children: [
        switch (_tab) {
          _Tab.people => _peopleTab(users, roles),
          _Tab.roles => _rolesTab(users, roles),
          _Tab.permissions => _permissionsTab(roles),
        },
      ],
    );
  }

  // ── Phone fallback ──────────────────────────────────────────
  Widget _phoneLayout(List<AppUser> users, List<Role> roles) {
    final sc = context.sat;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
        children: [
          for (final u in users)
            GestureDetector(
              onTap: () => _openDetail(u),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: sc.bg2,
                  border: Border.all(color: sc.border0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _Avatar(user: u, role: _roleOf(u, roles), size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.name,
                              style: SatType.sans(
                                  size: 14,
                                  weight: FontWeight.w500,
                                  color: sc.textHi)),
                          const SizedBox(height: 2),
                          Text(_roleOf(u, roles)?.name ?? '—',
                              style: SatType.mono(
                                  size: 10,
                                  color: sc.textLo,
                                  letterSpacing: 0.4)),
                        ],
                      ),
                    ),
                    if (u.onDuty)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: sc.success, shape: BoxShape.circle),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── People tab ──────────────────────────────────────────────
  Widget _peopleTab(List<AppUser> users, List<Role> roles) {
    final sc = context.sat;
    final filtered = users.where((u) {
      if (_onDutyOnly && (!u.onDuty || u.disabled)) return false;
      if (_roleFilter != null && u.roleId != _roleFilter) return false;
      if (_query.isNotEmpty &&
          !u.name.toLowerCase().contains(_query.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: sc.bg2,
                  border: Border.all(color: sc.border0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 16, color: sc.textLo),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        style: SatType.sans(size: 13, color: sc.textHi),
                        decoration: InputDecoration.collapsed(
                          hintText: 'Search by name',
                          hintStyle:
                              SatType.sans(size: 13, color: sc.textLo),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
                onTap: () => _addStaff(roles),
                child: adminPill(context, '+ Add staff', on: true)),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _filterChip('All', _roleFilter == null && !_onDutyOnly, () {
                setState(() {
                  _roleFilter = null;
                  _onDutyOnly = false;
                });
              }),
              const SizedBox(width: 8),
              _filterChip('On-duty', _onDutyOnly, () {
                setState(() => _onDutyOnly = !_onDutyOnly);
              }),
              for (final r in roles) ...[
                const SizedBox(width: 8),
                _filterChip(r.name, _roleFilter == r.id, () {
                  setState(() =>
                      _roleFilter = _roleFilter == r.id ? null : r.id);
                }, color: r.color),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: sc.bg2,
              border: Border.all(color: sc.border0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text('No staff match these filters',
                style: SatType.sans(size: 13, color: sc.textLo)),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisExtent: 168,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) =>
                _StaffCard(user: filtered[i], role: _roleOf(filtered[i], roles), onTap: () => _openDetail(filtered[i])),
          ),
      ],
    );
  }

  // ── Roles tab ───────────────────────────────────────────────
  Widget _rolesTab(List<AppUser> users, List<Role> roles) {
    final sc = context.sat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('${roles.length} custom roles',
                style: SatType.sans(
                    size: 13, weight: FontWeight.w500, color: sc.textMd)),
            const Spacer(),
            GestureDetector(
              onTap: _createRole,
              child: adminPill(context, '+ New role', on: true),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: sc.bg2,
            border: Border.all(color: sc.border0),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              for (var i = 0; i < roles.length; i++)
                _roleRow(roles[i], users, last: i == roles.length - 1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _roleRow(Role r, List<AppUser> users, {bool last = false}) {
    final sc = context.sat;
    final memberCount =
        users.where((u) => u.roleId == r.id && !u.disabled).length;
    final isAdminRole = r.has(Capability.manageStaff);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: last ? BorderSide.none : BorderSide(color: sc.border0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: r.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Text(r.name,
                style: SatType.sans(
                    size: 14,
                    weight: FontWeight.w600,
                    color: sc.textHi)),
          ),
          Expanded(
            flex: 3,
            child: Text(
                '${r.capabilities.length}/${Capability.values.length} capabilities',
                style: SatType.mono(
                    size: 11, color: sc.textMd, letterSpacing: 0.4)),
          ),
          Expanded(
            flex: 3,
            child: Text('$memberCount members',
                style: SatType.mono(
                    size: 11, color: sc.textMd, letterSpacing: 0.4)),
          ),
          if (isAdminRole) _tagBadge(context, 'ADMIN', sc.violet, sc.violetSoft),
          const SizedBox(width: 8),
          GestureDetector(
              onTap: () => _renameRole(r),
              child: adminPill(context, 'Rename')),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: memberCount == 0 ? () => _deleteRole(r) : null,
            child: Opacity(
              opacity: memberCount == 0 ? 1 : 0.4,
              child: adminPill(context, 'Delete', danger: true),
            ),
          ),
        ],
      ),
    );
  }

  // ── Permissions tab ─────────────────────────────────────────
  Widget _permissionsTab(List<Role> roles) {
    final sc = context.sat;
    final caps = Capability.values;
    final grouped = <CapabilityGroup, List<Capability>>{};
    for (final c in caps) {
      grouped.putIfAbsent(c.group, () => []).add(c);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Role × capability matrix',
              style: SatType.sans(
                  size: 15,
                  weight: FontWeight.w600,
                  color: sc.textHi)),
          const SizedBox(height: 4),
          Text('Tap a cell to toggle. Last admin guard prevents removing the final “Manage staff” holder.',
              style: SatType.sans(size: 11, color: sc.textLo)),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    SizedBox(width: 160, child: _h('Role')),
                    for (final g in CapabilityGroup.values) ...[
                      for (final c in grouped[g]!)
                        SizedBox(width: 110, child: _h(c.label)),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                for (final r in roles)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(color: sc.border0)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 160,
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                    color: r.color,
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(r.name,
                                    style: SatType.sans(
                                        size: 13,
                                        weight: FontWeight.w500,
                                        color: sc.textHi)),
                              ),
                            ],
                          ),
                        ),
                        for (final g in CapabilityGroup.values) ...[
                          for (final c in grouped[g]!)
                            SizedBox(
                              width: 110,
                              child: _capCell(r, c),
                            ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _capCell(Role r, Capability c) {
    final sc = context.sat;
    final on = r.has(c);
    return GestureDetector(
      onTap: () => _toggleCap(r, c, !on),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        height: 26,
        decoration: BoxDecoration(
          color: on ? sc.successSoft : sc.bg3,
          border: Border.all(color: on ? sc.success : sc.border1),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(on ? '✓' : '—',
            style: SatType.mono(
              size: 12,
              weight: FontWeight.w700,
              color: on ? sc.success : sc.textDim,
            )),
      ),
    );
  }

  void _toggleCap(Role r, Capability c, bool on) {
    // Guard: removing last manageStaff holder
    if (!on && c == Capability.manageStaff) {
      final holders = ref
          .read(rolesRepositoryProvider.notifier)
          .capabilityHolders(Capability.manageStaff);
      if (holders <= 1) {
        _toast('Cannot remove the last role with “Manage staff”');
        return;
      }
    }
    ref.read(rolesRepositoryProvider.notifier).setCapability(r.id, c, on);
  }

  // ── Detail drawer ───────────────────────────────────────────
  void _openDetail(AppUser u) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: FractionallySizedBox(
          heightFactor: 0.92,
          child: _StaffDetailDrawer(userId: u.id),
        ),
      ),
    );
  }

  // ── Actions ─────────────────────────────────────────────────
  Future<void> _addStaff(List<Role> roles) async {
    if (roles.isEmpty) {
      _toast('Create a role first');
      return;
    }
    final res = await showModalBottomSheet<_NewStaff>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.sat.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _NewStaffDialog(roles: roles),
    );
    if (res == null) return;
    try {
      final created = ref.read(staffRepositoryProvider.notifier).create(
            name: res.name,
            initials: res.initials,
            roleId: res.roleId,
            legacyRole: res.legacyRole,
          );
      _toast('Created ${created.name}. PIN: ${created.pin}');
    } on StaffException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _createRole() async {
    final name = await _prompt('New role name', '');
    if (name == null || name.trim().isEmpty) return;
    ref.read(rolesRepositoryProvider.notifier).create(name.trim());
  }

  Future<void> _renameRole(Role r) async {
    final name = await _prompt('Rename role', r.name);
    if (name == null || name.trim().isEmpty) return;
    ref.read(rolesRepositoryProvider.notifier).rename(r.id, name.trim());
  }

  Future<void> _deleteRole(Role r) async {
    final ok = await _confirm('Delete role “${r.name}”?',
        'Capabilities assigned to this role will be lost.');
    if (ok != true) return;
    if (r.has(Capability.manageStaff)) {
      final holders = ref
          .read(rolesRepositoryProvider.notifier)
          .capabilityHolders(Capability.manageStaff);
      if (holders <= 1) {
        _toast('Cannot delete the last admin role');
        return;
      }
    }
    ref.read(rolesRepositoryProvider.notifier).delete(r.id);
  }

  // ── Helpers ─────────────────────────────────────────────────
  bool _isAdmin(AppUser u, List<Role> roles) {
    if (u.disabled || u.roleId == null) return false;
    for (final r in roles) {
      if (r.id == u.roleId) return r.has(Capability.manageStaff);
    }
    return false;
  }

  Role? _roleOf(AppUser u, List<Role> roles) {
    for (final r in roles) {
      if (r.id == u.roleId) return r;
    }
    return null;
  }

  Widget _tabBtn(String label, _Tab t) {
    return GestureDetector(
      onTap: () => setState(() => _tab = t),
      child: adminPill(context, label, on: _tab == t),
    );
  }

  Widget _filterChip(String label, bool on, VoidCallback onTap,
      {Color? color}) {
    final sc = context.sat;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? sc.accentSoft : sc.bg3,
          border:
              Border.all(color: on ? sc.accentBorder : sc.border1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: SatType.sans(
                    size: 11,
                    weight: FontWeight.w500,
                    color: on ? sc.accent : sc.textMd)),
          ],
        ),
      ),
    );
  }

  Widget _h(String t) {
    final sc = context.sat;
    return Text(t.toUpperCase(),
        style: SatType.mono(
            size: 10,
            weight: FontWeight.w600,
            letterSpacing: 1.0,
            color: sc.textLo));
  }

  Widget _tagBadge(BuildContext context, String t, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
      child: Text(t,
          style: SatType.mono(
              size: 9,
              weight: FontWeight.w600,
              letterSpacing: 0.8,
              color: fg)),
    );
  }

  Future<bool?> _confirm(String title, String body) =>
      _confirmSheet(context, title, body);

  Future<String?> _prompt(String title, String initial) {
    final ctl = TextEditingController(text: initial);
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.sat.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final sc = ctx.sat;
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: _sheetHandle(sc)),
                  const SizedBox(height: 18),
                  Text(title,
                      style: SatType.sans(
                          size: 16,
                          weight: FontWeight.w600,
                          color: sc.textHi)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: ctl,
                    autofocus: true,
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel')),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                            onPressed: () => Navigator.pop(ctx, ctl.text),
                            child: const Text('Save')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bottom-sheet helpers
// ─────────────────────────────────────────────────────────────
Widget _sheetHandle(SatColors sc) => Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: sc.border1,
        borderRadius: BorderRadius.circular(2),
      ),
    );

Future<bool?> _confirmSheet(
  BuildContext context,
  String title,
  String body, {
  String confirmLabel = 'Confirm',
  bool danger = false,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: context.sat.bg1,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
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
              const SizedBox(height: 18),
              Text(title,
                  style: SatType.sans(
                      size: 16, weight: FontWeight.w600, color: sc.textHi)),
              const SizedBox(height: 8),
              Text(body,
                  style:
                      SatType.sans(size: 13, color: sc.textMd, height: 1.4)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: danger
                          ? FilledButton.styleFrom(backgroundColor: sc.urgent)
                          : null,
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(confirmLabel),
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

// ─────────────────────────────────────────────────────────────
// Staff card
// ─────────────────────────────────────────────────────────────
class _StaffCard extends StatelessWidget {
  final AppUser user;
  final Role? role;
  final VoidCallback onTap;
  const _StaffCard(
      {required this.user, required this.role, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final disabled = user.disabled;
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: sc.bg2,
            border: Border.all(color: sc.border0),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Avatar(user: user, role: role, size: 44),
                  const Spacer(),
                  if (user.onDuty && !disabled)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: sc.success, shape: BoxShape.circle),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SatType.sans(
                      size: 15,
                      weight: FontWeight.w600,
                      color: sc.textHi)),
              const SizedBox(height: 4),
              if (role != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: role!.color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(5)),
                  child: Text(role!.name.toUpperCase(),
                      style: SatType.mono(
                          size: 9,
                          weight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: role!.color)),
                )
              else
                Text('No role',
                    style: SatType.mono(
                        size: 10,
                        color: sc.textLo,
                        letterSpacing: 0.4)),
              const Spacer(),
              Text('PIN ${user.pin}',
                  style: SatType.mono(
                      size: 11, color: sc.textLo, letterSpacing: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final AppUser user;
  final Role? role;
  final double size;
  const _Avatar({required this.user, required this.role, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final base = role?.color ?? const Color(0xFF6DB5FF);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, Color.alphaBlend(Colors.black.withValues(alpha: 0.32), base)],
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(user.initials,
          style: SatType.mono(
              size: size * 0.32,
              weight: FontWeight.w600,
              color: Colors.white)),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// New staff dialog
// ─────────────────────────────────────────────────────────────
class _NewStaff {
  final String name;
  final String initials;
  final String roleId;
  final UserRole legacyRole;
  _NewStaff(this.name, this.initials, this.roleId, this.legacyRole);
}

class _NewStaffDialog extends StatefulWidget {
  final List<Role> roles;
  const _NewStaffDialog({required this.roles});

  @override
  State<_NewStaffDialog> createState() => _NewStaffDialogState();
}

class _NewStaffDialogState extends State<_NewStaffDialog> {
  final _nameCtl = TextEditingController();
  String? _roleId;

  @override
  void initState() {
    super.initState();
    _roleId = widget.roles.first.id;
  }

  void _submit() {
    final name = _nameCtl.text.trim();
    if (name.isEmpty || _roleId == null) return;
    final initials = name
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();
    // Pick legacy role best-fit by name keyword
    final rname =
        widget.roles.firstWhere((r) => r.id == _roleId).name.toLowerCase();
    final legacy = rname.contains('kitchen') || rname.contains('dapur')
        ? UserRole.kitchen
        : (rname.contains('admin') || rname.contains('manager'))
            ? UserRole.admin
            : UserRole.waiter;
    Navigator.pop(context, _NewStaff(name, initials, _roleId!, legacy));
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: _sheetHandle(sc)),
              const SizedBox(height: 18),
              Text('Add staff',
                  style: SatType.sans(
                      size: 16, weight: FontWeight.w600, color: sc.textHi)),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtl,
                autofocus: true,
                decoration: const InputDecoration(
                    labelText: 'Full name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _roleId,
                items: [
                  for (final r in widget.roles)
                    DropdownMenuItem(value: r.id, child: Text(r.name)),
                ],
                onChanged: (v) => setState(() => _roleId = v),
                decoration: const InputDecoration(
                    labelText: 'Role', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                        onPressed: _submit, child: const Text('Add')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Slide-over detail drawer
// ─────────────────────────────────────────────────────────────
class _StaffDetailDrawer extends ConsumerStatefulWidget {
  final String userId;
  const _StaffDetailDrawer({required this.userId});

  @override
  ConsumerState<_StaffDetailDrawer> createState() => _StaffDetailDrawerState();
}

class _StaffDetailDrawerState extends ConsumerState<_StaffDetailDrawer> {
  late TextEditingController _nameCtl;
  late TextEditingController _pinCtl;

  @override
  void initState() {
    super.initState();
    final u =
        ref.read(staffRepositoryProvider.notifier).byId(widget.userId);
    _nameCtl = TextEditingController(text: u?.name ?? '');
    _pinCtl = TextEditingController(text: u?.pin ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(staffRepositoryProvider);
    final roles = ref.watch(rolesRepositoryProvider);
    AppUser? maybeUser;
    for (final u in users) {
      if (u.id == widget.userId) {
        maybeUser = u;
        break;
      }
    }
    if (maybeUser == null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => Navigator.of(context).maybePop());
      return const SizedBox.shrink();
    }
    final AppUser user = maybeUser;
    final sc = context.sat;
    return Material(
      color: sc.bg1,
      clipBehavior: Clip.antiAlias,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SizedBox(
        height: double.infinity,
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(child: _sheetHandle(sc)),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
                child: Row(
                  children: [
                    _Avatar(
                        user: user,
                        role: _findRole(roles, user.roleId),
                        size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name,
                              style: SatType.sans(
                                  size: 18,
                                  weight: FontWeight.w600,
                                  color: sc.textHi)),
                          const SizedBox(height: 2),
                          Text(user.disabled ? 'Disabled' : (user.onDuty ? 'On duty' : 'Off duty'),
                              style: SatType.mono(
                                  size: 11,
                                  color: user.disabled ? sc.urgent : sc.textLo,
                                  letterSpacing: 0.4)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  children: [
                    _label('Name'),
                    TextField(
                      controller: _nameCtl,
                      decoration:
                          const InputDecoration(border: OutlineInputBorder()),
                      onSubmitted: (_) => _saveName(user),
                    ),
                    const SizedBox(height: 16),
                    _label('Role'),
                    DropdownButtonFormField<String>(
                      initialValue: user.roleId,
                      items: [
                        for (final r in roles)
                          DropdownMenuItem(value: r.id, child: Text(r.name)),
                      ],
                      onChanged: (v) => _changeRole(user, v),
                      decoration:
                          const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    _label('PIN (6 digits, unique)'),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _pinCtl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            decoration: const InputDecoration(
                                border: OutlineInputBorder()),
                            onSubmitted: (_) => _savePin(user),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                            onPressed: () => _resetPin(user),
                            child: const Text('Reset')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text('On duty',
                              style: SatType.sans(size: 13, color: sc.textHi)),
                        ),
                        Switch(
                          value: user.onDuty,
                          onChanged: user.disabled
                              ? null
                              : (_) => ref
                                  .read(staffRepositoryProvider.notifier)
                                  .toggleOnDuty(user.id),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(user.disabled ? 'Disabled' : 'Active',
                              style:
                                  SatType.sans(size: 13, color: sc.textHi)),
                        ),
                        Switch(
                          value: !user.disabled,
                          onChanged: (v) => _setDisabled(user, !v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: sc.border0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _deleteUser(user),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: sc.urgent),
                        child: const Text('Delete'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          _saveName(user);
                          _savePin(user);
                        },
                        child: const Text('Save changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(t.toUpperCase(),
          style: SatType.mono(
              size: 10,
              weight: FontWeight.w600,
              letterSpacing: 1,
              color: sc.textLo)),
    );
  }

  void _saveName(AppUser u) {
    final name = _nameCtl.text.trim();
    if (name.isEmpty || name == u.name) return;
    final initials = name
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();
    ref.read(staffRepositoryProvider.notifier).rename(u.id, name, initials);
  }

  Future<void> _changeRole(AppUser u, String? newId) async {
    if (newId == null || newId == u.roleId) return;
    final ok = await _confirmSheet(
      context,
      'Change role?',
      'Reassign ${u.name} to a different role. Permissions will update immediately.',
    );
    if (ok != true) return;
    try {
      ref.read(staffRepositoryProvider.notifier).assignRole(u.id, newId);
    } on StaffException catch (e) {
      _toast(e.message);
    }
  }

  void _savePin(AppUser u) {
    if (_pinCtl.text == u.pin) return;
    try {
      ref.read(staffRepositoryProvider.notifier).setPin(u.id, _pinCtl.text);
    } on StaffException catch (e) {
      _toast(e.message);
      _pinCtl.text = u.pin;
    }
  }

  void _resetPin(AppUser u) {
    final pin = ref.read(staffRepositoryProvider.notifier).resetPin(u.id);
    _pinCtl.text = pin;
    _toast('New PIN: $pin');
  }

  Future<void> _setDisabled(AppUser u, bool disabled) async {
    if (disabled) {
      final ok = await _confirmSheet(
        context,
        'Disable ${u.name}?',
        'User can no longer sign in. You can re-enable later.',
        confirmLabel: 'Disable',
        danger: true,
      );
      if (ok != true) return;
    }
    try {
      ref
          .read(staffRepositoryProvider.notifier)
          .setDisabled(u.id, disabled);
    } on StaffException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _deleteUser(AppUser u) async {
    final ok = await _confirmSheet(
      context,
      'Delete ${u.name}?',
      'This permanently removes the account. Past audit entries remain.',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (ok != true) return;
    try {
      ref.read(staffRepositoryProvider.notifier).delete(u.id);
      if (mounted) Navigator.pop(context);
    } on StaffException catch (e) {
      _toast(e.message);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }
}

Role? _findRole(List<Role> roles, String? id) {
  if (id == null) return null;
  for (final r in roles) {
    if (r.id == id) return r;
  }
  return null;
}
