import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Guards against accidental app exit via the Android back button.
///
/// Must be mounted inside go_router's [Navigator] (e.g. within a shell route)
/// so the wrapped [PopScope] receives back events for its route.
///
/// While there is an in-app route to pop, back navigates normally. Once at a
/// root route (where back would otherwise exit the app), the first press shows
/// a confirmation toast and a second press within [window] actually exits.
class ExitGuard extends StatefulWidget {
  final Widget child;
  const ExitGuard({super.key, required this.child});

  @override
  State<ExitGuard> createState() => _ExitGuardState();
}

class _ExitGuardState extends State<ExitGuard> {
  static const window = Duration(seconds: 2);
  DateTime? _lastBack;

  void _onPop(bool didPop, Object? result) {
    if (didPop) return;

    // In-app history available — pop that instead of exiting.
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }

    final now = DateTime.now();
    if (_lastBack != null && now.difference(_lastBack!) < window) {
      SystemNavigator.pop();
      return;
    }
    _lastBack = now;
    ScaffoldMessenger.maybeOf(context)
      ?..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          duration: window,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Tekan kembali lagi untuk keluar',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPop,
      child: widget.child,
    );
  }
}
