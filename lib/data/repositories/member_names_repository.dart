import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/services/api_client.dart';

/// id → name for the [[Pemilik tiket]] a sent order line carries.
///
/// A cache, never a directory. `MembersRepository` holds *one* shared query
/// backing the picker, so resolving a set of ids through it would clobber
/// whatever the cashier or the cart was searching for. This holds the other
/// shape: a growing id→name map nobody searches.
///
/// Three states per id, and the card renders each differently:
///
/// - **key absent** — never asked, or the ask failed. Render nothing.
/// - **key → name** — the member.
/// - **key → null** — asked, and the server named nobody. A member since
///   deleted (ADR-0092); render the placeholder, because the trade stands and
///   the person does not.
///
/// Never invalidated. A rename mid-shift costs a stale label on one line, and
/// `/kasir`, `/members` and the reports all fetch their own names — the
/// authoritative surfaces stay correct without this one watching for changes.
class MemberNames extends StateNotifier<Map<String, String?>> {
  MemberNames(this._ref, [super.initial = const {}]);

  final Ref _ref;

  /// Ids a request is already carrying. Twenty line cards on one table share
  /// three owners; without this the screen's own bulk call and a rebuild
  /// racing it would ask twice for the same three.
  final _inFlight = <String>{};

  /// Resolve every id we have neither answered nor asked about.
  ///
  /// Safe to call from `build`: the fetch awaits before it touches `state`,
  /// and a repeat call for known ids is a no-op.
  Future<void> resolve(Iterable<String?> ids) async {
    final want = {
      for (final id in ids)
        if (id != null &&
            id.isNotEmpty &&
            !state.containsKey(id) &&
            !_inFlight.contains(id))
          id,
    };
    if (want.isEmpty) return;
    _inFlight.addAll(want);
    try {
      final raw =
          await _ref.read(apiClientProvider).getJson(
                '/members/lookup',
                query: {'ids': want.join(',')},
              )
              as List;
      state = {...state, ...namesFrom(raw, want)};
    } catch (_) {
      // A 404 is membership switched off for this venue; anything else is a
      // dead socket. Record nothing either way, so the next screen retries
      // and no line renders "deleted" over a host that simply did not answer.
    } finally {
      _inFlight.removeAll(want);
    }
  }
}

/// The lookup response folded into one entry per id we asked about.
///
/// Matching is on the id we asked for, **never** on position: an older host
/// does not know `ids` and answers the unfiltered first page of the directory,
/// which would otherwise pin the wrong names onto the wrong lines. Anything
/// unasked-for is dropped, and an id the server named nobody for is recorded
/// as a miss rather than left absent — that is what lets the card tell
/// "deleted" from "not asked yet".
Map<String, String?> namesFrom(List<dynamic> raw, Set<String> asked) {
  final found = <String, String?>{};
  for (final m in raw) {
    if (m is! Map) continue;
    final id = m['id'] as String?;
    if (id == null || !asked.contains(id)) continue;
    found[id] = m['name'] as String?;
  }
  return {for (final id in asked) id: found[id]};
}

final memberNamesProvider =
    StateNotifierProvider<MemberNames, Map<String, String?>>(
      MemberNames.new,
    );
