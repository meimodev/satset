import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Shoot a proof photo — the one place the picker is configured.
///
/// Four call sites wanted the identical four arguments (`camera`, 1080 × 1080,
/// quality 80): the two settle panes, the [[Piutang]] collection sheet, and the
/// [[Pengeluaran kunjungan]] sheet. Four copies of a compression setting is
/// four places for a proof to quietly become a different size.
///
/// Returns null when the picker was dismissed. It does **not** swallow a
/// failure: a denied camera permission has to reach the caller, because on the
/// one screen where the photo is mandatory (ADR-0130) a silent null would read
/// as "the user changed their mind" and leave no way to say what went wrong.
Future<Uint8List?> shootProofPhoto({
  ImageSource source = ImageSource.camera,
}) async {
  final x = await ImagePicker().pickImage(
    source: source,
    maxWidth: 1080,
    maxHeight: 1080,
    imageQuality: 80,
  );
  if (x == null) return null;
  return x.readAsBytes();
}
