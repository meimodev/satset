import 'package:satset/ui/core/widgets/sat_chip.dart';

/// How a [[Bawa pulang (Takeaway)]] order reached the venue, as the cashier
/// reads it (ADR-0066). One hue each, because at the till these are four
/// different jobs: an aggregator order is usually already paid and waiting on a
/// courier, a phone order is owed and waiting on someone who may not turn up.
///
/// The pill this drives is a takeaway's stand-in for a dine-in's zone chip, so
/// it sits in the same slot on the card.
enum SatChannel {
  bungkus('bungkus', 'Bungkus', SatChipHue.violet),
  telepon('telepon', 'Telepon', SatChipHue.warn),
  gofood('gofood', 'GoFood', SatChipHue.success),
  grab('grab', 'GrabFood', SatChipHue.info);

  final String id;
  final String label;
  final SatChipHue hue;
  const SatChannel(this.id, this.label, this.hue);

  /// Unknown or empty falls back to Bungkus — every takeaway minted before the
  /// channel existed was a walk-in wanting it wrapped.
  static SatChannel from(String? id) => values.firstWhere(
    (c) => c.id == id,
    orElse: () => SatChannel.bungkus,
  );
}
