import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/services/firebase_admin_service.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_card.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';

/// Where an admin holding a dictated temporary password sets a real one.
///
/// Opened by the PIN screen the moment [pendingPasswordChangeProvider] fills,
/// which happens inside the sign-in gauntlet *before* eligibility is read and
/// before any server boots (ADR-0075). So this screen sits on a Firebase session
/// that has proved the credential and bought nothing else — the only two ways
/// out are setting a new password or signing out.
///
/// Presented full-screen rather than as a dialog on purpose: a barrier the
/// operator can tap past is not the same as a step they have to complete, and
/// this one is the only thing standing between a password spoken over WhatsApp
/// and a running restaurant.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({
    super.key,
    required this.pending,
    required this.tempPassword,
  });

  final PendingPasswordChange pending;

  /// The code they just signed in with, held only to refuse it as the new
  /// password. Never stored, never sent anywhere.
  final String tempPassword;

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  /// Matches `MIN_PASSWORD_LEN` in `functions/index.js`, which is Firebase's own
  /// floor. Validated here so the failure is a red line under the field rather
  /// than a round trip and a toast.
  static const _minLen = 6;

  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _newVisible = false;
  bool _confirmVisible = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? get _newError {
    final v = _new.text;
    if (v.isEmpty) return null;
    if (v.length < _minLen) return AppStrings.tempPasswordTooShort(_minLen);
    if (v == widget.tempPassword) return AppStrings.tempPasswordReused;
    return null;
  }

  String? get _confirmError {
    if (_confirm.text.isEmpty) return null;
    return _confirm.text == _new.text ? null : AppStrings.tempPasswordMismatch;
  }

  bool get _valid =>
      _new.text.length >= _minLen &&
      _new.text != widget.tempPassword &&
      _confirm.text == _new.text;

  Future<void> _submit() async {
    if (_busy || !_valid) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final password = _new.text;
    try {
      await ref
          .read(firebaseAdminServiceProvider)
          .changeOwnPassword(password);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '$e';
      });
      return;
    }

    // Clear the pending marker before re-entering sign-in: the gauntlet is about
    // to read a doc whose flag is now false, and a stale marker would bounce the
    // admin straight back onto this screen.
    ref.read(pendingPasswordChangeProvider.notifier).state = null;
    if (mounted) Navigator.of(context).pop(password);
  }

  Future<void> _cancel() async {
    ref.read(pendingPasswordChangeProvider.notifier).state = null;
    await ref.read(firebaseAdminServiceProvider).signOut();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return PopScope(
      // Backing out silently would leave a signed-in Firebase session behind a
      // screen that is no longer on top. Leaving is fine; leaving quietly is not.
      canPop: false,
      child: Scaffold(
        backgroundColor: sc.bg0,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Sp.s4),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SatCard.plain(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppStrings.tempPasswordTitle,
                        style: SatType.h2(color: sc.textHi),
                      ),
                      const SizedBox(height: Sp.s2),
                      Text(
                        AppStrings.tempPasswordReason,
                        style: SatType.bodyM(color: sc.textMd),
                      ),
                      const SizedBox(height: Sp.s2),
                      Text(
                        widget.pending.email,
                        style: SatType.monoS(color: sc.textLo),
                      ),
                      const SizedBox(height: Sp.s5),
                      SatField.password(
                        controller: _new,
                        label: AppStrings.tempPasswordNew,
                        hint: '',
                        autofocus: true,
                        visible: _newVisible,
                        onToggle: () =>
                            setState(() => _newVisible = !_newVisible),
                        onChanged: (_) => setState(() {}),
                        errorText: _newError,
                      ),
                      const SizedBox(height: Sp.s3),
                      SatField.password(
                        controller: _confirm,
                        label: AppStrings.tempPasswordConfirm,
                        hint: '',
                        visible: _confirmVisible,
                        onToggle: () =>
                            setState(() => _confirmVisible = !_confirmVisible),
                        onChanged: (_) => setState(() {}),
                        errorText: _confirmError,
                      ),
                      if (_error case final e?) ...[
                        const SizedBox(height: Sp.s3),
                        Text(e, style: SatType.bodyS(color: sc.urgent)),
                      ],
                      const SizedBox(height: Sp.s5),
                      SatButton.primary(
                        label: AppStrings.save,
                        onTap: _busy || !_valid ? null : _submit,
                      ),
                      const SizedBox(height: Sp.s2),
                      SatButton.ghost(
                        label: AppStrings.logout,
                        onTap: _busy ? null : _cancel,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
