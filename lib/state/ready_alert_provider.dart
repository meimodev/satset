import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReadyAlert {
  final String tableId;
  final String zone;
  final String what;
  const ReadyAlert({required this.tableId, required this.zone, required this.what});
}

final readyAlertProvider = StateProvider<ReadyAlert?>((ref) => null);
