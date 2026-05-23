import 'package:bonsoir/bonsoir.dart';

/// Advertise the in-app server over mDNS so clients on the same LAN can
/// discover it. Service type: `_satset._tcp`.
class SatSetAdvertiser {
  BonsoirBroadcast? _broadcast;

  Future<void> start({required int port, required String fingerprint}) async {
    final service = BonsoirService(
      name: 'satset',
      type: '_satset._tcp',
      port: port,
      attributes: {'fp': fingerprint},
    );
    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.ready;
    await _broadcast!.start();
  }

  Future<void> stop() async {
    await _broadcast?.stop();
    _broadcast = null;
  }
}
