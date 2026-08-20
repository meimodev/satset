/// The server's **[[Modul]]** gate (ADR-0107). The vocabulary itself lives in
/// `domain/models/venue_module.dart`; this file is only the read against a
/// settings row.
///
/// It is a *reader*, not a writer, which is what makes it unlike its neighbours
/// `cash.dart`, `members.dart` and `self_order.dart`. Nothing on this server may
/// write a module: the set is cloud-owned and arrives by the host's venue-doc
/// mirror (ADR-0018's pattern), so the only local write path is the ordinary
/// settings PATCH that mirror makes.
///
/// **Read it through a feature's own gate, never at a route.** `memberConfig`
/// and `guestRules` already compute one `enabled` that every route beneath them
/// obeys; the module check belongs in that computation and nowhere else, for the
/// same reason `writeAudit` is the only audit writer. A route that asks about
/// modules for itself is a review finding.
library;

import 'package:satset/domain/models/venue_module.dart';
import 'package:satset/server/db/database.dart';

export 'package:satset/domain/models/venue_module.dart';

/// Whether the venue holds [key].
///
/// **Unknown reads as entitled**, twice over: a missing settings row (nothing is
/// seeded yet) and a null `modules` (nothing has mirrored yet) both answer true.
/// The alternative is a venue losing a feature it pays for to a schema migration
/// or a cold boot, and payment is enforced by the subscription cutoff — never by
/// a feature going dark. `''` is a real answer and means no module.
bool venueHasModule(VenueSetting? s, String key) =>
    s?.modules == null || splitModules(s!.modules).contains(key);
