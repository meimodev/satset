import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/settlement_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/core/localization/locale_view_model.dart';

/// Every proof image in the app is this box: a [satProofThumb] square, cropped
/// `cover`, opening a fullscreen lightbox on tap. ADR-0082.
///
/// One size on every surface on purpose. The thumb is not there to be read —
/// a bank slip's nominal and sender sit at the edges and the crop eats them —
/// it is there to say *a real slip was attached, not a blurry ceiling shot*.
/// That judgement takes the same pixels on a live bill as it does in a report,
/// so no call site passes a size.
const double satProofThumb = 56;

/// Proof-photo thumbnail for a payment (ADR-0025), in all three of its states:
///
/// - **the slip** — bytes fetched over the pinned client via [proofPhotoProvider],
///   or handed in directly as [previewBytes];
/// - **proof exists but is unfetchable** — [fetchable] false. Blobs live only on
///   the LAN venue server, so an off-site owner reading a report knows the proof
///   was taken without being able to open it (ADR-0036);
/// - **no proof** — [hasPhoto] false. Cash, or a legacy row from before the
///   photo was mandatory.
///
/// The last two used to be a hand-rolled box at one call site, pinned to its
/// own size, which is how the placeholder and the thumb drifted apart.
///
/// [history] picks the blob: true reads the snapshotted (settled bill / report)
/// copy, false the live payment.
class PaymentProofThumb extends ConsumerWidget {
  /// Null only for a proof that has not been submitted yet — the settle flow's
  /// capture preview, which holds its bytes locally and has no payment to name.
  /// Such a call must pass [previewBytes].
  final String? paymentId;
  final bool history;

  /// Bytes to render instead of fetching. The capture preview's own shot, and
  /// the widget book's stub — both need the loaded state with no server.
  final Uint8List? previewBytes;

  /// False when the payment carries no proof at all (cash, legacy).
  final bool hasPhoto;

  /// False when the proof exists but its bytes are out of reach (ADR-0036).
  final bool fetchable;

  const PaymentProofThumb({
    super.key,
    required this.paymentId,
    this.history = false,
    this.previewBytes,
    this.hasPhoto = true,
    this.fetchable = true,
  }) : assert(
         paymentId != null || previewBytes != null,
         'a thumb with no payment id has nothing to fetch — pass previewBytes',
       );

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _held(_state(context, ref));

  Widget _state(BuildContext context, WidgetRef ref) {
    if (!hasPhoto) return _Placeholder(Icons.image_not_supported_rounded);
    if (previewBytes != null) return _shot(context, previewBytes!);
    if (!fetchable || paymentId == null) {
      return _Placeholder(Icons.photo_camera_back_outlined);
    }
    final async = ref.watch(
      proofPhotoProvider((id: paymentId!, history: history)),
    );
    return async.maybeWhen(
      data: (bytes) => bytes == null
          ? _Placeholder(Icons.photo_camera_back_outlined)
          : _shot(context, bytes),
      orElse: () => _Placeholder(Icons.photo_camera_back_outlined),
    );
  }

  /// Holds the box at [satProofThumb] even under tight parent constraints.
  ///
  /// A bare `SizedBox` does not: a parent that hands down a tight width — a
  /// `Container(width: double.infinity)`, a stretching `Column` — wins, and the
  /// thumb silently becomes a smeared full-width band. That is the opposite of
  /// what ADR-0082 says this widget is for, and it is invisible from the call
  /// site, so the guarantee belongs here rather than in every parent.
  Widget _held(Widget child) => UnconstrainedBox(
    alignment: Alignment.centerLeft,
    child: SizedBox(width: satProofThumb, height: satProofThumb, child: child),
  );

  Widget _shot(BuildContext context, Uint8List bytes) => Semantics(
    button: true,
    label: context.l10n.a11yViewPhoto,
    child: GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => ProofViewer(bytes),
        ),
      ),
      child: ClipRRect(
        borderRadius: SatR.a(6),
        child: Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
      ),
    ),
  );
}

/// The two image-less states. Same box as the slip so a column of payment rows
/// keeps one left edge whatever each row carries.
class _Placeholder extends StatelessWidget {
  final IconData icon;
  const _Placeholder(this.icon);

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      alignment: Alignment.center,
      decoration: SatBox.d(color: sc.bg1, borderRadius: SatR.a(6)),
      child: Icon(icon, size: satProofThumb * 0.4, color: sc.textLo),
    );
  }
}

/// The one fullscreen proof lightbox. Public because the venue log opens the
/// same image from a row rather than a thumb (ADR-0086), and a second viewer
/// would be a second set of chrome to keep in step.
class ProofViewer extends StatelessWidget {
  final Uint8List bytes;
  const ProofViewer(this.bytes, {super.key});

  // A lightbox, not a themed screen — see satMediaChrome.
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: satMediaChrome,
    appBar: AppBar(
      backgroundColor: satMediaChrome,
      iconTheme: const IconThemeData(color: satMediaInk),
      title: Text(
        context.l10n.ppfTitle,
        style: SatType.labelL(color: satMediaInk),
      ),
    ),
    body: Center(
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 5,
        child: Image.memory(bytes),
      ),
    ),
  );
}
