import 'package:satset/core/printing/struk_data.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/core/time/sat_clock.dart';

/// Client-side assembly of a [StrukData] from domain tickets + venue settings.
/// The server has its own assembly from Drift rows; both produce the same shape
/// so the shared [StrukRenderer] prints identically. See ADR-0020.
class StrukBuilder {
  /// Non-voided lines only — a struk confirms what the guest ordered.
  static List<StrukLine> linesFromTickets(List<Ticket> tickets) {
    return [
      for (final t in tickets)
        if (t.status != TicketStatus.voided)
          StrukLine(
            qty: t.qty,
            name: t.name,
            variant: t.variantName,
            modifiers: [for (final m in t.modifiers) m.label],
            note: (t.note ?? '').trim(),
          ),
    ];
  }

  static StrukData fromTable({
    required VenueSettingsDto venue,
    required String tableLabel,
    required int pax,
    required List<Ticket> tickets,
    String guestName = '',
    String guestNote = '',
    DateTime? at,
    List<int>? logoBytes,
  }) {
    return StrukData(
      venueName: venue.displayName,
      header: venue.receiptHeader,
      footer: venue.receiptFooter,
      tagline: venue.receiptTagline,
      social: venue.receiptSocial,
      thankYou: venue.receiptThankYou,
      address: venue.address,
      phone: venue.phone,
      logoBytes: logoBytes,
      tableLabel: tableLabel,
      pax: pax,
      guestName: guestName,
      guestNote: guestNote,
      at: at ?? SatClock.now(),
      lines: linesFromTickets(tickets),
    );
  }
}
