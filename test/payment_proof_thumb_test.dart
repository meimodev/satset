import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/core/widgets/payment_proof_thumb.dart';
import 'package:satset/l10n/app_localizations.dart';

/// One box for every proof state (ADR-0082).
///
/// Two regressions live here, and both were real before the widget owned all
/// three states: a call site picking its own `size` (the thumb was 22, 26 and
/// 44 on three screens showing the same slip), and the "no bytes" placeholder
/// drifting away from the thumb it stands in for (it was a hand-rolled 44dp
/// box at the reports call site while the thumb beside it was 56). Anything
/// that reintroduces either fails one of these.
///
/// `apiConfigProvider` defaults to null, so the fetching path resolves to its
/// unpaired branch with no overrides and no server — which is also the state an
/// off-site owner sees.
void main() {
  // 4×4 red PNG. Only needs to decode; nothing here looks at it.
  final pngBytes = Uint8List.fromList(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAQAAAAECAIAAAAmkwkpAAAAFklEQVR4nGP8z'
      '8DAwMDAxMDAwMDAAAANHQEHi5sTuwAAAABJRU5ErkJggg==',
    ),
  );

  Future<void> pump(WidgetTester tester, Widget thumb) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          // Pinned, exactly as the app pins it (ADR-0083). Without this the
          // test resolves against the host's locale and reads English.
          locale: const Locale('id'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          theme: satTheme(SatTheme.neonTerang),
          home: Scaffold(body: Center(child: thumb)),
        ),
      ),
    );
    await tester.pump();
  }

  Size boxOf(WidgetTester tester) =>
      tester.getSize(find.byType(PaymentProofThumb));

  testWidgets('the slip renders its bytes', (tester) async {
    await pump(
      tester,
      PaymentProofThumb(paymentId: null, previewBytes: pngBytes),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(boxOf(tester), const Size(satProofThumb, satProofThumb));
  });

  testWidgets('proof taken but unreachable is not the same as no proof', (
    tester,
  ) async {
    await pump(
      tester,
      const PaymentProofThumb(
        paymentId: 'pay-1',
        history: true,
        fetchable: false,
      ),
    );

    expect(find.byIcon(Icons.photo_camera_back_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(boxOf(tester), const Size(satProofThumb, satProofThumb));
  });

  testWidgets('a payment with no proof says so', (tester) async {
    await pump(
      tester,
      const PaymentProofThumb(paymentId: 'pay-2', hasPhoto: false),
    );

    expect(find.byIcon(Icons.image_not_supported_rounded), findsOneWidget);
    expect(boxOf(tester), const Size(satProofThumb, satProofThumb));
  });

  testWidgets('an unresolvable id degrades, never a broken image', (
    tester,
  ) async {
    await pump(tester, const PaymentProofThumb(paymentId: 'tidak-ada'));

    expect(find.byIcon(Icons.photo_camera_back_outlined), findsOneWidget);
    expect(boxOf(tester), const Size(satProofThumb, satProofThumb));
  });

  testWidgets('tapping the slip opens the lightbox', (tester) async {
    await pump(
      tester,
      PaymentProofThumb(paymentId: null, previewBytes: pngBytes),
    );

    await tester.tap(find.byType(PaymentProofThumb));
    await tester.pumpAndSettle();

    expect(find.text('Bukti pembayaran'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('a tight parent cannot stretch the box', (tester) async {
    // The widget book's stage is a `Container(width: double.infinity)`, and a
    // stretching Column does the same. A bare SizedBox loses that argument and
    // the thumb becomes a smeared full-width band — which is what shipped, and
    // what every other test here missed by pumping inside a Center.
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          // Pinned, exactly as the app pins it (ADR-0083). Without this the
          // test resolves against the host's locale and reads English.
          locale: const Locale('id'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          theme: satTheme(SatTheme.neonTerang),
          home: Scaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: PaymentProofThumb(
                    paymentId: null,
                    previewBytes: pngBytes,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.getSize(find.byType(Image)),
      const Size(satProofThumb, satProofThumb),
    );
  });

  testWidgets('a placeholder is not tappable', (tester) async {
    await pump(
      tester,
      const PaymentProofThumb(paymentId: 'pay-3', fetchable: false),
    );

    await tester.tap(find.byType(PaymentProofThumb));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsNothing);
  });
}
