import 'package:flutter/widgets.dart';

import 'package:satset/core/log/sat_log.dart';

class SatNavObserver extends NavigatorObserver {
  String _name(Route<dynamic>? r) =>
      r?.settings.name ?? r?.settings.toString() ?? '?';

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    SatLog.nav('push ${_name(route)}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    SatLog.nav('pop ${_name(route)} → ${_name(previousRoute)}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    SatLog.nav('replace ${_name(oldRoute)} → ${_name(newRoute)}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    SatLog.nav('remove ${_name(route)}');
  }
}
