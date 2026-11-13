import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:satset/core/log/sat_log.dart';

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
  final x = await pickImageKeepingAlive(
    source: source,
    maxWidth: 1080,
    maxHeight: 1080,
    imageQuality: 80,
  );
  if (x == null) return null;
  return x.readAsBytes();
}

const _guard = MethodChannel('satset/capture');

/// [ImagePicker.pickImage], with SatSet held in the foreground while the
/// camera or gallery — another app — has the screen. On a low-RAM phone
/// Android otherwise kills SatSet to make room, and the user returns to a cold
/// start with the sheet they were filling gone (`CaptureGuardService.kt`).
/// Every picker call in the app goes through here.
Future<XFile?> pickImageKeepingAlive({
  required ImageSource source,
  double? maxWidth,
  double? maxHeight,
  int? imageQuality,
}) async {
  // Not awaited: platform messages are handled in order on Android's main
  // thread, so the hold lands before the picker's own launch either way.
  unawaited(_setGuard('hold'));
  try {
    return await ImagePicker().pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  } finally {
    unawaited(_setGuard('release'));
  }
}

// The guard is protection, not a precondition: a refusal still opens the camera.
Future<void> _setGuard(String method) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  try {
    await _guard.invokeMethod<void>(method);
  } catch (e, st) {
    SatLog.err('capture.guard', e, st);
  }
}
