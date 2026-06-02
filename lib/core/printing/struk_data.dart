/// Plain, transport-agnostic description of a struk (guest order-confirmation
/// slip). Built identically on the server (from Drift rows) and on a client
/// (from domain tickets), then handed to the shared [StrukRenderer] so the
/// printed bytes are the same whoever transmits them. See
/// docs/adr/0020-two-scope-printers-shared-renderer.md.
///
/// Carries NO money — the struk is a confirmation, not a bill (see the "Struk"
/// glossary term in CONTEXT.md).
class StrukLine {
  final int qty;
  final String name;
  final String variant; // '' when none
  final List<String> modifiers; // human labels, may be empty
  final String note; // '' when none

  const StrukLine({
    required this.qty,
    required this.name,
    this.variant = '',
    this.modifiers = const [],
    this.note = '',
  });
}

class StrukData {
  final String venueName;
  final String header; // receiptHeader, free text, may be ''
  final String footer; // receiptFooter, free text, may be ''
  final String address;
  final String phone;
  final String tableLabel;
  final int pax;
  final String guestName; // '' when none
  final String guestNote; // table-level "Catatan", '' when none
  final DateTime at;
  final List<StrukLine> lines;

  const StrukData({
    required this.venueName,
    this.header = '',
    this.footer = '',
    this.address = '',
    this.phone = '',
    required this.tableLabel,
    required this.pax,
    this.guestName = '',
    this.guestNote = '',
    required this.at,
    required this.lines,
  });

  bool get isEmpty => lines.isEmpty;
}
