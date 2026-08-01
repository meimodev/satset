import 'dart:async';
import 'package:satset/ui/core/widgets/anim.dart';
import 'package:satset/ui/core/widgets/pulse_dot.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/ui/core/design/skin.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/data/services/firebase_admin_service.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/pin_sheet.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/ping_repository.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/ui/features/auth/view_models/pin_view_model.dart';
import 'package:satset/ui/features/auth/views/change_password_screen.dart';
import 'package:satset/ui/core/design/spacing.dart';

class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen>
    with TickerProviderStateMixin {
  final _adminEmail = TextEditingController();
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
    if (e.isEmpty) return 'Email belum diisi.';
    if (!_emailRegex.hasMatch(e)) return 'Email tidak valid.';
    return null;
  }

  String? _validatePassword(String v) {
    if (v.isEmpty) return 'Password belum diisi.';
    if (v.length < 6) return 'Minimal 6 karakter.';
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
    final ok = await ref
        .read(pinViewModelProvider.notifier)
        .submitAdmin(
          email: _adminEmail.text.trim(),
          password: _adminPassword.text,
        );
    if (!mounted) return;
    if (ok) {
      context.go('/venue');
      return;
    }
    // Not a failure: a temporary password was accepted and the gauntlet stopped
    // to collect a real one (ADR-0075). The Firebase session is still live so
    // the form below can authorize the change.
    final pending = ref.read(pendingPasswordChangeProvider);
    if (pending != null) await _changeTempPassword(pending);
  }

  /// Runs the forced change, then re-enters sign-in with the password the admin
  /// just chose. Re-entering rather than continuing from where the gauntlet
  /// stopped is deliberate: eligibility, the venue kill switch and the
  /// host-vs-client decision all still have to happen, and there is exactly one
  /// place that knows how to do them in the right order.
  Future<void> _changeTempPassword(PendingPasswordChange pending) async {
    final newPassword = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ChangePasswordScreen(
          pending: pending,
          tempPassword: _adminPassword.text,
        ),
        fullscreenDialog: true,
      ),
    );
    if (!mounted || newPassword == null) return;
    _adminPassword.text = newPassword;
    await _signInAdmin();
  }

  /// Hands the reset off to a human. See ADR-0059: there is no self-serve
  /// path any more, so this only has to get the address in front of the
  /// developer — `wa.me` is an https link, so it resolves to WhatsApp when
  /// installed and to the browser's "Continue to chat" page when not. No
  /// `canLaunchUrl` gate: on Android something always answers an https VIEW.
  Future<void> _forgotPassword() async {
    final emailErr = _validateEmail(_adminEmail.text);
    if (emailErr != null) {
      setState(() => _emailError = emailErr);
      return;
    }
    FocusScope.of(context).unfocus();
    final email = _adminEmail.text.trim();
    final uri = Uri.parse(
      'https://wa.me/${AppStrings.devWhatsApp}?text='
      '${Uri.encodeComponent(AppStrings.resetRequestMessage(email))}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.resetRequestFailed)),
      );
    }
  }

  Future<void> _openPinSheet(PairedServerInfo server) async {
    if (_sheetOpen) return;
    _sheetOpen = true;
    // Recheck reachability immediately on open so the status pill reflects the
    // live connection instead of a heartbeat sample up to 5s stale. Deferred a
    // frame so the sheet's pill is watching pingProvider (keeps it alive)
    // before the probe fires.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(ref.read(pingProvider.notifier).recheck());
    });
    final ok = await showPinSheet(
      context,
      title: 'Masukkan PIN',
      subtitle: 'Tersambung ke ${server.label}',
      statusSlot: const _ServerReachabilityPill(),
      onSubmit: (pin) => ref.read(pinViewModelProvider.notifier).verifyPin(pin),
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
    final body = _buildPin(context);
    if (!kDebugMode) return body;
    // Debug-only door into the widget book. PinScreen is the one surface
    // reachable before pairing, which is where the gallery is most useful.
    return Stack(
      children: [
        body,
        Positioned(
          left: Sp.s2,
          bottom: Sp.s2,
          child: SafeArea(
            child: SatButton.ghost(
              label: 'Widget book',
              onTap: () => context.push('/book'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPin(BuildContext context) {
    final sc = context.sat;
    final l = context.layout;
    final prefs = ref.watch(prefsServiceProvider);
    if (!prefs.hasValue) {
      return Scaffold(
        backgroundColor: sc.bg0,
        body: Center(
          child: SizedBox(
            width: Sp.s7,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: sc.accentText,
            ),
          ),
        ),
      );
    }
    final state = ref.watch(pinViewModelProvider);

    // A cached admin session blocked at cold boot (stale offline / ineligible)
    // surfaces under the admin form. Live sign-in errors take precedence.
    final adminServerError =
        state.adminError ?? _bootBlockText(ref.watch(adminBootBlockProvider));

    // Admin auto-login: while the boot-time session restore is in flight, mask
    // the sign-in form behind a loading screen so the form never flashes before
    // the router redirects an already-authenticated admin into the app.
    final restoring = ref.watch(authStateProvider.select((s) => s.restoring));
    if (state.mode == SignInMode.admin && restoring) {
      return const _RestoreLoadingScreen();
    }

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

    final staffConnected =
        state.mode == SignInMode.staff &&
        (state.selectedServer?.paired ?? false);
    final staffEditing =
        state.mode == SignInMode.staff && (_serverEditing || !staffConnected);
    final showModeSwitcher = state.mode == SignInMode.admin || staffEditing;

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
            onSelect: (k) =>
                ref.read(pinViewModelProvider.notifier).selectServer(k),
            onAutoClaim: (s) =>
                ref.read(pinViewModelProvider.notifier).selectDiscovered(s),
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
              decoration: SatBox.d(
                border: Border(left: SatB.side(color: sc.border0)),
              ),
              padding: const EdgeInsets.fromLTRB(48, 56, 48, 32),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Reveal(
                        index: 2,
                        child: _AdminAuthForm(
                          email: _adminEmail,
                          password: _adminPassword,
                          showPassword: _showAdminPw,
                          onToggleShow: () =>
                              setState(() => _showAdminPw = !_showAdminPw),
                          onSubmit: _signInAdmin,
                          onForgotPassword: _forgotPassword,
                          emailError: _emailError,
                          passwordError: _passwordError,
                          busy: state.adminBusy,
                          serverError: adminServerError,
                        ),
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
                      Reveal(child: _TabletBrand()),
                      const SizedBox(height: Sp.s12),
                      Reveal(
                        index: 1,
                        child: AnimatedSize(
                          duration: satMotion(context, 280),
                          curve: satEaseOut,
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
    final adminForm = _AdminAuthForm(
      email: _adminEmail,
      password: _adminPassword,
      showPassword: _showAdminPw,
      onToggleShow: () => setState(() => _showAdminPw = !_showAdminPw),
      onSubmit: _signInAdmin,
      onForgotPassword: _forgotPassword,
      emailError: _emailError,
      passwordError: _passwordError,
      busy: state.adminBusy,
      serverError: adminServerError,
    );
    final authBody = state.mode == SignInMode.staff
        ? const SizedBox.shrink()
        : adminForm;

    final twoCol = l.isLandscape && l.size.width >= 720;
    final swapKey = state.mode == SignInMode.admin ? 'admin' : 'staff';

    final modeBlock = AnimatedSize(
      duration: satMotion(context, 280),
      curve: satEaseOut,
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
                              Reveal(child: brand),
                              const SizedBox(height: Sp.s9),
                              Reveal(index: 1, child: modeBlock),
                            ],
                          ),
                        ),
                        const SizedBox(width: Sp.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (state.mode == SignInMode.admin)
                                Reveal(index: 2, child: wrappedAuthBody),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: Sp.s6),
                        Reveal(child: brand),
                        const SizedBox(height: Sp.s9),
                        Reveal(index: 1, child: modeBlock),
                        const SizedBox(height: Sp.s7),
                        if (state.mode == SignInMode.admin)
                          Reveal(index: 3, child: wrappedAuthBody),
                      ],
                    ),
            ),
          ),
        ),
      ),
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
  final VoidCallback onForgotPassword;
  const _AdminAuthForm({
    required this.email,
    required this.password,
    required this.showPassword,
    required this.onToggleShow,
    required this.onSubmit,
    required this.onForgotPassword,
    this.emailError,
    this.passwordError,
    this.busy = false,
    this.serverError,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final pwHasError = passwordError != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Field(
          label: 'Email',
          controller: email,
          hint: 'admin@warung.id',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          errorText: emailError,
        ),
        const SizedBox(height: Sp.s3h),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PASSWORD', style: SatType.monoS(color: sc.textLo)),
            const SizedBox(height: Sp.s1h),
            SatField.password(
              controller: password,
              hint: '••••••••',
              visible: showPassword,
              onToggle: onToggleShow,
              hasError: pwHasError,
              onSubmitted: (_) => onSubmit(),
            ),
            if (pwHasError)
              Padding(
                padding: const EdgeInsets.only(top: Sp.s1h, left: Sp.sHair),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 12, color: sc.urgent),
                    const SizedBox(width: Sp.s1h),
                    Text(
                      passwordError!,
                      style: SatType.bodyS(color: sc.urgent),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: Sp.s2),
        Align(
          alignment: Alignment.centerRight,
          child: SatButton.ghost(
            label: 'Lupa password?',
            size: SatButtonSize.sm,
            onTap: onForgotPassword,
          ),
        ),
        const SizedBox(height: Sp.s2),
        SizedBox(
          width: double.infinity,
          child: SatButton.primary(
            label: busy ? AppStrings.loading : 'Masuk sebagai admin',
            icon: Icons.shield_moon_outlined,
            busy: busy,
            size: SatButtonSize.lg,
            onTap: busy ? null : onSubmit,
          ),
        ),
        if (serverError != null) ...[
          const SizedBox(height: Sp.s2h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 12, color: sc.urgent),
              const SizedBox(width: Sp.s1h),
              Flexible(
                child: Text(
                  serverError!,
                  textAlign: TextAlign.center,
                  style: SatType.bodyS(color: sc.urgent),
                ),
              ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.all(Sp.s1),
      decoration: SatBox.d(
        color: sc.bg2,
        border: SatB.all(color: sc.border0),
        borderRadius: SatR.a(14),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pillW = (constraints.maxWidth - 4) / 2;
          return Stack(
            children: [
              AnimatedAlign(
                alignment: isAdmin
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                duration: satMotion(context, 280),
                curve: satEaseOut,
                child: Container(
                  width: pillW,
                  height: 52,
                  decoration: SatBox.d(
                    color: sc.accentSoft,
                    borderRadius: SatR.a(10),
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
                      active: isAdmin,
                      onTap: () => onChange(SignInMode.admin),
                    ),
                  ),
                  const SizedBox(width: Sp.s1),
                  Expanded(
                    child: _modeTab(
                      context,
                      sc,
                      icon: Icons.badge_outlined,
                      label: 'Staff',
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
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: SatR.a(10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(end: active ? 1.0 : 0.0),
              duration: satMotion(context, 200),
              curve: satEaseOut,
              builder: (context, t, _) => Icon(
                icon,
                size: 18,
                color: Color.lerp(sc.textMd, sc.accentText, t),
              ),
            ),
            const SizedBox(width: Sp.s2h),
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: active ? 1.0 : 0.0),
                duration: satMotion(context, 200),
                curve: satEaseOut,
                builder: (context, t, _) => Text(
                  label,
                  style: SatType.labelM(
                    color: Color.lerp(sc.textMd, sc.textHi, t),
                  ),
                ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: SatBox.d(
            color: sc.bg2,
            border: SatB.all(color: sc.border0),
            borderRadius: SatR.a(14),
          ),
          child: servers.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(Sp.s4h),
                  child: Text(
                    'Mencari server di jaringan… atau pasangkan manual lewat QR.',
                    style: SatType.bodyM(color: sc.textMd),
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
          const SizedBox(height: Sp.s2),
          Row(
            children: [
              Icon(Icons.error_outline, size: 12, color: sc.urgent),
              const SizedBox(width: Sp.s1h),
              Expanded(
                child: Text(
                  pairingError!,
                  style: SatType.bodyS(color: sc.urgent),
                ),
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
      duration: satMotion(context, 200),
      curve: satEaseOut,
      color: selected ? sc.accentSoft : Colors.transparent,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: busy ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                PulseDot(color: dotColor, glow: dotShadow, size: 8),
                const SizedBox(width: Sp.s3h),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.label,
                        overflow: TextOverflow.ellipsis,
                        style: SatType.bodyM(color: sc.textHi),
                      ),
                      const SizedBox(height: Sp.sHair),
                      Text(
                        server.version == null
                            ? server.ipLine
                            : '${server.ipLine} · v${server.version}',
                        style: SatType.monoS(color: sc.textLo),
                      ),
                    ],
                  ),
                ),
                if (busy)
                  SizedBox(
                    width: Sp.s6,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: sc.accentText,
                    ),
                  )
                else if (selected && server.paired)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: SatBox.d(
                      shape: BoxShape.circle,
                      color: sc.accent,
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.check, size: 14, color: sc.accentInk),
                  )
                else if (!server.paired)
                  Icon(
                    Icons.wifi_tethering_rounded,
                    size: 18,
                    color: sc.accentText,
                  )
                else
                  Container(
                    width: 22,
                    height: 22,
                    decoration: SatBox.d(
                      shape: BoxShape.circle,
                      border: SatB.all(color: sc.border2),
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

/// Full-screen loader shown to an auto-login admin while the boot-time session
/// restore runs, masking the sign-in form until the router redirects.
class _RestoreLoadingScreen extends StatelessWidget {
  const _RestoreLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Scaffold(
      backgroundColor: sc.bg0,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TabletBrand(),
              const SizedBox(height: Sp.s7),
              SizedBox(
                width: Sp.s6,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: sc.accentText,
                ),
              ),
              const SizedBox(height: Sp.s4),
              Text('Memeriksa sesi…', style: SatType.monoS(color: sc.textLo)),
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
          decoration: SatBox.d(color: sc.accent, borderRadius: SatR.a(8)),
          alignment: Alignment.center,
          child: Text('S', style: SatType.monoM(color: sc.accentInk)),
        ),
        const SizedBox(width: Sp.s2h),
        Text('satset', style: SatType.h3(color: sc.textHi)),
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
          decoration: SatBox.d(color: sc.accent, borderRadius: SatR.a(12)),
          alignment: Alignment.center,
          child: Text('S', style: SatType.monoL(color: sc.accentInk)),
        ),
        const SizedBox(width: Sp.s3),
        Text('satset', style: SatType.h2(color: sc.textHi)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: SatType.monoS(color: sc.textLo)),
        const SizedBox(height: Sp.s1h),
        SatField.text(controller: controller, hint: hint, hasError: hasError),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: Sp.s1h, left: Sp.sHair),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 12, color: sc.urgent),
                const SizedBox(width: Sp.s1h),
                Text(errorText!, style: SatType.bodyS(color: sc.urgent)),
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

/// Maps a cold-boot admin block code to user-facing copy. See ADR-0015.
String? _bootBlockText(String? code) => switch (code) {
  'stale' =>
    'Perlu koneksi internet untuk verifikasi admin. Sambungkan internet lalu masuk lagi.',
  'ineligible' => 'Akses admin dicabut. Hubungi pengelola.',
  'resetpending' => AppStrings.tempPasswordPending,
  _ => null,
};

/// Three-state reachability derived from the live `/healthz` heartbeat
/// ([pingProvider]) of the currently-published paired server. Debounced: a
/// single failed probe stays in the neutral "checking" state so a momentary
/// Wi-Fi blip doesn't flash "down" while the server is actually up.
({Color dot, Color glow, String label, bool offline}) _reachabilityVisual(
  PingState ping,
  SatColors sc,
) {
  if (ping.reachable) {
    final ms = (ping.latest ?? ping.p50)?.inMilliseconds;
    return (
      dot: sc.success,
      glow: sc.successSoft,
      label: ms == null ? 'Tersambung' : 'Tersambung · ${ms}ms',
      offline: false,
    );
  }
  if (ping.consecutiveFailures >= 2) {
    return (
      dot: sc.urgent,
      glow: sc.urgentSoft,
      label: 'Server tidak terjangkau',
      offline: true,
    );
  }
  return (
    dot: sc.warn,
    glow: sc.warnSoft,
    label: 'Memeriksa sambungan…',
    offline: false,
  );
}

/// Live reachability pill (dot + label) for the PIN sheet's status slot.
class _ServerReachabilityPill extends ConsumerWidget {
  const _ServerReachabilityPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final v = _reachabilityVisual(ref.watch(pingProvider), sc);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: SatBox.d(
            shape: BoxShape.circle,
            color: v.dot,
            boxShadow: [BoxShadow(color: v.glow, spreadRadius: 3)],
          ),
        ),
        const SizedBox(width: Sp.s2),
        Text(
          v.label,
          style: SatType.monoS(color: v.offline ? sc.urgent : sc.textMd),
        ),
      ],
    );
  }
}

class _ConnectedServerCard extends ConsumerWidget {
  final PairedServerInfo server;
  final VoidCallback onEdit;
  final VoidCallback onReenterPin;
  const _ConnectedServerCard({
    required this.server,
    required this.onEdit,
    required this.onReenterPin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final v = _reachabilityVisual(ref.watch(pingProvider), sc);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            'SERVER TERSAMBUNG',
            style: SatType.monoS(color: sc.textLo),
          ),
        ),
        Material(
          color: sc.bg2,
          borderRadius: SatR.a(14),
          child: InkWell(
            onTap: onReenterPin,
            borderRadius: SatR.a(14),
            child: Container(
              decoration: SatBox.d(
                border: SatB.all(color: sc.border0),
                borderRadius: SatR.a(14),
              ),
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: SatBox.d(
                      shape: BoxShape.circle,
                      color: v.dot,
                      boxShadow: [BoxShadow(color: v.glow, spreadRadius: 3)],
                    ),
                  ),
                  const SizedBox(width: Sp.s3h),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          server.label,
                          overflow: TextOverflow.ellipsis,
                          style: SatType.bodyM(color: sc.textHi),
                        ),
                        const SizedBox(height: Sp.sHair),
                        Text(
                          server.version == null
                              ? server.ipLine
                              : '${server.ipLine} · v${server.version}',
                          style: SatType.monoS(color: sc.textLo),
                        ),
                        const SizedBox(height: Sp.s1),
                        Text(
                          v.label,
                          style: SatType.monoS(
                            color: v.offline ? sc.urgent : sc.textMd,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onEdit,
                    tooltip: 'Ubah server',
                    icon: Icon(Icons.edit_outlined, size: 18, color: sc.textMd),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
      duration: satMotion(context, 280),
      curve: satEaseOut,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: satMotion(context, 280),
        switchInCurve: satEaseOut,
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
