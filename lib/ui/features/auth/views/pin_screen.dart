import 'dart:async';
import 'package:satset/ui/core/widgets/anim.dart';
import 'package:satset/ui/core/widgets/pulse_dot.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_inline_error.dart';
import 'package:satset/ui/core/widgets/sat_spinner.dart';
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
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/ping_repository.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/ui/features/auth/view_models/pin_view_model.dart';
import 'package:satset/ui/features/auth/views/change_password_screen.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/core/localization/admission_text.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/domain/models/admission.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/core/localization/dev_contact.dart';

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
  String? _emailError;
  String? _passwordError;

  /// The bounded password-change retry gave up: changed, re-entered, and the
  /// server still asks for a change. Cleared on the next submit.
  bool _admissionStuck = false;

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
    if (e.isEmpty) return context.l10n.pinErrEmailEmpty;
    if (!_emailRegex.hasMatch(e)) return context.l10n.pinErrEmailInvalid;
    return null;
  }

  String? _validatePassword(String v) {
    if (v.isEmpty) return context.l10n.pinErrPasswordEmpty;
    if (v.length < 6) return context.l10n.pinErrPasswordShort;
    return null;
  }

  /// Runs the admission, and at most **one** re-entry — the password change.
  ///
  /// Re-entering rather than continuing from where the admission stopped is
  /// deliberate: eligibility, the venue kill switch and the host decision all
  /// still have to happen, and exactly one place knows how to do them in the
  /// right order. The bound is what is new. This used to recurse through
  /// `_changeTempPassword`, so a Firestore cache still reporting
  /// `mustChangePassword` stacked change-password screens without limit. The
  /// re-entry also reads the profile `serverOnly`, so the flag it sees is the
  /// one the change just cleared.
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
    if (_admissionStuck) setState(() => _admissionStuck = false);

    for (var pass = 0; pass < 2; pass++) {
      final outcome = await ref
          .read(pinViewModelProvider.notifier)
          .submitAdmin(
            email: _adminEmail.text.trim(),
            password: _adminPassword.text,
            freshProfile: pass > 0,
          );
      if (!mounted) return;
      switch (outcome) {
        case AdmittedAsHost():
          context.go('/venue');
          return;
        // The router owns these two diverts — a super admin to `/fleet`, an
        // owner to `/owner` — and both fire off the auth state the admission
        // just set. Pushing from here would race it.
        case AdmittedAsSuper() || AdmittedAsOwner():
          return;
        case AdmissionNeedsNewPassword():
          if (pass > 0) {
            // Changed the password, came back, and the server still says a
            // change is due. Say so instead of looping — the operator can see
            // the form did its job and that something upstream disagrees.
            setState(() => _admissionStuck = true);
            return;
          }
          final newPassword = await _collectNewPassword(outcome);
          if (!mounted || newPassword == null) return;
          _adminPassword.text = newPassword;
        // Everything else is shown, not acted on: the outcome sits in
        // `PinState.admission` and the form renders its line (or its own screen,
        // for a host-occupied). Exhaustiveness lives in `admissionText`, which
        // is the one place that must name every outcome.
        case _:
          return;
      }
    }
  }

  void _cancelAdmin() {
    if (_admissionStuck) setState(() => _admissionStuck = false);
    ref.read(pinViewModelProvider.notifier).cancelAdmin();
  }

  Future<String?> _collectNewPassword(AdmissionNeedsNewPassword pending) =>
      // Not a go_router route on purpose: this is a modal continuation of a
      // sign-in that has no session yet, and giving it a location would make
      // the redirect ladder reason about a fifth pre-auth route. ADR-0078 is
      // the scar from exactly that.
      Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => ChangePasswordScreen(
            pending: pending,
            tempPassword: _adminPassword.text,
          ),
          fullscreenDialog: true,
        ),
      );

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
      'https://wa.me/$devWhatsApp?text='
      '${Uri.encodeComponent(context.l10n.resetRequestMessage(email))}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.resetRequestFailed)));
    }
  }

  Future<void> _openPinSheet(PairedServerInfo server) async {
    final vm = ref.read(pinViewModelProvider.notifier);
    if (ref.read(pinViewModelProvider).stage == StaffStage.enteringPin) return;
    vm.setStage(StaffStage.enteringPin);
    // Recheck reachability immediately on open so the status pill reflects the
    // live connection instead of a heartbeat sample up to 5s stale. Deferred a
    // frame so the sheet's pill is watching pingProvider (keeps it alive)
    // before the probe fires.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(ref.read(pingProvider.notifier).recheck());
    });
    bool? ok;
    try {
      ok = await showPinSheet(
        context,
        title: context.l10n.pinEnterPin,
        subtitle: context.l10n.pinConnectedTo(server.label),
        statusSlot: const _ServerReachabilityPill(),
        onSubmit: (pin) => vm.verifyPin(pin),
      );
    } finally {
      // Leaving the stage on `enteringPin` after a throw is what used to make
      // the pad unopenable for the rest of the session: the guard above saw a
      // sheet that was no longer on screen and refused to build another.
      if (ok != true) vm.setStage(StaffStage.pickingServer);
    }
    if (!mounted) return;
    if (ok == true) context.go('/tables');
  }

  /// Forget the pairing, behind a confirm — it drops a pairing that may well be
  /// working, and re-pairing needs the server in earshot.
  Future<void> _resetPairing() async {
    final confirmed = await showSatDialog<bool>(
      context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.pinResetPairingTitle),
        content: Text(context.l10n.pinResetPairingBody),
        actions: [
          SatButton.ghost(
            label: context.l10n.cancel,
            onTap: () => Navigator.of(context).pop(false),
          ),
          SatButton.danger(
            label: context.l10n.pinResetPairingConfirm,
            onTap: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await ref.read(pinViewModelProvider.notifier).resetPairing();
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
              label: context.l10n.pinWidgetBook,
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
        body: const Center(child: SatSpinner(size: SatSpinnerSize.md)),
      );
    }
    final state = ref.watch(pinViewModelProvider);

    // A cached admin session blocked at cold boot (stale offline / ineligible /
    // the server would not start) surfaces under the admin form. A live
    // admission outcome takes precedence, and the stuck retry beats both — it
    // is the most recent thing that happened.
    final adminServerError = _admissionStuck
        ? context.l10n.tempPasswordPending
        : admissionText(context.l10n, state.admission) ??
              _bootBlockText(context.l10n, ref.watch(adminBootBlockProvider));

    // Admin auto-login: while the boot-time session restore is in flight, mask
    // the sign-in form behind a loading screen so the form never flashes before
    // the router redirects an already-authenticated admin into the app.
    final restoring = ref.watch(authStateProvider.select((s) => s.restoring));
    if (state.mode == SignInMode.admin && restoring) {
      return const _RestoreLoadingScreen();
    }

    // Signed in at Firebase, refused the venue: another device already hosts it
    // (ADR-0077). Takes the whole screen rather than sitting under the form —
    // the form is not the next action, and leaving it there invites a retype of
    // a password that was never wrong.
    final admission = state.admission;
    if (admission is AdmissionHostOccupied) {
      return _HostOccupiedScreen(
        hostLabel: admission.hostLabel,
        busy: state.adminBusy,
        onRetry: _signInAdmin,
        onSignOut: () async {
          await ref.read(authStateProvider.notifier).abandonHostOccupied();
          ref.read(pinViewModelProvider.notifier).clearAdmission();
        },
      );
    }

    // The pad opens on the edge into `connected`, not on the level: the
    // view-model owns the stage, so this only has to notice the transition.
    ref.listen<PinState>(pinViewModelProvider, (prev, next) {
      final becameConnected =
          prev?.stage != StaffStage.connected &&
          next.stage == StaffStage.connected;
      if (becameConnected && next.mode == SignInMode.staff) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final server = next.selectedServer;
          if (server != null) _openPinSheet(server);
        });
      }
    });

    final staffEditing =
        state.mode == SignInMode.staff &&
        state.stage == StaffStage.pickingServer;
    final showModeSwitcher = state.mode == SignInMode.admin || staffEditing;

    final modeSwitcher = _ModeSwitcher(
      mode: state.mode,
      onChange: ref.read(pinViewModelProvider.notifier).setMode,
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
            onEdit: () => ref
                .read(pinViewModelProvider.notifier)
                .setStage(StaffStage.pickingServer),
            onReenterPin: () => _openPinSheet(state.selectedServer!),
            onResetPairing: _resetPairing,
          );

    if (l.useTabletShell) {
      // Tablet: left = brand + mode switch + server panel. Right = admin form
      // (admin mode only). Staff PIN entry lives in the bottom sheet.
      final rightCol = state.mode == SignInMode.admin
          ? Container(
              width: SatSize.authPanel,
              decoration: SatBox.d(
                border: Border(left: SatB.side(color: sc.border0)),
              ),
              padding: const EdgeInsets.fromLTRB(
                Sp.s12,
                SatSize.authPanelInset,
                Sp.s12,
                Sp.s8,
              ),
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
                          onCancel: _cancelAdmin,
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
                padding: const EdgeInsets.fromLTRB(
                  SatSize.authPanelInset,
                  SatSize.authPanelInset,
                  SatSize.authPanelInset,
                  Sp.s8,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Reveal(child: const _Brand(large: true)),
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

    final brand = const _Brand();
    final adminForm = _AdminAuthForm(
      email: _adminEmail,
      password: _adminPassword,
      showPassword: _showAdminPw,
      onToggleShow: () => setState(() => _showAdminPw = !_showAdminPw),
      onSubmit: _signInAdmin,
      onCancel: _cancelAdmin,
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
              padding: const EdgeInsets.fromLTRB(Sp.s8, Sp.s6, Sp.s8, Sp.s8),
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

  /// Only reachable while [busy]. Firebase's sign-in future cannot be
  /// cancelled, so this stops us waiting rather than stopping the work — see
  /// `AuthRepository.cancelAdmission`. It exists because the admin standing in
  /// front of a venue with no WAN knows the network is dead well before any
  /// deadline of ours expires.
  final VoidCallback onCancel;
  const _AdminAuthForm({
    required this.email,
    required this.password,
    required this.showPassword,
    required this.onToggleShow,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onCancel,
    this.emailError,
    this.passwordError,
    this.busy = false,
    this.serverError,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Field(
          label: context.l10n.pinEmail,
          controller: email,
          hint: context.l10n.pinEmailHint,
          keyboard: TextInputType.emailAddress,
          errorText: emailError,
        ),
        const SizedBox(height: Sp.s3h),
        _Field(
          label: context.l10n.pinPassword,
          controller: password,
          // No hint. A row of bullets is what a *filled* password field looks
          // like, so a bulleted placeholder reads as "already typed" — which
          // is the one thing this field must never be ambiguous about.
          hint: '',
          errorText: passwordError,
          visible: showPassword,
          onToggleVisible: onToggleShow,
          onSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: Sp.s2),
        Align(
          alignment: Alignment.centerRight,
          child: SatButton.ghost(
            label: context.l10n.pinForgotPassword,
            size: SatButtonSize.sm,
            onTap: onForgotPassword,
          ),
        ),
        const SizedBox(height: Sp.s2),
        SizedBox(
          width: double.infinity,
          child: SatButton.primary(
            label: busy ? context.l10n.loading : context.l10n.pinSignInAsAdmin,
            icon: Icons.shield_moon_outlined,
            busy: busy,
            size: SatButtonSize.lg,
            onTap: busy ? null : onSubmit,
          ),
        ),
        if (busy) ...[
          const SizedBox(height: Sp.s2),
          Align(
            alignment: Alignment.center,
            child: SatButton.ghost(
              label: context.l10n.admissionCancel,
              size: SatButtonSize.sm,
              onTap: onCancel,
            ),
          ),
        ],
        if (serverError != null) ...[
          const SizedBox(height: Sp.s2h),
          SatInlineError(serverError!, center: true),
        ],
      ],
    );
  }
}

/// Half the switcher's inner width, less the [Sp.s1] gutter between the two
/// tabs — the travel distance of the sliding pill behind them.
///
/// Clamped at zero because [LayoutBuilder] hands out `maxWidth: 0` on the frame
/// before the parent has been laid out (the renderer logs `Width is zero. 0,0`
/// three times on this screen's first build), and `(0 - 4) / 2` is `-2.0`,
/// which `Container` rejects outright:
/// `BoxConstraints has a negative minimum width`. The screen recovered on the
/// next frame, so the only symptom was an assertion in every debug boot —
/// noise that trains you to scroll past the log where a real error will land.
@visibleForTesting
double modeSwitcherPillWidth(double maxWidth) =>
    ((maxWidth - Sp.s1) / 2).clamp(0.0, double.infinity);

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
          final pillW = modeSwitcherPillWidth(constraints.maxWidth);
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
                  height: SatSize.control,
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
                      label: context.l10n.pinModeAdmin,
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
                      label: context.l10n.pinModeStaff,
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
        padding: const EdgeInsets.symmetric(
          horizontal: Sp.s3h,
          vertical: Sp.s3,
        ),
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
                  child: Column(
                    children: [
                      // mDNS browsing is deliberately unbounded — the server
                      // tablet may not be switched on yet — so the spinner is
                      // the only thing separating "still looking" from "gave
                      // up". The ellipsis in the copy cannot carry that alone.
                      const SatSpinner(size: SatSpinnerSize.sm),
                      const SizedBox(height: Sp.s3),
                      Text(
                        context.l10n.pinSearchingServers,
                        style: SatType.bodyM(color: sc.textMd),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: Sp.s3),
                      SatButton.ghost(
                        label: context.l10n.pinManualConnectBtn,
                        icon: Icons.settings_ethernet,
                        size: SatButtonSize.sm,
                        onTap: () => _showManualAddressDialog(context),
                      ),
                    ],
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
        if (servers.isNotEmpty) ...[
          const SizedBox(height: Sp.s2),
          Align(
            alignment: Alignment.centerRight,
            child: SatButton.ghost(
              label: context.l10n.pinManualConnectBtn,
              icon: Icons.settings_ethernet,
              size: SatButtonSize.sm,
              onTap: () => _showManualAddressDialog(context),
            ),
          ),
        ],
        if (pairingError != null) ...[
          const SizedBox(height: Sp.s2),
          SatInlineError(pairingError!),
        ],
      ],
    );
  }

  void _showManualAddressDialog(BuildContext context) {
    showSatDialog<bool>(
      context,
      builder: (ctx) => const _ManualAddressDialog(),
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
            padding: const EdgeInsets.fromLTRB(Sp.s3h, Sp.s3, Sp.s3, Sp.s3),
            child: Row(
              children: [
                PulseDot(color: dotColor, glow: dotShadow, size: Sp.s2),
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
                  const SatSpinner()
                // `Sp.s6` and not the 22 that was here: this circle and the
                // spinner above occupy the same slot, and two logical pixels of
                // difference made the row twitch every time the state changed.
                else if (selected && server.paired)
                  Container(
                    width: Sp.s6,
                    height: Sp.s6,
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
                    width: Sp.s6,
                    height: Sp.s6,
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

/// Shown when admin sign-in passed Firebase but the venue already has a host on
/// the LAN (ADR-0077). A venue runs on one device; the second is refused rather
/// than admitted as a client.
///
/// Two causes land here and the copy carries both, because the device cannot
/// tell them apart: the ordinary one is another tablet still switched on, which
/// clears itself the moment it stops hosting — hence **Coba lagi** rather than a
/// forced sign-out. The other is a surplus admin account on a venue that
/// predates the cap, which no amount of retrying fixes and only the fleet
/// operator can resolve.
class _HostOccupiedScreen extends StatelessWidget {
  final String hostLabel;
  final bool busy;
  final VoidCallback onRetry;
  final VoidCallback onSignOut;
  const _HostOccupiedScreen({
    required this.hostLabel,
    required this.busy,
    required this.onRetry,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Scaffold(
      backgroundColor: sc.bg0,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Sp.s6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: SatSize.authPanelNarrow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.devices_other, size: 44, color: sc.warn),
                  const SizedBox(height: Sp.s4),
                  Text(
                    context.l10n.pinHostTakenTitle,
                    style: SatType.h2(color: sc.textHi),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Sp.s3),
                  // The device is named, not described: the operator is
                  // standing between both of them and needs to know which one
                  // to walk over to.
                  Text(
                    hostLabel,
                    style: SatType.monoM(color: sc.accentText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Sp.s3),
                  Text(
                    context.l10n.pinHostTakenBody,
                    style: SatType.bodyM(color: sc.textMd),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Sp.s2h),
                  Text(
                    context.l10n.pinHostTakenNote,
                    style: SatType.bodyS(color: sc.textLo),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Sp.s6),
                  SatButton.primary(
                    label: context.l10n.retry,
                    icon: Icons.refresh,
                    onTap: busy ? null : onRetry,
                  ),
                  const SizedBox(height: Sp.s2h),
                  SatButton.ghost(
                    label: context.l10n.pinSignOut,
                    onTap: busy ? null : onSignOut,
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
              const _Brand(large: true),
              const SizedBox(height: Sp.s7),
              const SatSpinner(),
              const SizedBox(height: Sp.s4),
              Text(
                context.l10n.pinCheckingSession,
                style: SatType.monoS(color: sc.textLo),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The wordmark. [large] is the tablet's — the same mark one notch up every
/// ramp, which is what two separate widgets were already trying to be before
/// their radii drifted apart. The mark now sits on the spacing scale (32 / 48);
/// the tablet's was 44, off-grid for no reason anyone recorded.
class _Brand extends StatelessWidget {
  final bool large;
  const _Brand({this.large = false});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final d = large ? Sp.s12 : Sp.s8;
    return Row(
      children: [
        Container(
          width: d,
          height: d,
          decoration: SatBox.d(
            color: sc.accent,
            borderRadius: SatR.a(large ? 12 : 8),
          ),
          alignment: Alignment.center,
          child: Text(
            'S',
            style: large
                ? SatType.monoL(color: sc.accentInk)
                : SatType.monoM(color: sc.accentInk),
          ),
        ),
        SizedBox(width: large ? Sp.s3 : Sp.s2h),
        Text(
          'satset',
          style: large
              ? SatType.h2(color: sc.textHi)
              : SatType.h3(color: sc.textHi),
        ),
      ],
    );
  }
}

/// The sign-in form's one field anatomy: caps label, red border on error, and
/// the error line under it.
///
/// The admin form built its email through this and hand-rolled its password
/// beside it — the same three parts, but one label in `monoS` and the other in
/// `caption`, and two different gaps under the two fields. The label now comes
/// from [SatField] itself, so there is one renderer rather than two that only
/// agreed by accident.
///
/// The error line is drawn here rather than passed as `errorText` on purpose:
/// [SatField] hands that to Material, which reserves the line whether or not
/// there is a message and prints it without the glyph the rest of the app uses.
class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? errorText;
  final TextInputType? keyboard;
  final ValueChanged<String>? onSubmitted;

  /// Non-null makes this the password variant — reveal eye, obscured unless
  /// [visible]. The parent owns the bit; see [SatField.password].
  final VoidCallback? onToggleVisible;
  final bool visible;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.errorText,
    this.keyboard,
    this.onSubmitted,
    this.onToggleVisible,
    this.visible = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onToggleVisible case final toggle?)
          SatField.password(
            controller: controller,
            label: label,
            hint: hint,
            hasError: hasError,
            visible: visible,
            onToggle: toggle,
            onSubmitted: onSubmitted,
          )
        else
          SatField.text(
            controller: controller,
            label: label,
            hint: hint,
            hasError: hasError,
            keyboard: keyboard,
            onSubmitted: onSubmitted,
            capitalization: TextCapitalization.none,
          ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: Sp.s1h, left: Sp.sHair),
            child: SatInlineError(errorText!),
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
String? _bootBlockText(AppL10n l10n, String? code) => switch (code) {
  'stale' => l10n.bootBlockStale,
  'ineligible' => l10n.bootBlockIneligible,
  'resetpending' => l10n.tempPasswordPending,
  'bootfailed' => l10n.bootBlockFailed,
  _ => null,
};

/// Three-state reachability derived from the live `/healthz` heartbeat
/// ([pingProvider]) of the currently-published paired server. Debounced: a
/// single failed probe stays in the neutral "checking" state so a momentary
/// Wi-Fi blip doesn't flash "down" while the server is actually up.
({Color dot, Color glow, String label, bool offline}) _reachabilityVisual(
  AppL10n l10n,
  PingState ping,
  SatColors sc,
) {
  if (ping.reachable) {
    final ms = (ping.latest ?? ping.p50)?.inMilliseconds;
    return (
      dot: sc.success,
      glow: sc.successSoft,
      label: ms == null ? l10n.pinReachConnected : l10n.pinReachConnectedMs(ms),
      offline: false,
    );
  }
  if (ping.consecutiveFailures >= 2) {
    return (
      dot: sc.urgent,
      glow: sc.urgentSoft,
      label: l10n.pinReachUnreachable,
      offline: true,
    );
  }
  return (
    dot: sc.warn,
    glow: sc.warnSoft,
    label: l10n.pinReachChecking,
    offline: false,
  );
}

/// Live reachability pill (dot + label) for the PIN sheet's status slot.
class _ServerReachabilityPill extends ConsumerWidget {
  const _ServerReachabilityPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final v = _reachabilityVisual(context.l10n, ref.watch(pingProvider), sc);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Not pulsing: reachability is a fact the ping already refreshes, and a
        // breathing dot is the app asking for attention it does not need.
        PulseDot(color: v.dot, glow: v.glow, pulse: false, size: Sp.s2),
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

  /// The way out of a pairing that cannot work. Deliberately the quietest thing
  /// on the card — it is the last resort, not a peer of "ganti server".
  final VoidCallback onResetPairing;
  const _ConnectedServerCard({
    required this.server,
    required this.onEdit,
    required this.onReenterPin,
    required this.onResetPairing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final v = _reachabilityVisual(context.l10n, ref.watch(pingProvider), sc);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: Sp.s1,
            right: Sp.s1,
            bottom: Sp.s2,
          ),
          child: Text(
            context.l10n.pinServerConnected,
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
              padding: const EdgeInsets.fromLTRB(Sp.s3h, Sp.s3, Sp.s2h, Sp.s3),
              child: Row(
                children: [
                  PulseDot(
                    color: v.dot,
                    glow: v.glow,
                    pulse: false,
                    size: Sp.s2,
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
                    tooltip: context.l10n.pinChangeServer,
                    icon: Icon(Icons.edit_outlined, size: 18, color: sc.textMd),
                  ),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: SatButton.ghost(
            label: context.l10n.pinResetPairing,
            size: SatButtonSize.sm,
            onTap: onResetPairing,
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

class _ManualAddressDialog extends ConsumerStatefulWidget {
  const _ManualAddressDialog();

  @override
  ConsumerState<_ManualAddressDialog> createState() =>
      _ManualAddressDialogState();
}

class _ManualAddressDialogState extends ConsumerState<_ManualAddressDialog> {
  final _controller = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.pinManualEntryTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.pinManualEntryDescription),
          const SizedBox(height: Sp.s4),
          SatField.text(
            controller: _controller,
            hint: '192.168.1.100:7443',
            label: context.l10n.pinManualEntryLabel,
            errorText: _error,
            enabled: !_busy,
            autofocus: true,
            onSubmitted: (_) => _onSubmit(),
          ),
        ],
      ),
      actions: [
        SatButton.ghost(
          label: context.l10n.cancel,
          onTap: _busy ? null : () => Navigator.of(context).pop(false),
        ),
        SatButton.primary(
          label: _busy
              ? context.l10n.loading
              : context.l10n.pinManualConnectBtn,
          busy: _busy,
          onTap: _busy ? null : _onSubmit,
        ),
      ],
    );
  }

  Future<void> _onSubmit() async {
    final address = _controller.text.trim();
    if (address.isEmpty) {
      setState(() => _error = context.l10n.pinManualEntryEmpty);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    final ok = await ref
        .read(pinViewModelProvider.notifier)
        .connectManualAddress(address);

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      final state = ref.read(pinViewModelProvider);
      setState(() {
        _busy = false;
        _error = state.pairingError ?? context.l10n.pinManualEntryNotFound;
      });
    }
  }
}
