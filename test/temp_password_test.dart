import 'package:flutter_test/flutter_test.dart';
import 'package:satset/data/services/firebase_admin_service.dart';

/// The temporary-password gate, pinned (ADR-0075).
///
/// This is the comparison that decides whether a code someone read aloud over a
/// phone call is still allowed to authenticate. The hourly sweep in
/// `functions/index.js` retires the credential at Firebase, but it runs on a
/// schedule and this does not — so this is what actually closes the window, and
/// getting the boundary wrong either strands an admin or keeps a spoken
/// credential alive past its term.
void main() {
  final now = DateTime(2026, 8, 1, 12);

  AdminProfile profile({bool mustChange = true, DateTime? resetAt}) =>
      AdminProfile(
        uid: 'u1',
        status: AdminStatus.active,
        role: AdminRole.admin,
        name: 'Budi',
        venueId: 'v1',
        avatarColorHex: null,
        fromCache: false,
        mustChangePassword: mustChange,
        passwordResetAt: resetAt,
      );

  test('an account with no reset pending is never expired', () {
    // The flag is what puts an account in this state at all; an old timestamp
    // left behind on a settled account must not lock anyone out.
    final p = profile(
      mustChange: false,
      resetAt: now.subtract(const Duration(days: 90)),
    );
    expect(p.expiredTempPassword(now), isFalse);
  });

  test('fresh code passes', () {
    final p = profile(resetAt: now.subtract(const Duration(hours: 1)));
    expect(p.expiredTempPassword(now), isFalse);
  });

  test('just inside 24h passes', () {
    final p = profile(
      resetAt: now.subtract(const Duration(hours: 23, minutes: 59)),
    );
    expect(p.expiredTempPassword(now), isFalse);
  });

  test('exactly 24h still passes — the boundary is not expired yet', () {
    final p = profile(resetAt: now.subtract(FirebaseAdminService.otpTtl));
    expect(p.expiredTempPassword(now), isFalse);
  });

  test('past 24h is refused', () {
    final p = profile(
      resetAt: now.subtract(const Duration(hours: 24, minutes: 1)),
    );
    expect(p.expiredTempPassword(now), isTrue);
  });

  test('flagged with no timestamp is refused', () {
    // A half-landed write: the flag set, the stamp missing. Refusing costs the
    // operator one re-mint; accepting means a code with no term at all.
    expect(profile(resetAt: null).expiredTempPassword(now), isTrue);
  });

  test('the app TTL matches the sweep in functions/index.js', () {
    // OTP_TTL_MS there is 24 * 60 * 60 * 1000. If these drift apart the app
    // accepts a code the account no longer has, or refuses one it still does.
    expect(FirebaseAdminService.otpTtl, const Duration(hours: 24));
  });
}
