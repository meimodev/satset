import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'db/database.dart';

/// One-time pairing tokens with TTL. Tokens are single-use and bound to the
/// claiming device.
class PairingService {
  PairingService(this.db);
  final AppDatabase db;

  static const tokenTtl = Duration(minutes: 5);

  Future<PairToken> issue() async {
    final now = DateTime.now();
    final row = PairTokensCompanion.insert(
      token: const Uuid().v4(),
      createdAt: now,
      expiresAt: now.add(tokenTtl),
    );
    await db.into(db.pairTokens).insert(row);
    return (db.select(
      db.pairTokens,
    )..where((t) => t.token.equals(row.token.value))).getSingle();
  }

  /// Returns the device row on success or null when the token is missing,
  /// expired, or already used.
  Future<Device?> claim({
    required String token,
    required String deviceId,
    required String deviceLabel,
    required String publicKeyPem,
  }) async {
    final row = await (db.select(
      db.pairTokens,
    )..where((t) => t.token.equals(token))).getSingleOrNull();
    if (row == null) return null;
    if (row.used) return null;
    if (row.expiresAt.isBefore(DateTime.now())) return null;

    await db.transaction(() async {
      await (db.update(
        db.pairTokens,
      )..where((t) => t.token.equals(token))).write(
        PairTokensCompanion(
          used: const Value(true),
          claimedByDeviceId: Value(deviceId),
        ),
      );
      await db
          .into(db.devices)
          .insertOnConflictUpdate(
            DevicesCompanion.insert(
              id: deviceId,
              label: deviceLabel,
              publicKeyPem: publicKeyPem,
              pairedAt: DateTime.now(),
            ),
          );
    });
    return (db.select(
      db.devices,
    )..where((d) => d.id.equals(deviceId))).getSingleOrNull();
  }
}
