import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/services/api_client.dart';

/// **Buka kedai / Tutup kedai** (ADR-0111).
///
/// No state, deliberately — hence a plain [Provider] and not the
/// `StateNotifier` every sibling repository is. The venue day has nothing to
/// cache: the record is two audit rows the venue log already pages, and
/// anything holding "the shop is open" here would be the stuck boolean the ADR
/// rejected, only client-side and therefore worse.
class VenueDayRepository {
  const VenueDayRepository(this._ref);
  final Ref _ref;

  Future<void> open({String? note}) => _mark('open', note);

  Future<void> close({String? note}) => _mark('close', note);

  Future<void> _mark(String which, String? note) async {
    await _ref.read(apiClientProvider).postJson('/venue/day/$which', {
      'note': note,
    });
    SatLog.repo('venueDay.$which');
  }
}

final venueDayProvider = Provider<VenueDayRepository>(
  (ref) => VenueDayRepository(ref),
);
