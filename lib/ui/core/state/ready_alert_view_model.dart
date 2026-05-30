import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReadyAlert {
  /// Real table id — the `/table/:id` route param the "Ambil" button navigates
  /// to. Always the table's stable id, never a display label.
  final String tableId;

  /// Human-facing table label (e.g. "Meja 5" / "A2"). Display only — falls back
  /// to [tableId] when the table row can't be resolved.
  final String tableLabel;
  final String zone;
  final String what;
  const ReadyAlert({
    required this.tableId,
    required this.tableLabel,
    required this.zone,
    required this.what,
  });
}

final readyAlertProvider = StateProvider<ReadyAlert?>((ref) => null);
