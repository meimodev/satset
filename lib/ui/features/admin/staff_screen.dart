import 'package:flutter/material.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/core/localization/labels.dart';
import 'package:satset/ui/core/widgets/sat_card.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_toggle.dart';
import 'package:satset/ui/core/widgets/sat_dropdown.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
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
import 'package:satset/core/localization/locale_view_model.dart';

enum _Tab { people, roles }

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
      title: context.l10n.staffTitle,
      sub: context.l10n.staffSubtitle(users.length, approvers),
      topTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tabChip(context.l10n.staffTabPeople, _Tab.people),
          const SizedBox(width: Sp.s1h),
          _tabChip(context.l10n.staffTabRoles, _Tab.roles),
        ],
      ),
      children: [
        switch (_tab) {
          _Tab.people => _peopleTab(users, roles),
          _Tab.roles => _rolesTab(users, roles),
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
                hint: context.l10n.staffSearchHint,
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(width: Sp.s2h),
            SatButton.primary(
              label: context.l10n.staffAddPill,
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
              _filterChip(context.l10n.staffFilterAll, _roleFilter == null, () {
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
              context.l10n.staffEmpty,
              style: SatType.bodyM(color: sc.textLo),
            ),
          )
        else
          // ponytail: Wrap, not a shrinkWrap GridView — a nested sliver grid
          // inside AdminPage's SingleChildScrollView trips
          // `child.hasSize` during paint. Same tiles, plain box layout.
          LayoutBuilder(
            builder: (ctx, c) {
              const gap = 12.0;
              const maxTile = 200.0;
              final cols = (c.maxWidth / maxTile).ceil().clamp(1, 12);
              final w = (c.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final u in filtered)
                    SizedBox(
                      width: w,
                      height: 168,
                      child: _StaffCard(
                        user: u,
                        role: _roleOf(u, roles),
                        onTap: () => _openDetail(u),
                      ),
                    ),
                ],
              );
            },
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
              context.l10n.staffRolesCount(roles.length),
              style: SatType.bodyM(color: sc.textMd),
            ),
            const Spacer(),
            SatButton.primary(
              label: context.l10n.staffNewRolePill,
              size: SatButtonSize.sm,
              onTap: _createRole,
            ),
          ],
        ),
        const SizedBox(height: Sp.s1),
        Text(
          context.l10n.staffRolePermsHint,
          style: SatType.bodyS(color: sc.textLo),
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

  /// Scan only. Rename, colour and delete moved into the sheet this row opens —
  /// the row's job is comparing four roles at a glance, and a delete button
  /// sitting in a list you scan is one mis-tap from a role nobody meant to lose.
  Widget _roleRow(Role r, List<AppUser> users, {bool last = false}) {
    final sc = context.sat;
    final memberCount = users
        .where((u) => u.roleId == r.id && !u.disabled)
        .length;
    final isAdminRole = r.has(Capability.manageStaff);
    return Semantics(
      button: true,
      label: r.name,
      child: GestureDetector(
        onTap: () => _openRole(r),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
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
                  context.l10n.staffCapsCount(
                    r.capabilities.length,
                    Capability.values.length,
                  ),
                  style: SatType.monoS(color: sc.textMd),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  context.l10n.staffMembersCount(memberCount),
                  style: SatType.monoS(color: sc.textMd),
                ),
              ),
              // The admin role is infrastructure, not a role this screen hands
              // out: it belongs to the venue's one Firebase admin (ADR-0077),
              // and every path that could assign, grant or mint it is already
              // refused here and at the server. Shown but locked rather than
              // hidden — a person in the Orang tab holds it, so a list that
              // omitted it would leave that row pointing at a role defined
              // nowhere. The row still opens: its sheet is read-only, which
              // shows the state without ever offering an action on it.
              if (isAdminRole) ...[
                _tagBadge(
                  context,
                  context.l10n.staffRoleBadgeAdmin,
                  sc.violet,
                  sc.violetSoft,
                ),
                const SizedBox(width: Sp.s2),
              ],
              Icon(Icons.chevron_right, size: 20, color: sc.textDim),
            ],
          ),
        ),
      ),
    );
  }

  void _openRole(Role r) {
    showSatSheet<void>(
      context,
      bare: true,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.92,
        child: _RolePermissionsDrawer(roleId: r.id),
      ),
    );
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
    // Captured before the await: reading it off `context` afterwards is
    // exactly the use_build_context_synchronously the analyzer flags.
    final l10n = context.l10n;
    final selectable = [
      for (final r in roles)
        if (!r.has(Capability.manageStaff)) r,
    ];
    if (selectable.isEmpty) {
      _toast(l10n.staffErrNeedNonAdminRole);
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
      _toast(l10n.staffErrColorTaken);
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
      _toast(l10n.staffCreated(created.name, created.pin));
    } on StaffException catch (e) {
      _toast(staffErrorMessage(l10n, e));
    }
  }

  Future<void> _createRole() async {
    final name = await _prompt(context.l10n.staffNewRoleName, '');
    if (name == null || name.trim().isEmpty) return;
    ref.read(rolesRepositoryProvider.notifier).create(name.trim());
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

  /// Two tabs that fit on one line — a chip row shows both choices at once,
  /// where SatTabs would give the pair a heavier frame.
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

  Future<String?> _prompt(String title, String initial) =>
      _promptSheet(context, title, initial);

  void _toast(String msg) => _snack(context, msg);
}

Future<String?> _promptSheet(
  BuildContext context,
  String title,
  String initial,
) {
  final ctl = TextEditingController(text: initial);
  return showSatSheet<String>(
    context,
    builder: (ctx) {
      final sc = ctx.sat;
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                        label: context.l10n.cancel,
                        onTap: () => Navigator.pop(ctx),
                      ),
                    ),
                    const SizedBox(width: Sp.s2h),
                    Expanded(
                      child: SatButton.primary(
                        label: context.l10n.save,
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

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
  );
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
  // Defaulted at the body, not in the signature: a default must be const
  // and a localised string is not.
  String? confirmLabel,
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
                      label: context.l10n.cancel,
                      onTap: () => Navigator.pop(ctx, false),
                    ),
                  ),
                  const SizedBox(width: Sp.s2h),
                  Expanded(
                    child: SatButton.danger(
                      label: confirmLabel ?? ctx.l10n.confirm,
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
                context.l10n.staffNoRole,
                style: SatType.monoS(color: sc.textLo),
              ),
            // ponytail: fixed gap, not a Spacer — SatCard shrink-wraps its
            // child (Column mainAxisSize.min), so a flex child here gets
            // unbounded height and the whole page fails layout.
            const SizedBox(height: Sp.s2),
            Text(
              context.l10n.stfPinIs(user.pin),
              style: SatType.monoS(color: sc.textLo),
            ),
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
      label: context.l10n.a11yPickColor,
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
                context.l10n.staffAdd,
                style: SatType.labelL(color: sc.textHi),
              ),
              const SizedBox(height: Sp.s4),
              SatField.text(
                controller: _nameCtl,
                label: context.l10n.staffFullName,
                hint: '',
                autofocus: true,
              ),
              const SizedBox(height: Sp.s3),
              SatDropdown<String>(
                value: _roleId,
                label: context.l10n.staffRole,
                options: [
                  for (final r in widget.roles) SatOption(r.id, r.name),
                ],
                onChanged: (v) => setState(() => _roleId = v),
              ),
              const SizedBox(height: Sp.s4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.l10n.staffAvatarColor,
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
                      label: context.l10n.cancel,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: Sp.s2h),
                  Expanded(
                    child: SatButton.primary(
                      label: context.l10n.add,
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
                                ? context.l10n.inactive
                                : context.l10n.active,
                            style: SatType.monoS(
                              color: user.disabled ? sc.urgent : sc.textLo,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: context.l10n.close,
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
                    _label(context.l10n.staffName),
                    SatField.text(
                      controller: _nameCtl,
                      hint: '',
                      onSubmitted: (_) => _saveName(user),
                    ),
                    const SizedBox(height: Sp.s4),
                    _label(context.l10n.staffRole),
                    SatDropdown<String>(
                      value: user.roleId,
                      options: [
                        for (final r in roles)
                          if (!r.has(Capability.manageStaff) ||
                              r.id == user.roleId)
                            SatOption(
                              r.id,
                              r.has(Capability.manageStaff)
                                  ? context.l10n.staffRoleAdminSuffix(r.name)
                                  : r.name,
                            ),
                      ],
                      onChanged: (v) => _changeRole(user, v, roles),
                    ),
                    const SizedBox(height: Sp.s4),
                    _label(context.l10n.staffAvatarColor),
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
                    _label(context.l10n.staffPinField),
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
                          label: context.l10n.staffPinReset,
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
                                ? context.l10n.inactive
                                : context.l10n.active,
                            style: SatType.bodyM(color: sc.textHi),
                          ),
                        ),
                        SatToggle(
                          value: !user.disabled,
                          semanticLabel: context.l10n.active,
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
                        label: context.l10n.delete,
                        onTap: () => _deleteUser(user),
                      ),
                    ),
                    const SizedBox(width: Sp.s2h),
                    Expanded(
                      child: SatButton.primary(
                        label: context.l10n.staffSaveChanges,
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
      _toast(context.l10n.staffErrNameEmpty);
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
      _toast(context.l10n.staffErrAdminPromoteBlocked);
      return;
    }
    final l10n = context.l10n;
    final ok = await _confirmSheet(
      context,
      l10n.staffChangeRoleTitle,
      l10n.staffChangeRoleBody(u.name),
    );
    if (ok != true) return;
    try {
      ref.read(staffRepositoryProvider.notifier).assignRole(u.id, newId);
    } on StaffException catch (e) {
      _toast(staffErrorMessage(l10n, e));
    }
  }

  Future<bool> _savePin(AppUser u) async {
    // Captured before the await: reading it off `context` afterwards is
    // exactly the use_build_context_synchronously the analyzer flags.
    final l10n = context.l10n;
    if (_pinCtl.text == u.pin) return true;
    try {
      await ref
          .read(staffRepositoryProvider.notifier)
          .setPin(u.id, _pinCtl.text);
      _toast(l10n.staffPinUpdated);
      return true;
    } on StaffException catch (e) {
      _toast(staffErrorMessage(l10n, e));
      _pinCtl.text = u.pin;
      return false;
    }
  }

  void _pickAvatarColor(AppUser u, int hex, List<AppUser> users) {
    if (hex == u.avatarColorHex) return;
    final collision = users.any((x) => x.id != u.id && x.avatarColorHex == hex);
    if (collision) _toast(context.l10n.staffErrColorTakenShort);
    ref.read(staffRepositoryProvider.notifier).setAvatarColor(u.id, hex);
  }

  Future<void> _resetPin(AppUser u) async {
    // Captured before the await: reading it off `context` afterwards is
    // exactly the use_build_context_synchronously the analyzer flags.
    final l10n = context.l10n;
    try {
      final pin = await ref
          .read(staffRepositoryProvider.notifier)
          .resetPin(u.id);
      _pinCtl.text = pin;
      _toast(l10n.staffNewPin(pin));
    } on StaffException catch (e) {
      _toast(staffErrorMessage(l10n, e));
    }
  }

  Future<void> _setDisabled(AppUser u, bool disabled) async {
    final l10n = context.l10n;
    if (disabled) {
      final ok = await _confirmSheet(
        context,
        l10n.staffDisableTitle(u.name),
        l10n.staffDisableBody,
        confirmLabel: l10n.staffDisable,
        danger: true,
      );
      if (ok != true) return;
    }
    try {
      ref.read(staffRepositoryProvider.notifier).setDisabled(u.id, disabled);
    } on StaffException catch (e) {
      _toast(staffErrorMessage(l10n, e));
    }
  }

  Future<void> _deleteUser(AppUser u) async {
    final l10n = context.l10n;
    final ok = await _confirmSheet(
      context,
      l10n.staffDeleteTitle(u.name),
      l10n.staffDeleteBody,
      confirmLabel: l10n.delete,
      danger: true,
    );
    if (ok != true) return;
    try {
      ref.read(staffRepositoryProvider.notifier).delete(u.id);
      if (mounted) Navigator.pop(context);
    } on StaffException catch (e) {
      _toast(staffErrorMessage(l10n, e));
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

// ─────────────────────────────────────────────────────────────
// Role permissions drawer
// ─────────────────────────────────────────────────────────────

/// One role's permissions, grouped. Replaced the role × capability grid
/// (ADR-0087): the grid could compare four roles at once but had 110dp of
/// width per cell, which is enough for a label and nothing else. A sheet holds
/// one role and can afford to say what each capability actually does.
class _RolePermissionsDrawer extends ConsumerWidget {
  final String roleId;
  const _RolePermissionsDrawer({required this.roleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(rolesRepositoryProvider);
    final users = ref.watch(staffRepositoryProvider);
    final role = _findRole(roles, roleId);
    if (role == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => Navigator.of(context).maybePop(),
      );
      return const SizedBox.shrink();
    }
    final sc = context.sat;
    // The admin role is read-only end to end (ADR-0077). Locked here means the
    // whole sheet states rather than offers: no toggles, no rename, no delete.
    final locked = role.has(Capability.manageStaff);
    final memberCount = users
        .where((u) => u.roleId == role.id && !u.disabled)
        .length;

    // [[Tanpa antrian persiapan]] (ADR-0115): a venue with no prep queue has
    // no screen for `viewKds` to open, so the row is not offered. **Hidden, not
    // revoked** — the toggle writes the role's *stored* set (`setCapability`
    // rebuilds the PATCH from the row, never from what this sheet renders), so
    // an existing cook keeps the capability and gets it back the day the mode
    // is turned off. `CapabilityGroup.kitchen` holds nothing else, so its card
    // goes with it rather than standing empty.
    final bypassKds = ref.watch(
      venueSettingsProvider.select((v) => v.bypassKds),
    );
    final grouped = <CapabilityGroup, List<Capability>>{};
    for (final c in Capability.values) {
      if (bypassKds && c == Capability.viewKds) continue;
      grouped.putIfAbsent(c.group, () => []).add(c);
    }

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
                    Container(
                      width: 18,
                      height: 18,
                      decoration: SatBox.d(
                        color: role.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: Sp.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(role.name, style: SatType.h3(color: sc.textHi)),
                          const SizedBox(height: Sp.sHair),
                          Text(
                            context.l10n.staffMembersCount(memberCount),
                            style: SatType.monoS(color: sc.textLo),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: context.l10n.close,
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    if (locked)
                      Container(
                        padding: const EdgeInsets.all(Sp.s3h),
                        decoration: SatBox.d(
                          color: sc.violetSoft,
                          border: SatB.all(color: sc.violet),
                          borderRadius: SatR.a(12),
                        ),
                        child: Text(
                          context.l10n.staffRoleLockedBanner,
                          style: SatType.bodyS(color: sc.textHi),
                        ),
                      )
                    else
                      Row(
                        children: [
                          SatButton.outline(
                            label: context.l10n.staffColor,
                            size: SatButtonSize.sm,
                            onTap: () => _pickColor(context, ref, role),
                          ),
                          const SizedBox(width: Sp.s1h),
                          SatButton.outline(
                            label: context.l10n.a11yRename,
                            size: SatButtonSize.sm,
                            onTap: () => _rename(context, ref, role),
                          ),
                          const Spacer(),
                          // Guarded by member count, not by confidence: a role
                          // still worn by someone cannot be deleted, and the
                          // dead button says so before the sheet does.
                          SatButton.danger(
                            label: context.l10n.delete,
                            size: SatButtonSize.sm,
                            onTap: memberCount == 0
                                ? () => _delete(context, ref, role)
                                : null,
                          ),
                        ],
                      ),
                    for (final g in CapabilityGroup.values)
                      if (grouped[g]?.isNotEmpty ?? false) ...[
                      const SizedBox(height: Sp.s4),
                      SatCard.section(
                        header: capabilityGroupLabel(context.l10n, g),
                        // textLo, not textMd: the count sits beside a caps
                        // header and matching its weight made an empty group
                        // read as loud as a full one.
                        headerTrailing: Text(
                          context.l10n.capGrpCount(
                            grouped[g]!.where(role.has).length,
                            grouped[g]!.length,
                          ),
                          style: SatType.monoS(color: sc.textLo),
                        ),
                        padding: const EdgeInsets.fromLTRB(
                          Sp.s4,
                          Sp.s4,
                          Sp.s4,
                          Sp.s2,
                        ),
                        child: Column(
                          children: [
                            for (final c in grouped[g]!)
                              _CapRow(role: role, cap: c, roleLocked: locked),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, Role r) async {
    final name = await _promptSheet(
      context,
      context.l10n.staffRenameRole,
      r.name,
    );
    if (name == null || name.trim().isEmpty) return;
    ref.read(rolesRepositoryProvider.notifier).rename(r.id, name.trim());
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Role r) async {
    // Captured before the await: reading it off `context` afterwards is
    // exactly the use_build_context_synchronously the analyzer flags.
    final l10n = context.l10n;
    final nav = Navigator.of(context);
    final ok = await _confirmSheet(
      context,
      l10n.staffDeleteRoleTitle(r.name),
      l10n.staffDeleteRoleBody,
    );
    if (ok != true) return;
    // The admin role's sheet has no delete button to reach this, and the server
    // refuses it besides (ADR-0077) — but this is the function a future caller
    // will reach for, so it states the rule rather than trusting the caller.
    if (r.has(Capability.manageStaff)) return;
    ref.read(rolesRepositoryProvider.notifier).delete(r.id);
    nav.maybePop();
  }

  Future<void> _pickColor(BuildContext context, WidgetRef ref, Role r) async {
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
                  ctx.l10n.staffRoleColor,
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
                        label: ctx.l10n.staffColor,
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
}

/// One capability: what it is, what it lets a person do, and whether this role
/// has it. Three shapes, and only the first is a control — a locked row is not
/// a disabled toggle that refuses on tap, it is state (ADR-0077's rule, applied
/// to `manageStaff` too, where a toast used to stand in for it).
class _CapRow extends ConsumerWidget {
  final Role role;
  final Capability cap;
  final bool roleLocked;
  const _CapRow({
    required this.role,
    required this.cap,
    required this.roleLocked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final on = role.has(cap);
    // Admin is Firebase-only: a local admin granting `manageStaff` would mint
    // an admin-level role as a backdoor, so the row never offers it. The server
    // refuses the same PATCH regardless. See ADR-0017.
    final adminOnly = cap == Capability.manageStaff;
    final locked = roleLocked || adminOnly;
    final label = capabilityLabel(context.l10n, cap);
    final desc = adminOnly && !roleLocked
        ? context.l10n.staffCapAdminOnly
        : capabilityDescription(context.l10n, cap);

    final body = Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.s2h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: SatType.bodyM(
                    color: locked && !on ? sc.textLo : sc.textHi,
                  ),
                ),
                const SizedBox(height: Sp.sHair),
                Text(desc, style: SatType.bodyS(color: sc.textLo)),
              ],
            ),
          ),
          const SizedBox(width: Sp.s3),
          if (locked)
            Padding(
              padding: const EdgeInsets.only(top: Sp.sHair),
              child: Text(
                on ? context.l10n.stfRoleActive : context.l10n.dscInactive,
                style: SatType.monoS(color: on ? sc.success : sc.textDim),
              ),
            )
          else
            SatToggle(
              value: on,
              onChanged: (v) => ref
                  .read(rolesRepositoryProvider.notifier)
                  .setCapability(role.id, cap, v),
              semanticLabel: context.l10n.stfRoleSemantics(role.name, label),
            ),
        ],
      ),
    );

    // Returned with no tap target at all — TalkBack reads the state without
    // ever offering an action on it.
    if (locked) {
      return Semantics(
        label: context.l10n.stfRoleLockedSemantics(
          role.name,
          label,
          on ? context.l10n.stfRoleActive : context.l10n.dscInactive,
        ),
        excludeSemantics: true,
        child: body,
      );
    }
    return body;
  }
}
