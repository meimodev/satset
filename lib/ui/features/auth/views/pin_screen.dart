import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/data/repositories/auth_repository.dart';

enum _LoginMode { admin, staff }

class _ServerOption {
  final String id;
  final String name;
  final String ip;
  final String latency;
  final bool online;
  const _ServerOption({
    required this.id,
    required this.name,
    required this.ip,
    required this.latency,
    required this.online,
  });
}

const List<_ServerOption> _kServers = [
  _ServerOption(
      id: 'warung-berawa',
      name: 'Warung Sebelah · Berawa',
      ip: '192.168.4.21',
      latency: '38 ms',
      online: true),
  _ServerOption(
      id: 'cabang-sanur',
      name: 'Cabang Sanur',
      ip: '192.168.5.10',
      latency: '62 ms',
      online: true),
  _ServerOption(
      id: 'cabang-ubud',
      name: 'Cabang Ubud',
      ip: '192.168.6.4',
      latency: '—',
      online: false),
];

class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _pin = '';
  static const _max = 4;
  _LoginMode _mode = _LoginMode.staff;
  String _serverId = _kServers.first.id;

  final _adminEmail = TextEditingController(text: 'admin@warungsebelah.id');
  final _adminPassword = TextEditingController();
  bool _showAdminPw = false;
  String? _emailError;
  String? _passwordError;

  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  @override
  void initState() {
    super.initState();
    _adminEmail.addListener(_clearEmailError);
    _adminPassword.addListener(_clearPasswordError);
  }

  @override
  void dispose() {
    _adminEmail.removeListener(_clearEmailError);
    _adminPassword.removeListener(_clearPasswordError);
    _adminEmail.dispose();
    _adminPassword.dispose();
    super.dispose();
  }

  void _clearEmailError() {
    if (_emailError != null) setState(() => _emailError = null);
  }

  void _clearPasswordError() {
    if (_passwordError != null) setState(() => _passwordError = null);
  }

  String? _validateEmail(String v) {
    final e = v.trim();
    if (e.isEmpty) return 'Email wajib diisi';
    if (!_emailRegex.hasMatch(e)) return 'Format email tidak valid';
    return null;
  }

  String? _validatePassword(String v) {
    if (v.isEmpty) return 'Kata sandi wajib diisi';
    if (v.length < 6) return 'Minimal 6 karakter';
    return null;
  }

  void _signInAdmin() {
    final emailErr = _validateEmail(_adminEmail.text);
    final pwErr = _validatePassword(_adminPassword.text);
    if (emailErr != null || pwErr != null) {
      setState(() {
        _emailError = emailErr;
        _passwordError = pwErr;
      });
      return;
    }
    FocusScope.of(context).unfocus();
    ref.read(authStateProvider.notifier).signIn();
    context.go('/tables');
  }

  void _press(String d) {
    if (d == 'del') {
      setState(() =>
          _pin = _pin.isEmpty ? _pin : _pin.substring(0, _pin.length - 1));
      return;
    }
    if (_pin.length >= _max) return;
    setState(() => _pin = _pin + d);
    if (_pin.length == _max) {
      Future.delayed(const Duration(milliseconds: 220), () {
        if (!mounted) return;
        ref.read(authStateProvider.notifier).signIn();
        context.go('/tables');
      });
    }
  }

  void _setMode(_LoginMode m) {
    setState(() => _mode = m);
  }

  void _setServer(String id) {
    setState(() => _serverId = id);
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l = context.layout;

    final modeSwitcher = _ModeSwitcher(mode: _mode, onChange: _setMode);
    final serverList = _ServerList(
      servers: _kServers,
      selectedId: _serverId,
      onSelect: _setServer,
    );

    if (l.useTabletShell) {
      return Scaffold(
        backgroundColor: sc.bg0,
        body: Row(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                color: sc.bg1,
                padding: const EdgeInsets.fromLTRB(56, 56, 56, 32),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TabletBrand(),
                      const SizedBox(height: 48),
                      Text('Selamat sore',
                          style: SatType.mono(
                            size: 13,
                            color: sc.textMd,
                            letterSpacing: 1.3,
                          )),
                      const SizedBox(height: 22),
                      modeSwitcher,
                      if (_mode == _LoginMode.staff) ...[
                        const SizedBox(height: 18),
                        serverList,
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: 480,
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: sc.border0)),
              ),
              padding: const EdgeInsets.fromLTRB(48, 56, 48, 32),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ModeHeading(mode: _mode, serverId: _serverId),
                      const SizedBox(height: 28),
                      if (_mode == _LoginMode.staff) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _max,
                            (i) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 9),
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      i < _pin.length ? sc.accent : sc.bg3,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _PinHelper(pinLength: _pin.length, max: _max),
                        const SizedBox(height: 22),
                        _Pad(onPress: _press, tablet: true),
                      ] else
                        _AdminAuthForm(
                          email: _adminEmail,
                          password: _adminPassword,
                          showPassword: _showAdminPw,
                          onToggleShow: () => setState(
                              () => _showAdminPw = !_showAdminPw),
                          onSubmit: _signInAdmin,
                          emailError: _emailError,
                          passwordError: _passwordError,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final brand = _Brand();
    final greeting = Text('Selamat sore',
        style: SatType.mono(
          size: 13,
          color: sc.textMd,
          letterSpacing: 1.04,
        ));
    final dots = Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _max,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _pin.length ? sc.accent : sc.bg3,
              ),
            ),
          ),
        ),
      ),
    );
    final pad = _Pad(onPress: _press, tablet: false);
    final modeHeading = _ModeHeading(mode: _mode, serverId: _serverId);
    final adminForm = _AdminAuthForm(
      email: _adminEmail,
      password: _adminPassword,
      showPassword: _showAdminPw,
      onToggleShow: () => setState(() => _showAdminPw = !_showAdminPw),
      onSubmit: _signInAdmin,
      emailError: _emailError,
      passwordError: _passwordError,
    );
    final authBody = _mode == _LoginMode.staff
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              dots,
              const SizedBox(height: 10),
              _PinHelper(pinLength: _pin.length, max: _max),
              const SizedBox(height: 18),
              pad,
            ],
          )
        : adminForm;

    final twoCol = l.isLandscape && l.size.width >= 720;

    final modeBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        modeSwitcher,
        if (_mode == _LoginMode.staff) ...[
          const SizedBox(height: 14),
          serverList,
        ],
      ],
    );

    return Scaffold(
      backgroundColor: sc.bg0,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: twoCol ? 980 : 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
              child: twoCol
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              brand,
                              const SizedBox(height: 36),
                              greeting,
                              const SizedBox(height: 24),
                              modeBlock,
                            ],
                          ),
                        ),
                        const SizedBox(width: 48),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              modeHeading,
                              const SizedBox(height: 22),
                              authBody,
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        brand,
                        const SizedBox(height: 36),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: greeting,
                        ),
                        const SizedBox(height: 22),
                        modeBlock,
                        const SizedBox(height: 26),
                        modeHeading,
                        const SizedBox(height: 18),
                        authBody,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeHeading extends StatelessWidget {
  final _LoginMode mode;
  final String serverId;
  const _ModeHeading({required this.mode, required this.serverId});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final isAdmin = mode == _LoginMode.admin;
    final server =
        _kServers.firstWhere((s) => s.id == serverId, orElse: () => _kServers.first);
    final label = isAdmin ? 'MODE ADMIN' : 'MODE STAFF';
    final title = isAdmin ? 'Masuk admin' : 'Masukkan PIN';
    final sub = isAdmin
        ? 'Login dengan email & kata sandi'
        : 'Tersambung ke ${server.name}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isAdmin ? sc.warnSoft : sc.accentSoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(label,
              style: SatType.mono(
                size: 10,
                weight: FontWeight.w600,
                letterSpacing: 1.2,
                color: isAdmin ? sc.warn : sc.accent,
              )),
        ),
        const SizedBox(height: 8),
        Text(title,
            style: SatType.sans(
              size: 22,
              weight: FontWeight.w600,
              letterSpacing: -0.22,
              color: sc.textHi,
            )),
        const SizedBox(height: 2),
        Text(sub,
            textAlign: TextAlign.center,
            style: SatType.sans(size: 12, color: sc.textMd)),
      ],
    );
  }
}

class _AdminAuthForm extends StatelessWidget {
  final TextEditingController email;
  final TextEditingController password;
  final bool showPassword;
  final VoidCallback onToggleShow;
  final VoidCallback onSubmit;
  final String? emailError;
  final String? passwordError;
  const _AdminAuthForm({
    required this.email,
    required this.password,
    required this.showPassword,
    required this.onToggleShow,
    required this.onSubmit,
    this.emailError,
    this.passwordError,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final pwHasError = passwordError != null;
    final pwBorder = pwHasError ? sc.urgent : sc.border0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Field(
          label: 'Email admin',
          controller: email,
          hint: 'admin@warung.id',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          errorText: emailError,
        ),
        const SizedBox(height: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('KATA SANDI',
                style: SatType.mono(
                    size: 10,
                    weight: FontWeight.w500,
                    letterSpacing: 1.2,
                    color: sc.textLo)),
            const SizedBox(height: 6),
            TextField(
              controller: password,
              obscureText: !showPassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
              style: SatType.sans(size: 15, color: sc.textHi),
              decoration: InputDecoration(
                hintText: '••••••••',
                hintStyle: SatType.sans(size: 15, color: sc.textLo),
                filled: true,
                fillColor: sc.bg2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: pwBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: pwBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: pwHasError ? sc.urgent : sc.accent),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                suffixIcon: IconButton(
                  onPressed: onToggleShow,
                  icon: Icon(
                    showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: sc.textMd,
                  ),
                ),
              ),
            ),
            if (pwHasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 2),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 12, color: sc.urgent),
                    const SizedBox(width: 6),
                    Text(passwordError!,
                        style: SatType.sans(
                            size: 12,
                            weight: FontWeight.w500,
                            color: sc.urgent)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4)),
            child: Text('Lupa kata sandi?',
                style: SatType.sans(
                    size: 12,
                    weight: FontWeight.w500,
                    color: sc.textMd)),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: onSubmit,
            icon: Icon(Icons.shield_moon_outlined,
                size: 18, color: sc.accentInk),
            label: Text('Masuk sebagai admin',
                style: SatType.sans(
                    size: 15,
                    weight: FontWeight.w600,
                    color: sc.accentInk)),
            style: ElevatedButton.styleFrom(
              backgroundColor: sc.accent,
              foregroundColor: sc.accentInk,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 12, color: sc.textLo),
            const SizedBox(width: 6),
            Text('Akses penuh manajer · audit dicatat',
                style: SatType.mono(
                    size: 10, color: sc.textLo, letterSpacing: 0.4)),
          ],
        ),
      ],
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  final _LoginMode mode;
  final ValueChanged<_LoginMode> onChange;
  const _ModeSwitcher({required this.mode, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _modeTab(
              context,
              sc,
              icon: Icons.shield_moon_outlined,
              label: 'Admin',
              sub: 'Server lokal',
              active: mode == _LoginMode.admin,
              onTap: () => onChange(_LoginMode.admin),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _modeTab(
              context,
              sc,
              icon: Icons.badge_outlined,
              label: 'Staff',
              sub: 'Pilih server',
              active: mode == _LoginMode.staff,
              onTap: () => onChange(_LoginMode.staff),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeTab(
    BuildContext context,
    SatColors sc, {
    required IconData icon,
    required String label,
    required String sub,
    required bool active,
    required VoidCallback onTap,
  }) {
    final fg = active ? sc.accent : sc.textMd;
    return Material(
      color: active ? sc.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: SatType.sans(
                          size: 14,
                          weight: FontWeight.w600,
                          letterSpacing: -0.14,
                          color: active ? sc.textHi : sc.textMd,
                        )),
                    const SizedBox(height: 1),
                    Text(sub,
                        style: SatType.mono(
                          size: 10,
                          color: active ? fg : sc.textLo,
                          letterSpacing: 0.4,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServerList extends StatelessWidget {
  final List<_ServerOption> servers;
  final String selectedId;
  final ValueChanged<String> onSelect;
  const _ServerList({
    required this.servers,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Row(
            children: [
              Text('SERVER TERSEDIA',
                  style: SatType.mono(
                    size: 10,
                    weight: FontWeight.w500,
                    letterSpacing: 1.2,
                    color: sc.textLo,
                  )),
              const Spacer(),
              Text('${servers.where((s) => s.online).length}/${servers.length} ONLINE',
                  style: SatType.mono(
                    size: 10,
                    color: sc.textDim,
                    letterSpacing: 1.2,
                  )),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: sc.bg2,
            border: Border.all(color: sc.border0),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              for (var i = 0; i < servers.length; i++) ...[
                _ServerRow(
                  server: servers[i],
                  selected: servers[i].id == selectedId,
                  onTap: servers[i].online
                      ? () => onSelect(servers[i].id)
                      : null,
                ),
                if (i != servers.length - 1)
                  Divider(height: 1, color: sc.border0),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _OutlineActionButton(
                icon: Icons.add_link_rounded,
                label: 'Tambah manual',
                onTap: () => showManualServerSheet(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OutlineActionButton(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Pindai QR',
                onTap: () => showQrScanSheet(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OutlineActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Material(
      color: sc.bg2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sc.border1),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: sc.textMd),
              const SizedBox(width: 8),
              Text(label,
                  style: SatType.sans(
                    size: 13,
                    weight: FontWeight.w600,
                    letterSpacing: -0.13,
                    color: sc.textHi,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServerRow extends StatelessWidget {
  final _ServerOption server;
  final bool selected;
  final VoidCallback? onTap;
  const _ServerRow({
    required this.server,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final disabled = onTap == null;
    final dotColor = server.online ? sc.success : sc.urgent;
    return Material(
      color: selected ? sc.accentSoft : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                  boxShadow: server.online
                      ? [BoxShadow(color: sc.successSoft, spreadRadius: 3)]
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(server.name,
                        style: SatType.sans(
                          size: 14,
                          weight: FontWeight.w500,
                          letterSpacing: -0.14,
                          color: disabled ? sc.textLo : sc.textHi,
                        )),
                    const SizedBox(height: 2),
                    Text(
                      server.online
                          ? '${server.ip} · ${server.latency}'
                          : '${server.ip} · offline',
                      style: SatType.mono(
                        size: 10,
                        color: disabled ? sc.textDim : sc.textLo,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: sc.accent,
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.check, size: 14, color: sc.accentInk),
                )
              else if (disabled)
                Text('OFFLINE',
                    style: SatType.mono(
                      size: 9,
                      weight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: sc.textDim,
                    ))
              else
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: sc.border2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: sc.accent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            'S',
            style: SatType.mono(
              size: 16,
              weight: FontWeight.w700,
              letterSpacing: -0.64,
              color: sc.accentInk,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('satset',
            style: SatType.sans(
              size: 18,
              weight: FontWeight.w600,
              letterSpacing: -0.18,
              color: sc.textHi,
            )),
      ],
    );
  }
}

class _TabletBrand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: sc.accent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            'S',
            style: SatType.mono(
              size: 22,
              weight: FontWeight.w700,
              letterSpacing: -0.88,
              color: sc.accentInk,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text('satset',
            style: SatType.sans(
              size: 22,
              weight: FontWeight.w600,
              letterSpacing: -0.22,
              color: sc.textHi,
            )),
      ],
    );
  }
}

class _Pad extends StatelessWidget {
  final void Function(String) onPress;
  final bool tablet;
  const _Pad({required this.onPress, required this.tablet});

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'del'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: tablet ? 12 : 10,
      crossAxisSpacing: tablet ? 12 : 10,
      childAspectRatio: tablet ? 1.6 : 1.4,
      children: [
        for (final k in keys)
          if (k == '')
            const SizedBox.shrink()
          else
            _PinKey(label: k, tablet: tablet, onTap: () => onPress(k)),
      ],
    );
  }
}

void showManualServerSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ManualServerSheet(),
  );
}

void showQrScanSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _QrScanSheet(),
  );
}

class _SheetShell extends StatelessWidget {
  final String title;
  final String? sub;
  final Widget child;
  const _SheetShell({required this.title, this.sub, required this.child});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: sc.bg1,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: sc.border2,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: SatType.sans(
                                size: 20,
                                weight: FontWeight.w600,
                                letterSpacing: -0.4,
                                color: sc.textHi,
                              )),
                          if (sub != null) ...[
                            const SizedBox(height: 3),
                            Text(sub!,
                                style: SatType.sans(
                                    size: 13, color: sc.textMd, height: 1.4)),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(Icons.close_rounded, color: sc.textMd),
                    ),
                  ],
                ),
              ),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManualServerSheet extends StatefulWidget {
  const _ManualServerSheet();

  @override
  State<_ManualServerSheet> createState() => _ManualServerSheetState();
}

class _ManualServerSheetState extends State<_ManualServerSheet> {
  final _name = TextEditingController(text: 'Cabang baru');
  final _host = TextEditingController();
  final _port = TextEditingController(text: '8080');
  bool _testing = false;
  bool? _testOk;
  String _testLatency = '';

  @override
  void dispose() {
    _name.dispose();
    _host.dispose();
    _port.dispose();
    super.dispose();
  }

  void _runTest() async {
    setState(() {
      _testing = true;
      _testOk = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final ok = _host.text.trim().isNotEmpty;
    setState(() {
      _testing = false;
      _testOk = ok;
      _testLatency = ok ? '42 ms' : 'host kosong';
    });
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final canSave = _testOk == true;
    return _SheetShell(
      title: 'Tambah server',
      sub: 'Isi alamat server lokal yang ingin dijadikan target staff.',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Field(label: 'Nama server', controller: _name, hint: 'Cabang Kuta'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _Field(
                      label: 'Host / IP',
                      controller: _host,
                      hint: '192.168.4.21'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: _Field(
                      label: 'Port', controller: _port, hint: '8080'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: sc.bg2,
                border: Border.all(color: sc.border0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  if (_testing)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: sc.accent),
                    )
                  else if (_testOk == true)
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: sc.successSoft,
                      ),
                      alignment: Alignment.center,
                      child:
                          Icon(Icons.check, size: 14, color: sc.success),
                    )
                  else if (_testOk == false)
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: sc.urgentSoft,
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.close_rounded,
                          size: 14, color: sc.urgent),
                    )
                  else
                    Icon(Icons.wifi_find_rounded,
                        size: 18, color: sc.textMd),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _testing
                              ? 'Menguji koneksi...'
                              : _testOk == true
                                  ? 'Terhubung'
                                  : _testOk == false
                                      ? 'Gagal'
                                      : 'Belum diuji',
                          style: SatType.sans(
                              size: 14,
                              weight: FontWeight.w600,
                              color: sc.textHi),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _testing
                              ? 'Mencari handshake LAN'
                              : _testOk == true
                                  ? '$_testLatency · cert OK'
                                  : _testOk == false
                                      ? _testLatency
                                      : 'Tekan "Uji koneksi" untuk verifikasi',
                          style: SatType.mono(
                              size: 10,
                              color: sc.textLo,
                              letterSpacing: 0.4),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _testing ? null : _runTest,
                    child: Text('Uji koneksi',
                        style: SatType.sans(
                            size: 13,
                            weight: FontWeight.w600,
                            color: _testing ? sc.textLo : sc.accent)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: canSave
                    ? () => Navigator.of(context).maybePop()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: sc.accent,
                  foregroundColor: sc.accentInk,
                  disabledBackgroundColor: sc.bg3,
                  disabledForegroundColor: sc.textLo,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Simpan & sambungkan',
                    style: SatType.sans(
                        size: 15, weight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final hasError = errorText != null;
    final borderColor = hasError ? sc.urgent : sc.border0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: SatType.mono(
                size: 10,
                weight: FontWeight.w500,
                letterSpacing: 1.2,
                color: sc.textLo)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          style: SatType.sans(size: 15, color: sc.textHi),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: SatType.sans(size: 15, color: sc.textLo),
            filled: true,
            fillColor: sc.bg2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: hasError ? sc.urgent : sc.accent),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 12, color: sc.urgent),
                const SizedBox(width: 6),
                Text(errorText!,
                    style: SatType.sans(
                        size: 12,
                        weight: FontWeight.w500,
                        color: sc.urgent)),
              ],
            ),
          ),
      ],
    );
  }
}

class _QrScanSheet extends StatefulWidget {
  const _QrScanSheet();

  @override
  State<_QrScanSheet> createState() => _QrScanSheetState();
}

class _QrScanSheetState extends State<_QrScanSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return _SheetShell(
      title: 'Pindai QR server',
      sub: 'Arahkan kamera ke QR yang tampil di layar admin server.',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [Color(0xFF1A1410), Color(0xFF000000)],
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: SizedBox(
                        width: 220,
                        height: 220,
                        child: Stack(
                          children: [
                            _corner(Alignment.topLeft, sc),
                            _corner(Alignment.topRight, sc),
                            _corner(Alignment.bottomLeft, sc),
                            _corner(Alignment.bottomRight, sc),
                            AnimatedBuilder(
                              animation: _ctrl,
                              builder: (_, _) => Positioned(
                                left: 0,
                                right: 0,
                                top: 220 * _ctrl.value,
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: sc.accent,
                                    boxShadow: [
                                      BoxShadow(
                                          color: sc.accent.withValues(alpha: 0.6),
                                          blurRadius: 10),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 14,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('MENCARI QR · LAN',
                              style: SatType.mono(
                                size: 10,
                                color: Colors.white.withValues(alpha: 0.7),
                                letterSpacing: 0.8,
                              )),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: sc.bg2,
                border: Border.all(color: sc.border0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, size: 16, color: sc.textMd),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Terakhir dipindai',
                            style: SatType.sans(
                                size: 13,
                                weight: FontWeight.w600,
                                color: sc.textHi)),
                        const SizedBox(height: 2),
                        Text('Warung Sebelah · 192.168.4.21 · 2 jam lalu',
                            style: SatType.mono(
                                size: 10,
                                color: sc.textLo,
                                letterSpacing: 0.4)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text('Gunakan',
                        style: SatType.sans(
                            size: 13,
                            weight: FontWeight.w600,
                            color: sc.accent)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(Icons.flashlight_on_outlined,
                    size: 18, color: sc.textHi),
                label: Text('Senter',
                    style: SatType.sans(
                        size: 14,
                        weight: FontWeight.w600,
                        color: sc.textHi)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: sc.border2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _corner(Alignment a, SatColors sc) {
    const t = 3.0;
    const len = 28.0;
    final isTop = a.y < 0;
    final isLeft = a.x < 0;
    return Align(
      alignment: a,
      child: SizedBox(
        width: len,
        height: len,
        child: Stack(
          children: [
            Positioned(
              top: isTop ? 0 : null,
              bottom: isTop ? null : 0,
              left: isLeft ? 0 : null,
              right: isLeft ? null : 0,
              child: Container(width: len, height: t, color: sc.accent),
            ),
            Positioned(
              top: isTop ? 0 : null,
              bottom: isTop ? null : 0,
              left: isLeft ? 0 : null,
              right: isLeft ? null : 0,
              child: Container(width: t, height: len, color: sc.accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinHelper extends StatelessWidget {
  final int pinLength;
  final int max;
  const _PinHelper({required this.pinLength, required this.max});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final empty = pinLength == 0;
    final complete = pinLength >= max;
    final text = complete
        ? 'Memverifikasi...'
        : empty
            ? 'Masukkan $max digit PIN'
            : '$pinLength / $max digit';
    final color = complete ? sc.accent : sc.textLo;
    return Center(
      child: Text(text,
          style: SatType.mono(
              size: 11, color: color, letterSpacing: 0.6)),
    );
  }
}

class _PinKey extends StatelessWidget {
  final String label;
  final bool tablet;
  final VoidCallback onTap;
  const _PinKey({required this.label, required this.tablet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final muted = label == 'del';
    return Material(
      color: muted ? Colors.transparent : sc.bg2,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          alignment: Alignment.center,
          child: muted
              ? Icon(Icons.backspace_outlined, color: sc.textMd, size: tablet ? 26 : 22)
              : Text(label,
                  style: SatType.mono(
                    size: tablet ? 32 : 26,
                    weight: FontWeight.w500,
                    letterSpacing: 0,
                    color: sc.textHi,
                  )),
        ),
      ),
    );
  }
}
