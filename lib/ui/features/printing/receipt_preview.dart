import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_sheet_header.dart';

/// Capture the actual renderer's commands, including branding and payment
/// details, instead of maintaining another receipt template for the screen.
class ReceiptPreviewGenerator extends Generator {
  ReceiptPreviewGenerator(super.paper, super.profile);

  final children = <Widget>[];
  bool _insideRow = false;

  Text _text(String value, PosStyles styles) => Text(
    value,
    textAlign: switch (styles.align) {
      PosAlign.left => TextAlign.left,
      PosAlign.center => TextAlign.center,
      PosAlign.right => TextAlign.right,
    },
    style: TextStyle(
      color: satPaperInk,
      fontFamily: 'monospace',
      fontSize: 16.0 * styles.width.value,
      height: 1.25 * styles.height.value / styles.width.value,
      fontWeight: styles.bold ? FontWeight.bold : FontWeight.normal,
      decoration: styles.underline ? TextDecoration.underline : null,
    ),
  );

  @override
  List<int> text(
    String text, {
    PosStyles styles = const PosStyles(),
    int linesAfter = 0,
    bool containsChinese = false,
    int? maxCharsPerLine,
  }) {
    children.add(_text(text, styles));
    if (linesAfter > 0) children.add(SizedBox(height: 20.0 * linesAfter));
    return super.text(
      text,
      styles: styles,
      linesAfter: linesAfter,
      containsChinese: containsChinese,
      maxCharsPerLine: maxCharsPerLine,
    );
  }

  @override
  List<int> row(List<PosColumn> cols, {bool multiLine = true}) {
    // Generator.row recursively emits overflow rows; capture the logical row
    // once and let its columns wrap on screen.
    if (_insideRow) return super.row(cols, multiLine: multiLine);
    children.add(
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final col in cols)
            Expanded(flex: col.width, child: _text(col.text, col.styles)),
        ],
      ),
    );
    _insideRow = true;
    try {
      return super.row(cols, multiLine: multiLine);
    } finally {
      _insideRow = false;
    }
  }

  @override
  List<int> image(
    img.Image imgSrc, {
    PosAlign align = PosAlign.center,
    bool isDoubleDensity = true,
  }) {
    children.add(
      Center(
        child: Image.memory(
          Uint8List.fromList(img.encodePng(img.grayscale(imgSrc.clone()))),
          width: imgSrc.width * 0.8,
        ),
      ),
    );
    return super.image(imgSrc, align: align, isDoubleDensity: isDoubleDensity);
  }

  @override
  List<int> qrcode(
    String text, {
    PosAlign align = PosAlign.center,
    QRSize size = QRSize.size4,
    QRCorrection cor = QRCorrection.L,
  }) {
    children.add(Center(child: QrImageView(data: text, size: 160)));
    return super.qrcode(text, align: align, size: size, cor: cor);
  }

  @override
  List<int> feed(int n) {
    children.add(SizedBox(height: n * 20.0));
    return super.feed(n);
  }
}

class PreparedReceipt {
  final List<int> bytes;
  final List<Widget> content;
  const PreparedReceipt(this.bytes, this.content);
}

/// Loads again at confirmation, comparing the same timestamped render. A
/// changed document is shown for another review, never silently substituted.
class ReceiptPreviewSheet extends StatefulWidget {
  final String title;
  final Future<PreparedReceipt> Function() load;
  final Future<String?> Function(List<int>) send;
  final bool Function() offline;

  const ReceiptPreviewSheet({
    super.key,
    required this.title,
    required this.load,
    required this.send,
    required this.offline,
  });

  @override
  State<ReceiptPreviewSheet> createState() => _ReceiptPreviewSheetState();
}

class _ReceiptPreviewSheetState extends State<ReceiptPreviewSheet> {
  PreparedReceipt? _receipt;
  bool _busy = true;
  bool _retry = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final receipt = await widget.load();
      if (mounted) setState(() => _receipt = receipt);
    } catch (_) {
      if (mounted) setState(() => _message = context.l10n.prnErrFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    var sending = false;
    try {
      final latest = await widget.load();
      if (!mounted) return;
      if (_receipt == null || !listEquals(latest.bytes, _receipt!.bytes)) {
        setState(() {
          _receipt = latest;
          _message =
              '${context.l10n.prnPreviewChanged}'
              '${_retry ? '\n${context.l10n.prnPreviewRetryHint}' : ''}';
        });
        return;
      }
      sending = true;
      final error = await widget.send(_receipt!.bytes);
      if (!mounted) return;
      if (error == null) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _retry = true;
          _message = '$error\n${context.l10n.prnPreviewRetryHint}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _retry = _retry || sending;
          _message =
              '${context.l10n.prnErrFailed}'
              '${_retry ? '\n${context.l10n.prnPreviewRetryHint}' : ''}';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: FractionallySizedBox(
      heightFactor: 0.9,
      child: SafeArea(
        child: Column(
          children: [
            SatSheetHeader(
              onClose: () {
                if (!_busy) Navigator.of(context).pop(false);
              },
              child: Text(widget.title),
            ),
            if (widget.offline())
              Padding(
                padding: const EdgeInsets.all(Sp.s3),
                child: Text(context.l10n.prnPreviewOffline),
              ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.all(Sp.s3),
                child: Text(_message!),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Sp.s3),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    width: 332,
                    padding: const EdgeInsets.all(Sp.s3),
                    color: satPaperGround,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _receipt?.content ?? const [],
                    ),
                  ),
                ),
              ),
            ),
            if (_busy) const LinearProgressIndicator(),
            Padding(
              padding: const EdgeInsets.all(Sp.s4),
              child: SatButton.primary(
                label: _retry || _receipt == null
                    ? context.l10n.retry
                    : context.l10n.prnPreviewPrint,
                icon: Icons.print_rounded,
                onTap: _busy ? null : _confirm,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
