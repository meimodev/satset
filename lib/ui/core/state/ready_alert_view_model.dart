import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReadyAlert {
  /// Real table id — the `/table/:id` route param the "Ambil" button navigates
  /// to. Always the table's stable id, never a display label.
  final String tableId;

  /// Human-facing table label (e.g. "Meja 5" / "A2"), or the takeaway visit
  /// label ("Bawa pulang #7") when [isTakeaway]. Display only — falls back to
  /// [tableId] when neither a table row nor a takeaway visit resolves.
  final String tableLabel;

  /// Zone name for a dine-in table; the guest name for a takeaway visit. ''
  /// when unknown.
  final String zone;
  final String what;

  /// True when the ready order is a takeaway [[Visit]] (no table). Drives both
  /// the toast copy (no "MEJA" prefix) and the "Ambil" route (`/takeaway/:id`
  /// vs `/table/:id`). See ADR-0026.
  final bool isTakeaway;
  const ReadyAlert({
    required this.tableId,
    required this.tableLabel,
    required this.zone,
    required this.what,
    this.isTakeaway = false,
  });
}

final readyAlertProvider = StateProvider<ReadyAlert?>((ref) => null);
