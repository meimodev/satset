import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/router/app_router.dart';

import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/services/alert_sound_service.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/ui/core/state/ready_alert_view_model.dart';
import 'package:satset/ui/core/widgets/ready_toast.dart';

/// App-wide host that (1) keeps [alertSoundServiceProvider] alive once paired
/// and authenticated, and (2) renders the [ReadyToast] in response to
/// [readyAlertProvider]. Wrap the router child with this in `app.dart`.
class AlertHost extends ConsumerStatefulWidget {
  const AlertHost({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AlertHost> createState() => _AlertHostState();
}

class _AlertHostState extends ConsumerState<AlertHost>
    with SingleTickerProviderStateMixin {
  // Created in initState (not a `late final` initializer) so the controller
  // always exists by dispose(). A lazy initializer would otherwise fire from
  // dispose() if no toast ever showed, running createTicker() against a
  // deactivated element → "Looking up a deactivated widget's ancestor".
  // Refined drop-in: confident ease-out on enter, snappier (shorter) exit.
  late final AnimationController _ac;
  // ease-out-expo — decisive deceleration, no bounce.
  late final Animation<double> _curve;

  // Held separately from the provider so the toast stays mounted through its
  // exit animation after the provider is cleared.
  ReadyAlert? _shown;
  Timer? _dwell;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 260),
    );
    _curve = CurvedAnimation(parent: _ac, curve: const Cubic(0.16, 1, 0.3, 1));
  }

  @override
  void dispose() {
    _dwell?.cancel();
    _ac.dispose();
    super.dispose();
  }

  void _show(ReadyAlert alert) {
    _dwell?.cancel();
    setState(() => _shown = alert);
    _ac.forward();
    _dwell = Timer(const Duration(seconds: 3), _hide);
  }

  /// "Ambil" tapped: jump to the ready table's detail unless already there,
  /// then dismiss. Opening the detail acquires the table lock — the waiter is
  /// grabbing the handoff.
  void _grab() {
    final id = _shown?.tableId;
    if (id != null && id.isNotEmpty) {
      // AlertHost sits above the route subtree (MaterialApp.router builder), so
      // GoRouterState.of(context) has no ancestor here. Reach the router via the
      // provider instead.
      final router = ref.read(routerProvider);
      // Takeaway ready alerts carry a visitId → route to the Bawa pulang detail;
      // dine-in carries a tableId → the table detail. See ADR-0026.
      final base = (_shown?.isTakeaway ?? false) ? '/takeaway' : '/table';
      final loc = router.routerDelegate.currentConfiguration.uri.path;
      final inIt = loc == '$base/$id' || loc.startsWith('$base/$id/');
      if (!inIt) router.push('$base/$id');
    }
    _hide();
  }

  void _hide() {
    _dwell?.cancel();
    _dwell = null;
    if (ref.read(readyAlertProvider) != null) {
      // Drives the listener back through here exactly once.
      ref.read(readyAlertProvider.notifier).state = null;
      return;
    }
    _ac.reverse().whenComplete(() {
      if (mounted && ref.read(readyAlertProvider) == null) {
        setState(() => _shown = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final paired = ref.watch(apiConfigProvider) != null;
    final authed =
        ref.watch(authStateProvider.select((s) => s.isAuthenticated));
    // Only spin up the service (and its WS subscription) post-login.
    if (paired && authed) ref.watch(alertSoundServiceProvider);

    ref.listen<ReadyAlert?>(readyAlertProvider, (_, next) {
      if (next != null) {
        _show(next);
      } else {
        _hide();
      }
    });

    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Stack(
      children: [
        widget.child,
        if (_shown != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: AnimatedBuilder(
                animation: _curve,
                builder: (context, child) {
                  final t = reduceMotion
                      ? (_ac.value > 0 ? 1.0 : 0.0)
                      : _curve.value;
                  return Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: Transform.translate(
                      // Slide the toast's own height in from above.
                      offset: Offset(0, reduceMotion ? 0 : (t - 1) * 88),
                      child: child,
                    ),
                  );
                },
                child: Material(
                  color: Colors.transparent,
                  child: ReadyToast(
                    alert: _shown!,
                    onView: _grab,
                    onDismiss: _hide,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
