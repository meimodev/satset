import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// The [[Alamat pelanggan]] picker's vocabulary: kabupaten → kecamatan →
/// kelurahan, **Sulawesi Utara only**.
///
/// **Why one province.** The venues this ships to are there, and the whole
/// national set is ~83k desa — a ~1.5 MB asset to make a nice-to-have field
/// spell-check itself. This one is 25 KB. Widening it later is a bigger JSON
/// and nothing else: no schema change, no migration, no route, because the
/// picked value is stored as a **name snapshot** and nothing joins on it.
/// Nothing here is a validator — a guest from Surabaya leaves all three empty
/// and their address goes on the street line.
///
/// Bundled rather than fetched because the app's whole promise is working with
/// no internet.
class Wilayah {
  /// Kabupaten/kota name → kecamatan name → kelurahan/desa names. Every level
  /// is pre-sorted by the generator, so a picker renders it as-is.
  final Map<String, Map<String, List<String>>> byKabupaten;

  const Wilayah(this.byKabupaten);

  List<String> get kabupaten => byKabupaten.keys.toList(growable: false);

  List<String> kecamatanIn(String? kab) =>
      (byKabupaten[kab]?.keys.toList(growable: false)) ?? const [];

  List<String> kelurahanIn(String? kab, String? kec) =>
      byKabupaten[kab]?[kec] ?? const [];
}

Future<Wilayah>? _pending;

/// Loaded once per process and held: 25 KB the picker may open a dozen times a
/// shift, and re-decoding it each time buys nothing.
Future<Wilayah> loadWilayah() =>
    _pending ??= rootBundle.loadString('assets/wilayah/sulut.json').then((raw) {
      final root = jsonDecode(raw) as Map<String, dynamic>;
      return Wilayah({
        for (final kab in root.entries)
          kab.key: {
            for (final kec in (kab.value as Map<String, dynamic>).entries)
              kec.key: [
                for (final kel in kec.value as List) kel as String,
              ],
          },
      });
    });
