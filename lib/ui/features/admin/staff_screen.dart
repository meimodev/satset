import 'package:flutter/material.dart';
import 'package:satset/ui/core/widgets/sat_card.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_toggle.dart';
import 'package:satset/ui/core/widgets/sat_dropdown.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/ui/core/design/skin.dart';
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
import 'package:satset/ui/core/widgets/staff_avatar.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';

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

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(staffRepositoryProvider);
    final roles = ref.watch(rolesRepositoryProvider);
    final approvers = users
        .where((u) => !u.disabled && _isAdmin(u, roles))
        .length;

    if (!context.layout.useTabletShell) {
      return _phoneLayout(users, roles);
    }

    return AdminPage(
      title: AppStrings.staffTitle,
      sub: AppStrings.staffSubtitle(users.length, approvers),
      topTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tabChip(AppStrings.staffTabPeople, _Tab.people),
          const SizedBox(width: Sp.s1h),
          _tabChip(AppStrings.staffTabRoles, _Tab.roles),
          const SizedBox(width: Sp.s1h),
          _tabChip(AppStrings.staffTabPermissions, _Tab.permissions),
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
                margin: const EdgeInsets.only(bottom: Sp.s2),
                padding: const EdgeInsets.all(Sp.s3h),
                decoration: SatBox.d(
                  color: sc.bg2,
                  border: SatB.all(color: sc.border0),
                  borderRadius: SatR.a(14),
                ),
                child: Row(
                  children: [
                    StaffAvatar(
                      actor: u,
                      fallbackColor: _roleOf(u, roles)?.color,
                      size: 36,
                    ),
                    const SizedBox(width: Sp.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.name, style: SatType.bodyM(color: sc.textHi)),
                          const SizedBox(height: Sp.sHair),
                          Text(
                            _roleOf(u, roles)?.name ?? '—',
                            style: SatType.monoS(color: sc.textLo),
                          ),
                        ],
                      ),
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
              child: SatField.search(
                hint: AppStrings.staffSearchHint,
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(width: Sp.s2h),
            SatButton.primary(
              label: AppStrings.staffAddPill,
              size: SatButtonSize.sm,
              onTap: () => _addStaff(roles),
            ),
          ],
        ),
        const SizedBox(height: Sp.s3),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _filterChip(AppStrings.staffFilterAll, _roleFilter == null, () {
                setState(() => _roleFilter = null);
              }),
              for (final r in roles) ...[
                const SizedBox(width: Sp.s2),
                _filterChip(r.name, _roleFilter == r.id, () {
                  setState(
                    () => _roleFilter = _roleFilter == r.id ? null : r.id,
                  );
                }, color: r.color),
              ],
            ],
          ),
        ),
        const SizedBox(height: Sp.s4h),
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(Sp.s6),
            alignment: Alignment.center,
            decoration: SatBox.d(
              color: sc.bg2,
              border: SatB.all(color: sc.border0),
              borderRadius: SatR.a(14),
            ),
            child: Text(
              AppStrings.staffEmpty,
              style: SatType.bodyM(color: sc.textLo),
            ),
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
            itemBuilder: (ctx, i) => _StaffCard(
              user: filtered[i],
              role: _roleOf(filtered[i], roles),
              onTap: () => _openDetail(filtered[i]),
            ),
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
            Text(
              AppStrings.staffRolesCount(roles.length),
              style: SatType.bodyM(color: sc.textMd),
            ),
            const Spacer(),
            SatButton.primary(
              label: AppStrings.staffNewRolePill,
              size: SatButtonSize.sm,
              onTap: _createRole,
            ),
          ],
        ),
        const SizedBox(height: Sp.s3h),
        Container(
          decoration: SatBox.d(
            color: sc.bg2,
            border: SatB.all(color: sc.border0),
            borderRadius: SatR.a(14),
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
    final memberCount = users
        .where((u) => u.roleId == r.id && !u.disabled)
        .length;
    final isAdminRole = r.has(Capability.manageStaff);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: SatBox.d(
        border: Border(
          bottom: last ? BorderSide.none : SatB.side(color: sc.border0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: SatBox.d(color: r.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: Sp.s3),
          Expanded(
            flex: 5,
            child: Text(r.name, style: SatType.labelM(color: sc.textHi)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              AppStrings.staffCapsCount(
                r.capabilities.length,
                Capability.values.length,
              ),
              style: SatType.monoS(color: sc.textMd),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              AppStrings.staffMembersCount(memberCount),
              style: SatType.monoS(color: sc.textMd),
            ),
          ),
          if (isAdminRole)
            _tagBadge(
              context,
              AppStrings.staffRoleBadgeAdmin,
              sc.violet,
              sc.violetSoft,
            ),
          const SizedBox(width: Sp.s2),
          SatButton.outline(
            label: AppStrings.staffColor,
            size: SatButtonSize.sm,
            onTap: () => _pickRoleColor(r),
          ),
          const SizedBox(width: Sp.s1h),
          SatButton.outline(
            label: AppStrings.a11yRename,
            size: SatButtonSize.sm,
            onTap: () => _renameRole(r),
          ),
          const SizedBox(width: Sp.s1h),
          SatButton.danger(
            label: AppStrings.delete,
            size: SatButtonSize.sm,
            onTap: memberCount == 0 ? () => _deleteRole(r) : null,
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
      padding: const EdgeInsets.all(Sp.s5),
      decoration: SatBox.d(
        color: sc.bg2,
        border: SatB.all(color: sc.border0),
        borderRadius: SatR.a(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.staffMatrixTitle,
            style: SatType.labelL(color: sc.textHi),
          ),
          const SizedBox(height: Sp.s1),
          Text(
            AppStrings.staffMatrixHint,
            style: SatType.bodyS(color: sc.textLo),
          ),
          const SizedBox(height: Sp.s4h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    SizedBox(width: 160, child: _h(AppStrings.staffRole)),
                    for (final g in CapabilityGroup.values) ...[
                      for (final c in grouped[g]!)
                        SizedBox(width: 110, child: _h(c.label)),
                    ],
                  ],
                ),
                const SizedBox(height: Sp.s2),
                for (final r in roles)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: Sp.s2),
                    decoration: SatBox.d(
                      border: Border(top: SatB.side(color: sc.border0)),
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
                                decoration: SatBox.d(
                                  color: r.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: Sp.s2),
                              Expanded(
                                child: Text(
                                  r.name,
                                  style: SatType.bodyM(color: sc.textHi),
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (final g in CapabilityGroup.values) ...[
                          for (final c in grouped[g]!)
                            SizedBox(width: 110, child: _capCell(r, c)),
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
        margin: const EdgeInsets.symmetric(horizontal: Sp.s1),
        height: 26,
        decoration: SatBox.d(
          color: on ? sc.successSoft : sc.bg3,
          border: SatB.all(color: on ? sc.success : sc.border1),
          borderRadius: SatR.a(6),
        ),
        alignment: Alignment.center,
        child: Text(
          on ? '✓' : '—',
          style: SatType.monoM(color: on ? sc.success : sc.textDim),
        ),
      ),
    );
  }

  void _toggleCap(Role r, Capability c, bool on) {
    // Admin is Firebase-only: a local admin can't newly grant manageStaff to a
    // role (it would mint an admin-level role as a backdoor). Roles that
    // already hold it keep it. Server enforces the same. See ADR-0017.
    if (on && c == Capability.manageStaff && !r.has(Capability.manageStaff)) {
      _toast(AppStrings.staffErrAdminBySuperOnly);
      return;
    }
    // Guard: removing last manageStaff holder
    if (!on && c == Capability.manageStaff) {
      final holders = ref
          .read(rolesRepositoryProvider.notifier)
          .capabilityHolders(Capability.manageStaff);
      if (holders <= 1) {
        _toast(AppStrings.staffErrLastManageStaff);
        return;
      }
    }
    ref.read(rolesRepositoryProvider.notifier).setCapability(r.id, c, on);
  }

  // ── Detail drawer ───────────────────────────────────────────
  void _openDetail(AppUser u) {
    showSatSheet<void>(
      context,
      bare: true,
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
    final selectable = [
      for (final r in roles)
        if (!r.has(Capability.manageStaff)) r,
    ];
    if (selectable.isEmpty) {
      _toast(AppStrings.staffErrNeedNonAdminRole);
      return;
    }
    final users = ref.read(staffRepositoryProvider);
    final takenColors = <int>{
      for (final u in users)
        if (u.avatarColorHex != null) u.avatarColorHex!,
    };
    final res = await showSatSheet<_NewStaff>(
      context,
      builder: (_) =>
          _NewStaffDialog(roles: selectable, takenColors: takenColors),
    );
    if (res == null) return;
    if (takenColors.contains(res.avatarColorHex)) {
      _toast(AppStrings.staffErrColorTaken);
    }
    try {
      final created = ref
          .read(staffRepositoryProvider.notifier)
          .create(
            name: res.name,
            initials: res.initials,
            roleId: res.roleId,
            legacyRole: res.legacyRole,
            avatarColorHex: res.avatarColorHex,
          );
      _toast(AppStrings.staffCreated(created.name, created.pin));
    } on StaffException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _createRole() async {
    final name = await _prompt(AppStrings.staffNewRoleName, '');
    if (name == null || name.trim().isEmpty) return;
    ref.read(rolesRepositoryProvider.notifier).create(name.trim());
  }

  Future<void> _pickRoleColor(Role r) async {
    const swatches = <int>[
      0xFFC08AFF,
      0xFF6DB5FF,
      0xFF4DD487,
      0xFFFF9233,
      0xFFFFC04D,
      0xFFFF5C5C,
      0xFF7ED6C4,
      0xFFE48BB7,
    ];
    final picked = await showSatSheet<int>(
      context,
      builder: (ctx) {
        final sc = ctx.sat;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: _sheetHandle(sc)),
                const SizedBox(height: Sp.s4h),
                Text(
                  AppStrings.staffRoleColor,
                  style: SatType.labelL(color: sc.textHi),
                ),
                const SizedBox(height: Sp.s4),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    for (final c in swatches)
                      Semantics(
                        button: true,
                        selected: c == r.colorHex,
                        label: AppStrings.staffColor,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx, c),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: SatBox.d(
                              color: Color(c),
                              shape: BoxShape.circle,
                              border: SatB.all(
                                color: c == r.colorHex ? sc.textHi : sc.border1,
                                width: c == r.colorHex ? 3 : 1,
                              ),
                            ),
                          ),
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
    if (picked == null || picked == r.colorHex) return;
    ref.read(rolesRepositoryProvider.notifier).setColor(r.id, picked);
  }

  Future<void> _renameRole(Role r) async {
    final name = await _prompt(AppStrings.staffRenameRole, r.name);
    if (name == null || name.trim().isEmpty) return;
    ref.read(rolesRepositoryProvider.notifier).rename(r.id, name.trim());
  }

  Future<void> _deleteRole(Role r) async {
    final ok = await _confirm(
      AppStrings.staffDeleteRoleTitle(r.name),
      AppStrings.staffDeleteRoleBody,
    );
    if (ok != true) return;
    if (r.has(Capability.manageStaff)) {
      final holders = ref
          .read(rolesRepositoryProvider.notifier)
          .capabilityHolders(Capability.manageStaff);
      if (holders <= 1) {
        _toast(AppStrings.staffErrLastAdminRole);
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

  /// Three tabs that all fit on one line — a chip row shows every choice at
  /// once, where SatTabs would give the same three a heavier frame.
  Widget _tabChip(String label, _Tab t) {
    return SatChip.select(
      label: label,
      selected: _tab == t,
      size: SatChipSize.sm,
      onTap: () => setState(() => _tab = t),
    );
  }

  Widget _filterChip(
    String label,
    bool on,
    VoidCallback onTap, {
    Color? color,
  }) {
    return SatChip.select(
      label: label,
      dot: color,
      selected: on,
      size: SatChipSize.sm,
      onTap: onTap,
    );
  }

  Widget _h(String t) {
    final sc = context.sat;
    return Text(t.toUpperCase(), style: SatType.caption(color: sc.textLo));
  }

  Widget _tagBadge(BuildContext context, String t, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Sp.s1h,
        vertical: Sp.sHair,
      ),
      decoration: SatBox.d(color: bg, borderRadius: SatR.a(5)),
      child: Text(t, style: SatType.caption(color: fg)),
    );
  }

  Future<bool?> _confirm(String title, String body) =>
      _confirmSheet(context, title, body);

  Future<String?> _prompt(String title, String initial) {
    final ctl = TextEditingController(text: initial);
    return showSatSheet<String>(
      context,
      builder: (ctx) {
        final sc = ctx.sat;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: _sheetHandle(sc)),
                  const SizedBox(height: Sp.s4h),
                  Text(title, style: SatType.labelL(color: sc.textHi)),
                  const SizedBox(height: Sp.s3h),
                  SatField.text(controller: ctl, hint: '', autofocus: true),
                  const SizedBox(height: Sp.s4),
                  Row(
                    children: [
                      Expanded(
                        child: SatButton.outline(
                          label: AppStrings.cancel,
                          onTap: () => Navigator.pop(ctx),
                        ),
                      ),
                      const SizedBox(width: Sp.s2h),
                      Expanded(
                        child: SatButton.primary(
                          label: AppStrings.save,
                          onTap: () => Navigator.pop(ctx, ctl.text),
                        ),
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
  decoration: SatBox.d(color: sc.border1, borderRadius: SatR.a(2)),
);

Future<bool?> _confirmSheet(
  BuildContext context,
  String title,
  String body, {
  String confirmLabel = AppStrings.confirm,
  bool danger = false,
}) {
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
              Text(body, style: SatType.bodyM(color: sc.textMd)),
              const SizedBox(height: Sp.s4h),
              Row(
                children: [
                  Expanded(
                    child: SatButton.outline(
                      label: AppStrings.cancel,
                      onTap: () => Navigator.pop(ctx, false),
                    ),
                  ),
                  const SizedBox(width: Sp.s2h),
                  Expanded(
                    child: SatButton.danger(
                      label: confirmLabel,
                      onTap: () => Navigator.pop(ctx, true),
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
  const _StaffCard({
    required this.user,
    required this.role,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final disabled = user.disabled;
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: SatCard.tappable(
        onTap: onTap,
        padding: const EdgeInsets.all(Sp.s3h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StaffAvatar(actor: user, fallbackColor: role?.color, size: 44),
            const SizedBox(height: Sp.s3),
            Text(
              user.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SatType.labelL(color: sc.textHi),
            ),
            const SizedBox(height: Sp.s1),
            if (role != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Sp.s1h,
                  vertical: Sp.sHair,
                ),
                decoration: SatBox.d(
                  color: role!.color.withValues(alpha: 0.16),
                  borderRadius: SatR.a(5),
                ),
                child: Text(
                  role!.name.toUpperCase(),
                  style: SatType.caption(color: role!.color),
                ),
              )
            else
              Text(
                AppStrings.staffNoRole,
                style: SatType.monoS(color: sc.textLo),
              ),
            const Spacer(),
            Text('PIN ${user.pin}', style: SatType.monoS(color: sc.textLo)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Avatar color swatch grid
// ─────────────────────────────────────────────────────────────
class _AvatarSwatchGrid extends StatelessWidget {
  final List<int> palette;
  final Set<int> takenColors;
  final int? selected;
  final ValueChanged<int> onPick;
  const _AvatarSwatchGrid({
    required this.palette,
    required this.takenColors,
    required this.selected,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final c in palette)
          _SwatchDot(
            color: Color(c),
            taken: takenColors.contains(c) && c != selected,
            selected: c == selected,
            borderColor: sc.textHi,
            faintBorder: sc.border1,
            onTap: () => onPick(c),
          ),
      ],
    );
  }
}

class _SwatchDot extends StatelessWidget {
  final Color color;
  final bool taken;
  final bool selected;
  final Color borderColor;
  final Color faintBorder;
  final VoidCallback onTap;
  const _SwatchDot({
    required this.color,
    required this.taken,
    required this.selected,
    required this.borderColor,
    required this.faintBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: taken,
      label: AppStrings.a11yPickColor,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: taken ? 0.4 : 1,
          child: Container(
            width: 36,
            height: 36,
            decoration: SatBox.d(
              color: color,
              shape: BoxShape.circle,
              border: SatB.all(
                color: selected ? borderColor : faintBorder,
                width: selected ? 3 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: taken
                ? Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: onFill(color).withValues(alpha: 0.85),
                  )
                : null,
          ),
        ),
      ),
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
  final int avatarColorHex;
  _NewStaff(
    this.name,
    this.initials,
    this.roleId,
    this.legacyRole,
    this.avatarColorHex,
  );
}

class _NewStaffDialog extends StatefulWidget {
  final List<Role> roles;
  final Set<int> takenColors;
  const _NewStaffDialog({required this.roles, required this.takenColors});

  @override
  State<_NewStaffDialog> createState() => _NewStaffDialogState();
}

class _NewStaffDialogState extends State<_NewStaffDialog> {
  final _nameCtl = TextEditingController();
  String? _roleId;
  int? _avatarHex;

  @override
  void initState() {
    super.initState();
    _roleId = widget.roles.first.id;
    // Pre-pick the first non-taken swatch as a hint, but the user must still
    // confirm by leaving or tapping any swatch before Add becomes enabled.
    _avatarHex = avatarColorPalette.firstWhere(
      (c) => !widget.takenColors.contains(c),
      orElse: () => avatarColorPalette.first,
    );
  }

  void _submit() {
    final name = _nameCtl.text.trim();
    if (name.isEmpty || _roleId == null || _avatarHex == null) return;
    final initials = name
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();
    // Pick legacy role best-fit by name keyword
    final rname = widget.roles
        .firstWhere((r) => r.id == _roleId)
        .name
        .toLowerCase();
    final legacy = rname.contains('kitchen') || rname.contains('dapur')
        ? UserRole.kitchen
        : (rname.contains('admin') || rname.contains('manager'))
        ? UserRole.admin
        : UserRole.waiter;
    Navigator.pop(
      context,
      _NewStaff(name, initials, _roleId!, legacy, _avatarHex!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: _sheetHandle(sc)),
              const SizedBox(height: Sp.s4h),
              Text(
                AppStrings.staffAdd,
                style: SatType.labelL(color: sc.textHi),
              ),
              const SizedBox(height: Sp.s4),
              SatField.text(
                controller: _nameCtl,
                label: AppStrings.staffFullName,
                hint: '',
                autofocus: true,
              ),
              const SizedBox(height: Sp.s3),
              SatDropdown<String>(
                value: _roleId,
                label: AppStrings.staffRole,
                options: [
                  for (final r in widget.roles) SatOption(r.id, r.name),
                ],
                onChanged: (v) => setState(() => _roleId = v),
              ),
              const SizedBox(height: Sp.s4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppStrings.staffAvatarColor,
                  style: SatType.caption(color: sc.textLo),
                ),
              ),
              const SizedBox(height: Sp.s2),
              _AvatarSwatchGrid(
                palette: avatarColorPalette,
                takenColors: widget.takenColors,
                selected: _avatarHex,
                onPick: (c) => setState(() => _avatarHex = c),
              ),
              const SizedBox(height: Sp.s4h),
              Row(
                children: [
                  Expanded(
                    child: SatButton.outline(
                      label: AppStrings.cancel,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: Sp.s2h),
                  Expanded(
                    child: SatButton.primary(
                      label: AppStrings.add,
                      onTap: _avatarHex == null ? null : _submit,
                    ),
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
    final u = ref.read(staffRepositoryProvider.notifier).byId(widget.userId);
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
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => Navigator.of(context).maybePop(),
      );
      return const SizedBox.shrink();
    }
    final AppUser user = maybeUser;
    final sc = context.sat;
    return Material(
      color: sc.bg1,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.vertical(top: SatR.c(24)),
      child: SizedBox(
        height: double.infinity,
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Sp.s2),
              Center(child: _sheetHandle(sc)),
              const SizedBox(height: Sp.s1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
                child: Row(
                  children: [
                    StaffAvatar(
                      actor: user,
                      fallbackColor: _findRole(roles, user.roleId)?.color,
                      size: 48,
                    ),
                    const SizedBox(width: Sp.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: SatType.h3(color: sc.textHi)),
                          const SizedBox(height: Sp.sHair),
                          Text(
                            user.disabled
                                ? AppStrings.inactive
                                : AppStrings.active,
                            style: SatType.monoS(
                              color: user.disabled ? sc.urgent : sc.textLo,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: AppStrings.close,
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
                    _label(AppStrings.staffName),
                    SatField.text(
                      controller: _nameCtl,
                      hint: '',
                      onSubmitted: (_) => _saveName(user),
                    ),
                    const SizedBox(height: Sp.s4),
                    _label(AppStrings.staffRole),
                    SatDropdown<String>(
                      value: user.roleId,
                      options: [
                        for (final r in roles)
                          if (!r.has(Capability.manageStaff) ||
                              r.id == user.roleId)
                            SatOption(
                              r.id,
                              r.has(Capability.manageStaff)
                                  ? AppStrings.staffRoleAdminSuffix(r.name)
                                  : r.name,
                            ),
                      ],
                      onChanged: (v) => _changeRole(user, v, roles),
                    ),
                    const SizedBox(height: Sp.s4),
                    _label(AppStrings.staffAvatarColor),
                    _AvatarSwatchGrid(
                      palette: avatarColorPalette,
                      takenColors: {
                        for (final u in users)
                          if (u.id != user.id && u.avatarColorHex != null)
                            u.avatarColorHex!,
                      },
                      selected: user.avatarColorHex,
                      onPick: (c) => _pickAvatarColor(user, c, users),
                    ),
                    const SizedBox(height: Sp.s4),
                    _label(AppStrings.staffPinField),
                    Row(
                      children: [
                        Expanded(
                          child: SatField.number(
                            controller: _pinCtl,
                            hint: '',
                            maxLength: 6,
                            onSubmitted: (_) => _savePin(user),
                          ),
                        ),
                        const SizedBox(width: Sp.s2),
                        SatButton.primary(
                          label: AppStrings.staffPinReset,
                          onTap: () => _resetPin(user),
                        ),
                      ],
                    ),
                    const SizedBox(height: Sp.s4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.disabled
                                ? AppStrings.inactive
                                : AppStrings.active,
                            style: SatType.bodyM(color: sc.textHi),
                          ),
                        ),
                        SatToggle(
                          value: !user.disabled,
                          semanticLabel: AppStrings.active,
                          onChanged: (v) => _setDisabled(user, !v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                decoration: SatBox.d(
                  border: Border(top: SatB.side(color: sc.border0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SatButton.danger(
                        label: AppStrings.delete,
                        onTap: () => _deleteUser(user),
                      ),
                    ),
                    const SizedBox(width: Sp.s2h),
                    Expanded(
                      child: SatButton.primary(
                        label: AppStrings.staffSaveChanges,
                        onTap: () async {
                          final results = await Future.wait([
                            _saveName(user),
                            _savePin(user),
                          ]);
                          if (results.every((ok) => ok) && context.mounted) {
                            Navigator.pop(context);
                          }
                        },
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
      padding: const EdgeInsets.only(bottom: Sp.s1h),
      child: Text(t.toUpperCase(), style: SatType.caption(color: sc.textLo)),
    );
  }

  /// Returns true when the name persisted (or was unchanged). Network
  /// failures are swallowed by the repo's optimistic rename; treat them as
  /// success here since the user can re-open and retry.
  Future<bool> _saveName(AppUser u) async {
    final name = _nameCtl.text.trim();
    if (name.isEmpty) {
      _toast(AppStrings.staffErrNameEmpty);
      _nameCtl.text = u.name;
      return false;
    }
    if (name == u.name) return true;
    final initials = name
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();
    ref.read(staffRepositoryProvider.notifier).rename(u.id, name, initials);
    return true;
  }

  Future<void> _changeRole(AppUser u, String? newId, List<Role> roles) async {
    if (newId == null || newId == u.roleId) return;
    // Block UI-driven promotion to an admin role. Existing admins keep their
    // role in the dropdown but can only be moved to a non-admin role.
    final target = _findRole(roles, newId);
    if (target != null && target.has(Capability.manageStaff)) {
      _toast(AppStrings.staffErrAdminPromoteBlocked);
      return;
    }
    final ok = await _confirmSheet(
      context,
      AppStrings.staffChangeRoleTitle,
      AppStrings.staffChangeRoleBody(u.name),
    );
    if (ok != true) return;
    try {
      ref.read(staffRepositoryProvider.notifier).assignRole(u.id, newId);
    } on StaffException catch (e) {
      _toast(e.message);
    }
  }

  Future<bool> _savePin(AppUser u) async {
    if (_pinCtl.text == u.pin) return true;
    try {
      await ref
          .read(staffRepositoryProvider.notifier)
          .setPin(u.id, _pinCtl.text);
      _toast(AppStrings.staffPinUpdated);
      return true;
    } on StaffException catch (e) {
      _toast(e.message);
      _pinCtl.text = u.pin;
      return false;
    }
  }

  void _pickAvatarColor(AppUser u, int hex, List<AppUser> users) {
    if (hex == u.avatarColorHex) return;
    final collision = users.any((x) => x.id != u.id && x.avatarColorHex == hex);
    if (collision) _toast(AppStrings.staffErrColorTakenShort);
    ref.read(staffRepositoryProvider.notifier).setAvatarColor(u.id, hex);
  }

  Future<void> _resetPin(AppUser u) async {
    try {
      final pin = await ref
          .read(staffRepositoryProvider.notifier)
          .resetPin(u.id);
      _pinCtl.text = pin;
      _toast(AppStrings.staffNewPin(pin));
    } on StaffException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _setDisabled(AppUser u, bool disabled) async {
    if (disabled) {
      final ok = await _confirmSheet(
        context,
        AppStrings.staffDisableTitle(u.name),
        AppStrings.staffDisableBody,
        confirmLabel: AppStrings.staffDisable,
        danger: true,
      );
      if (ok != true) return;
    }
    try {
      ref.read(staffRepositoryProvider.notifier).setDisabled(u.id, disabled);
    } on StaffException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _deleteUser(AppUser u) async {
    final ok = await _confirmSheet(
      context,
      AppStrings.staffDeleteTitle(u.name),
      AppStrings.staffDeleteBody,
      confirmLabel: AppStrings.delete,
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
