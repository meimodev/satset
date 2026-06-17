import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;

/// Shared ESC/POS branding helper (ADR-0033). Decodes the stored venue logo
/// JPEG, downscales it to the 58mm print head, and returns the centred
/// monochrome raster bytes. Returns an empty list on any failure (no bytes,
/// undecodable image) so a bad logo never blocks a print — the renderer simply
/// falls back to a text-only header.
///
/// CRITICAL: uses the ESC * column-format command (`Generator.image`), NOT the
/// GS v 0 raster command (`imageRaster`). Many cheap 58mm heads don't implement
/// GS v 0 — they spew the raster data block as text, desync, and render the
/// ENTIRE receipt as random characters. ESC * is the legacy bit-image command
/// with the widest compatibility. We pre-resize to a multiple of 8 ≤ 384 dots
/// (the print head width) so the image fits and never trips esc_pos's buggy
/// non-multiple-of-8 padding path.
List<int> logoRasterBytes(Generator g, List<int>? jpeg) {
  if (jpeg == null || jpeg.isEmpty) return const [];
  try {
    final decoded = img.decodeImage(Uint8List.fromList(jpeg));
    if (decoded == null) return const [];
    var target = decoded.width > 384 ? 384 : decoded.width;
    target -= target % 8; // multiple of 8, fits the 384-dot head
    if (target <= 0) return const [];
    final scaled = target == decoded.width
        ? decoded
        : img.copyResize(decoded, width: target);
    return g.image(scaled, align: PosAlign.center);
  } catch (_) {
    return const [];
  }
}
