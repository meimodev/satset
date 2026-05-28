import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/pin_sheet.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/ui/features/auth/view_models/pin_view_model.dart';

const _kEnterDur = Duration(milliseconds: 480);
const _kMicroDur = Duration(milliseconds: 200);
const _kPanelDur = Duration(milliseconds: 280);
const _kEnterCurve = Curves.easeOutQuart;
const _kPanelCurve = Curves.easeOutQuint;

Duration _d(BuildContext c, Duration d) =>
    MediaQuery.disableAnimationsOf(c) ? Duration.zero : d;

const _kStaffDebugCreds = PinDebugCreds([
  (pin: '100000', name: 'Pak Nyoman', role: 'Owner'),
  (pin: '100001', name: 'Maya', role: 'Waiter'),
  (pin: '100002', name: 'Budi', role: 'Waiter'),
  (pin: '100003', name: 'Rina', role: 'Waiter'),
  (pin: '100004', name: 'Komang', role: 'Kitchen'),
]);

class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen>
    with TickerProviderStateMixin {
  final _adminEmail = TextEditingController(text: 'admin@warungsebelah.id');
  final _adminPassword = TextEditingController();
  bool _showAdminPw = false;
  bool _serverEditing = false;
  bool _sheetOpen = false;
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

  Future<void> _signInAdmin() async {
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
    final ok = await ref.read(pinViewModelProvider.notifier).submitAdmin(
          email: _adminEmail.text.trim(),
          password: _adminPassword.text,
        );
    if (!mounted) return;
    if (ok) context.go('/venue');
  }

  Future<void> _openPinSheet(PairedServerInfo server) async {
    if (_sheetOpen) return;
    _sheetOpen = true;
    final ok = await showPinSheet(
      context,
      title: 'Masukkan PIN',
      subtitle: 'Tersambung ke ${server.label}',
      onSubmit: (pin) =>
          ref.read(pinViewModelProvider.notifier).verifyPin(pin),
      debugCreds: kDebugMode ? _kStaffDebugCreds : null,
    );
    _sheetOpen = false;
    if (!mounted) return;
    if (ok == true) {
      context.go('/tables');
    } else {
      // Dismissed without success — flip back to server-edit so user can pick
      // a different server or retry.
      setState(() => _serverEditing = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l = context.layout;
    final prefs = ref.watch(prefsServiceProvider);
    if (!prefs.hasValue) {
      return Scaffold(
        backgroundColor: sc.bg0,
        body: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2, color: sc.accent),
          ),
        ),
      );
    }
    final state = ref.watch(pinViewModelProvider);

    ref.listen<PinState>(pinViewModelProvider, (prev, next) {
      final wasPaired = prev?.selectedServer?.paired ?? false;
      final isPaired = next.selectedServer?.paired ?? false;
      if (!wasPaired && isPaired) {
        if (_serverEditing) {
          setState(() => _serverEditing = false);
        }
        if (next.mode == SignInMode.staff && !_sheetOpen) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _openPinSheet(next.selectedServer!);
          });
        }
      }
    });

    final staffConnected = state.mode == SignInMode.staff &&
        (state.selectedServer?.paired ?? false);
    final staffEditing =
        state.mode == SignInMode.staff && (_serverEditing || !staffConnected);
    final showModeSwitcher =
        state.mode == SignInMode.admin || staffEditing;

    final modeSwitcher = _ModeSwitcher(
      mode: state.mode,
      onChange: (m) {
        if (m == SignInMode.staff) {
          setState(() => _serverEditing = false);
        }
        ref.read(pinViewModelProvider.notifier).setMode(m);
      },
    );
    final serverPanel = state.mode != SignInMode.staff
        ? const SizedBox.shrink()
        : staffEditing
            ? _ServerList(
                servers: state.servers,
                selectedKey: state.selectedServerKey,
                pairingBusy: state.pairingBusy,
                pairingError: state.pairingError,
                onSelect: (k) => ref
                    .read(pinViewModelProvider.notifier)
                    .selectServer(k),
                onAutoClaim: (s) => ref
                    .read(pinViewModelProvider.notifier)
                    .selectDiscovered(s),
              )
            : _ConnectedServerCard(
                server: state.selectedServer!,
                onEdit: () => setState(() => _serverEditing = true),
                onReenterPin: () => _openPinSheet(state.selectedServer!),
              );

    if (l.useTabletShell) {
      // Tablet: left = brand + mode switch + server panel. Right = admin form
      // (admin mode only). Staff PIN entry lives in the bottom sheet.
      final rightCol = state.mode == SignInMode.admin
          ? Container(
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
                      _Reveal(
                        delay: const Duration(milliseconds: 120),
                        child: _ModeHeading(
                          mode: state.mode,
                          server: state.selectedServer,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _Reveal(
                        delay: const Duration(milliseconds: 180),
                        child: _AdminAuthForm(
                          email: _adminEmail,
                          password: _adminPassword,
                          showPassword: _showAdminPw,
                          onToggleShow: () =>
                              setState(() => _showAdminPw = !_showAdminPw),
                          onSubmit: _signInAdmin,
                          emailError: _emailError,
                          passwordError: _passwordError,
                          busy: state.adminBusy,
                          serverError: state.adminError,
                        ),
                      ),
                      _Reveal(
                        delay: const Duration(milliseconds: 260),
                        child: _AdminDebugCredsButton(),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink();
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
                      _Reveal(child: _TabletBrand()),
                      const SizedBox(height: 48),
                      _Reveal(
                        delay: const Duration(milliseconds: 80),
                        child: AnimatedSize(
                          duration: _d(context, _kPanelDur),
                          curve: _kPanelCurve,
                          alignment: Alignment.topCenter,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showModeSwitcher) modeSwitcher,
                              if (state.mode == SignInMode.staff) ...[
                                SizedBox(height: showModeSwitcher ? 18 : 0),
                                _SwapBody(
                                  switchKey: staffEditing
                                      ? 'server-list'
                                      : 'server-connected',
                                  child: serverPanel,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            rightCol,
          ],
        ),
      );
    }

    final brand = _Brand();
    final modeHeading = _ModeHeading(
      mode: state.mode,
      server: state.selectedServer,
    );
    final adminForm = _AdminAuthForm(
      email: _adminEmail,
      password: _adminPassword,
      showPassword: _showAdminPw,
      onToggleShow: () => setState(() => _showAdminPw = !_showAdminPw),
      onSubmit: _signInAdmin,
      emailError: _emailError,
      passwordError: _passwordError,
      busy: state.adminBusy,
      serverError: state.adminError,
    );
    final authBody = state.mode == SignInMode.staff
        ? const SizedBox.shrink()
        : adminForm;

    final twoCol = l.isLandscape && l.size.width >= 720;
    final swapKey = state.mode == SignInMode.admin ? 'admin' : 'staff';

    final modeBlock = AnimatedSize(
      duration: _d(context, _kPanelDur),
      curve: _kPanelCurve,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showModeSwitcher) modeSwitcher,
          if (state.mode == SignInMode.staff) ...[
            SizedBox(height: showModeSwitcher ? 14 : 0),
            _SwapBody(
              switchKey: staffEditing ? 'server-list' : 'server-connected',
              child: serverPanel,
            ),
          ],
        ],
      ),
    );

    final wrappedAuthBody = _SwapBody(switchKey: swapKey, child: authBody);

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
                              _Reveal(child: brand),
                              const SizedBox(height: 36),
                              _Reveal(
                                delay: const Duration(milliseconds: 80),
                                child: modeBlock,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 48),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (state.mode == SignInMode.admin) ...[
                                _Reveal(
                                  delay: const Duration(milliseconds: 120),
                                  child: modeHeading,
                                ),
                                const SizedBox(height: 22),
                                _Reveal(
                                  delay: const Duration(milliseconds: 180),
                                  child: wrappedAuthBody,
                                ),
                                _Reveal(
                                  delay: const Duration(milliseconds: 260),
                                  child: _AdminDebugCredsButton(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        _Reveal(child: brand),
                        const SizedBox(height: 36),
                        _Reveal(
                          delay: const Duration(milliseconds: 80),
                          child: modeBlock,
                        ),
                        const SizedBox(height: 26),
                        if (state.mode == SignInMode.admin) ...[
                          _Reveal(
                            delay: const Duration(milliseconds: 140),
                            child: modeHeading,
                          ),
                          const SizedBox(height: 18),
                          _Reveal(
                            delay: const Duration(milliseconds: 200),
                            child: wrappedAuthBody,
                          ),
                          _Reveal(
                            delay: const Duration(milliseconds: 280),
                            child: _AdminDebugCredsButton(),
                          ),
                        ],
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
  final SignInMode mode;
  final PairedServerInfo? server;
  const _ModeHeading({required this.mode, required this.server});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final isAdmin = mode == SignInMode.admin;
    final label = isAdmin ? 'MODE ADMIN' : 'MODE STAFF';
    final title = isAdmin ? 'Masuk admin' : 'Masukkan PIN';
    final sub = isAdmin
        ? 'Login dengan email & kata sandi'
        : server != null
            ? 'Tersambung ke ${server!.label}'
            : 'Pilih server lebih dulu';
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
  final bool busy;
  final String? serverError;
  const _AdminAuthForm({
    required this.email,
    required this.password,
    required this.showPassword,
    required this.onToggleShow,
    required this.onSubmit,
    this.emailError,
    this.passwordError,
    this.busy = false,
    this.serverError,
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
            onPressed: busy ? null : onSubmit,
            icon: busy
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: sc.accentInk),
                  )
                : Icon(Icons.shield_moon_outlined,
                    size: 18, color: sc.accentInk),
            label: Text(busy ? 'Memuat...' : 'Masuk sebagai admin',
                style: SatType.sans(
                    size: 15,
                    weight: FontWeight.w600,
                    color: sc.accentInk)),
            style: ElevatedButton.styleFrom(
              backgroundColor: sc.accent,
              foregroundColor: sc.accentInk,
              disabledBackgroundColor: sc.accent.withValues(alpha: 0.7),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        if (serverError != null) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 12, color: sc.urgent),
              const SizedBox(width: 6),
              Flexible(
                child: Text(serverError!,
                    textAlign: TextAlign.center,
                    style: SatType.sans(
                        size: 12,
                        weight: FontWeight.w500,
                        color: sc.urgent)),
              ),
            ],
          ),
        ],
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
  final SignInMode mode;
  final ValueChanged<SignInMode> onChange;
  const _ModeSwitcher({required this.mode, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final isAdmin = mode == SignInMode.admin;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: sc.bg2,
        border: Border.all(color: sc.border0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pillW = (constraints.maxWidth - 4) / 2;
          return Stack(
            children: [
              AnimatedAlign(
                alignment:
                    isAdmin ? Alignment.centerLeft : Alignment.centerRight,
                duration: _d(context, _kPanelDur),
                curve: _kPanelCurve,
                child: Container(
                  width: pillW,
                  height: 52,
                  decoration: BoxDecoration(
                    color: sc.accentSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _modeTab(
                      context,
                      sc,
                      icon: Icons.shield_moon_outlined,
                      label: 'Admin',
                      sub: 'Server lokal',
                      active: isAdmin,
                      onTap: () => onChange(SignInMode.admin),
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
                      active: !isAdmin,
                      onTap: () => onChange(SignInMode.staff),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(end: active ? 1.0 : 0.0),
              duration: _d(context, _kMicroDur),
              curve: Curves.easeOutQuart,
              builder: (context, t, _) => Icon(
                icon,
                size: 18,
                color: Color.lerp(sc.textMd, sc.accent, t),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: active ? 1.0 : 0.0),
                    duration: _d(context, _kMicroDur),
                    curve: Curves.easeOutQuart,
                    builder: (context, t, _) => Text(label,
                        style: SatType.sans(
                          size: 14,
                          weight: FontWeight.w600,
                          letterSpacing: -0.14,
                          color: Color.lerp(sc.textMd, sc.textHi, t),
                        )),
                  ),
                  const SizedBox(height: 1),
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: active ? 1.0 : 0.0),
                    duration: _d(context, _kMicroDur),
                    curve: Curves.easeOutQuart,
                    builder: (context, t, _) => Text(sub,
                        style: SatType.mono(
                          size: 10,
                          color: Color.lerp(sc.textLo, sc.accent, t),
                          letterSpacing: 0.4,
                        )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServerList extends ConsumerWidget {
  final List<PairedServerInfo> servers;
  final String? selectedKey;
  final bool pairingBusy;
  final String? pairingError;
  final ValueChanged<String> onSelect;
  final Future<bool> Function(PairedServerInfo) onAutoClaim;
  const _ServerList({
    required this.servers,
    required this.selectedKey,
    required this.pairingBusy,
    required this.pairingError,
    required this.onSelect,
    required this.onAutoClaim,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final pairedCount = servers.where((s) => s.paired).length;
    final discoveredCount = servers.length - pairedCount;
    final counterText = discoveredCount > 0
        ? '$pairedCount TERPASANG · $discoveredCount LAN'
        : '$pairedCount TERPASANG';
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
              Text(counterText,
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
          child: servers.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    'Mencari server di jaringan… atau pasangkan manual lewat QR.',
                    style: SatType.sans(size: 13, color: sc.textMd),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < servers.length; i++) ...[
                      _ServerRow(
                        server: servers[i],
                        selected: servers[i].key == selectedKey,
                        busy: pairingBusy && servers[i].key == selectedKey,
                        onTap: servers[i].paired
                            ? () => onSelect(servers[i].key)
                            : () => onAutoClaim(servers[i]),
                      ),
                      if (i != servers.length - 1)
                        Divider(height: 1, color: sc.border0),
                    ],
                  ],
                ),
        ),
        if (pairingError != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.error_outline, size: 12, color: sc.urgent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(pairingError!,
                    style: SatType.sans(
                        size: 12,
                        weight: FontWeight.w500,
                        color: sc.urgent)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ServerRow extends StatelessWidget {
  final PairedServerInfo server;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;
  const _ServerRow({
    required this.server,
    required this.selected,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final dotColor = server.paired ? sc.success : sc.accent;
    final dotShadow = server.paired ? sc.successSoft : sc.accentSoft;
    return AnimatedContainer(
      duration: _d(context, _kMicroDur),
      curve: Curves.easeOutQuart,
      color: selected ? sc.accentSoft : Colors.transparent,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
        onTap: busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              _PulseDot(color: dotColor, glow: dotShadow),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(server.label,
                              overflow: TextOverflow.ellipsis,
                              style: SatType.sans(
                                size: 14,
                                weight: FontWeight.w500,
                                letterSpacing: -0.14,
                                color: sc.textHi,
                              )),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: server.paired
                                ? sc.successSoft
                                : sc.accentSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            server.paired ? 'TERPASANG' : 'LAN',
                            style: SatType.mono(
                              size: 9,
                              weight: FontWeight.w600,
                              letterSpacing: 1.0,
                              color: server.paired ? sc.success : sc.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      server.version == null
                          ? server.ipLine
                          : '${server.ipLine} · v${server.version}',
                      style: SatType.mono(
                        size: 10,
                        color: sc.textLo,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (busy)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: sc.accent),
                )
              else if (selected && server.paired)
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
              else if (!server.paired)
                Icon(Icons.wifi_tethering_rounded,
                    size: 18, color: sc.accent)
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

// Keep `authStateProvider` import alive — surfacing auth busy/error on the
// pad area is delegated to PinViewModel which forwards into PinState.
// ignore: unused_element
void _retain(WidgetRef ref) => ref.read(authStateProvider);

/// Debug-only button surfacing seeded admin credentials. Staff PIN creds live
/// inside the PIN sheet (see `_kStaffDebugCreds`).
class _AdminDebugCredsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Center(
        child: TextButton.icon(
          onPressed: () => _showAdminDebugCreds(context),
          style: TextButton.styleFrom(
            foregroundColor: sc.warn,
            backgroundColor: sc.warnSoft,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: BorderSide(color: sc.warn.withValues(alpha: 0.4)),
            ),
          ),
          icon: Icon(Icons.bug_report_outlined, size: 14, color: sc.warn),
          label: Text('DEBUG · SEEDED CREDS',
              style: SatType.mono(
                size: 10,
                weight: FontWeight.w600,
                letterSpacing: 1.2,
                color: sc.warn,
              )),
        ),
      ),
    );
  }

  static void _showAdminDebugCreds(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final sc = ctx.sat;
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sc.bg1,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sc.border0),
            ),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bug_report_outlined, size: 14, color: sc.warn),
                    const SizedBox(width: 6),
                    Text('DEBUG · SEEDED ADMIN',
                        style: SatType.mono(
                          size: 10,
                          weight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: sc.warn,
                        )),
                  ],
                ),
                const SizedBox(height: 8),
                _DebugCredRow(label: 'EMAIL', value: 'admin@satset.local'),
                const SizedBox(height: 4),
                _DebugCredRow(label: 'PASS', value: 'admin123'),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ConnectedServerCard extends StatelessWidget {
  final PairedServerInfo server;
  final VoidCallback onEdit;
  final VoidCallback onReenterPin;
  const _ConnectedServerCard({
    required this.server,
    required this.onEdit,
    required this.onReenterPin,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text('SERVER TERSAMBUNG',
              style: SatType.mono(
                size: 10,
                weight: FontWeight.w500,
                letterSpacing: 1.2,
                color: sc.textLo,
              )),
        ),
        Material(
          color: sc.bg2,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onReenterPin,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: sc.border0),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sc.success,
                      boxShadow: [
                        BoxShadow(color: sc.successSoft, spreadRadius: 3),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                server.label,
                                overflow: TextOverflow.ellipsis,
                                style: SatType.sans(
                                  size: 14,
                                  weight: FontWeight.w500,
                                  letterSpacing: -0.14,
                                  color: sc.textHi,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: sc.accentSoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'STAFF',
                                style: SatType.mono(
                                  size: 9,
                                  weight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                  color: sc.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          server.version == null
                              ? server.ipLine
                              : '${server.ipLine} · v${server.version}',
                          style: SatType.mono(
                            size: 10,
                            color: sc.textLo,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onEdit,
                    tooltip: 'Ubah server',
                    icon: Icon(Icons.edit_outlined,
                        size: 18, color: sc.textMd),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'Ketuk kartu untuk masukkan PIN',
            style: SatType.mono(
              size: 10,
              color: sc.textLo,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ],
    );
  }
}

class _DebugCredRow extends StatelessWidget {
  final String label;
  final String value;
  const _DebugCredRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: label));
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text('Disalin: $label'),
            duration: const Duration(milliseconds: 800),
          ),
        );
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 76,
              child: Text(label,
                  style: SatType.mono(
                    size: 11,
                    weight: FontWeight.w700,
                    color: sc.textHi,
                  )),
            ),
            Expanded(
              child: Text(value,
                  style: SatType.sans(size: 11, color: sc.textMd)),
            ),
            Icon(Icons.copy_rounded, size: 12, color: sc.textLo),
          ],
        ),
      ),
    );
  }
}

class _Reveal extends StatefulWidget {
  final Duration delay;
  final Widget child;
  const _Reveal({this.delay = Duration.zero, required this.child});

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _kEnterDur);
    Future<void>.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _kEnterCurve.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 14),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  final Color glow;
  const _PulseDot({required this.color, required this.glow});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = reduce ? 0.5 : Curves.easeInOut.transform(_c.value);
        final spread = 2.0 + t * 2.5;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [BoxShadow(color: widget.glow, spreadRadius: spread)],
          ),
        );
      },
    );
  }
}

class _SwapBody extends StatelessWidget {
  final Widget child;
  final Object switchKey;
  const _SwapBody({required this.child, required this.switchKey});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: _d(context, _kPanelDur),
      curve: _kPanelCurve,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: _d(context, _kPanelDur),
        switchInCurve: _kPanelCurve,
        switchOutCurve: Curves.easeInQuart,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(switchKey), child: child),
      ),
    );
  }
}
