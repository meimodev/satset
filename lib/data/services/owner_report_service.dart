import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';

/// Cloud report snapshot plumbing for the off-site owner (ADR-0036).
///
/// Two sides, two roles:
///   - [OwnerReportPublisher] runs on the **host** (Main Device): it pushes the
///     venue's aggregate report to `reports/{vid}` on a fixed interval + on
///     demand, and listens for the owner's refresh command.
///   - [OwnerReportService] runs on the **owner**'s device: it reads
///     `reports/{vid}` and writes the refresh command `report_requests/{vid}`.
///
/// The report payload is the JSON the embedded server already serves at
/// `/reports/snapshot` (pre-aggregated, KB-scale) — published per fixed range,
/// not real-time. See ADR-0036.

/// Ranges published into the one report doc. Keys match the server's `range`
/// query param and double as the Firestore field names.
const kOwnerReportRanges = ['today', 'd7'];

/// How often the host republishes while the server is live. Not real-time by
/// design; the owner can force a fresh publish via a refresh request.
const kOwnerReportInterval = Duration(minutes: 30);

/// Host-side publisher. Constructed with a [fetchSnapshot] that hits the local
/// `/reports/snapshot` endpoint (loopback) — keeping this service free of the
/// HTTP/Drift details and easy to test.
class OwnerReportPublisher {
  OwnerReportPublisher({
    required FirebaseFirestore firestore,
    required this.vid,
    required this.fetchSnapshot,
  }) : _fs = firestore;

  final FirebaseFirestore _fs;
  final String vid;

  /// Returns the decoded `/reports/snapshot` JSON for [range], or null on
  /// failure (publish then skips that range rather than wiping a good one).
  final Future<Map<String, dynamic>?> Function(String range) fetchSnapshot;

  Timer? _timer;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _reqSub;
  DateTime? _lastHandledRequest;
  bool _publishing = false;

  DocumentReference<Map<String, dynamic>> get _reportDoc =>
      _fs.collection('reports').doc(vid);
  DocumentReference<Map<String, dynamic>> get _requestDoc =>
      _fs.collection('report_requests').doc(vid);

  void start() {
    stop();
    unawaited(_publish()); // immediate, so the owner sees data right after boot
    _timer = Timer.periodic(kOwnerReportInterval, (_) => unawaited(_publish()));
    // Owner refresh command: republish when requestedAt advances. The host
    // never writes this doc, so its own publishes can't re-trigger this.
    _reqSub = _requestDoc.snapshots().listen((snap) {
      final ts = (snap.data()?['requestedAt'] as Timestamp?)?.toDate();
      if (ts == null) return;
      if (_lastHandledRequest != null && !ts.isAfter(_lastHandledRequest!)) {
        return; // already satisfied
      }
      _lastHandledRequest = ts;
      SatLog.repo('ownerReport.refresh requested vid=$vid');
      unawaited(_publish());
    });
  }

  Future<void> _publish() async {
    if (_publishing) return; // coalesce overlapping ticks/requests
    _publishing = true;
    try {
      final payload = <String, dynamic>{};
      for (final range in kOwnerReportRanges) {
        final json = await fetchSnapshot(range);
        if (json != null) payload[range] = json;
      }
      if (payload.isEmpty) return; // all ranges failed — keep the last good doc
      payload['generatedAt'] = FieldValue.serverTimestamp();
      await _reportDoc.set(payload);
      SatLog.repo('ownerReport.published vid=$vid ranges=${payload.keys.length - 1}');
    } catch (e) {
      SatLog.repo('ownerReport.publish fail $e');
    } finally {
      _publishing = false;
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    unawaited(_reqSub?.cancel());
    _reqSub = null;
  }
}

/// One published report doc as the owner sees it: a freshness stamp plus the
/// raw per-range snapshot JSON (parsed into `ReportsSnapshotDto` by the UI).
class OwnerReport {
  final DateTime? generatedAt;
  final Map<String, Map<String, dynamic>> ranges;
  final bool fromCache;

  const OwnerReport({
    required this.generatedAt,
    required this.ranges,
    required this.fromCache,
  });

  Map<String, dynamic>? range(String key) => ranges[key];

  static OwnerReport fromDoc(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? const {};
    final ranges = <String, Map<String, dynamic>>{};
    for (final key in kOwnerReportRanges) {
      final v = d[key];
      if (v is Map) ranges[key] = v.cast<String, dynamic>();
    }
    return OwnerReport(
      generatedAt: (d['generatedAt'] as Timestamp?)?.toDate(),
      ranges: ranges,
      fromCache: snap.metadata.isFromCache,
    );
  }
}

/// Owner-side reader: streams the published report and sends refresh commands.
class OwnerReportService {
  OwnerReportService({FirebaseFirestore? firestore})
      : _fs = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _fs;

  Stream<OwnerReport?> watch(String vid) =>
      _fs.collection('reports').doc(vid).snapshots().map(
            (s) => s.exists ? OwnerReport.fromDoc(s) : null,
          );

  /// Stamp the refresh command. The host (if online) republishes; the owner's
  /// [watch] stream then surfaces a newer `generatedAt`.
  Future<void> requestRefresh(String vid) => _fs
      .collection('report_requests')
      .doc(vid)
      .set({'requestedAt': FieldValue.serverTimestamp()});
}

final ownerReportServiceProvider =
    Provider<OwnerReportService>((_) => OwnerReportService());

/// Live published report for the signed-in owner's venue. The owner screen
/// reads its venueId from the auth session and passes it here.
final ownerReportProvider =
    StreamProvider.family<OwnerReport?, String>((ref, vid) {
  return ref.watch(ownerReportServiceProvider).watch(vid);
});
