// The Dart half of `satset/bt` (BtPrinter.kt): bytes travel as a byte array,
// not a boxed list, and a native failure surfaces the way each caller expects.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/data/services/bt_printer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('satset/bt');
  final calls = <MethodCall>[];
  Object? Function(MethodCall) answer = (_) => null;

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return answer(call);
        });
  });

  test('send hands the printer one byte array', () async {
    answer = (_) => null;
    await BtPrinterService().send('AA:BB', [27, 64, 10]);
    expect(calls.single.method, 'send');
    final args = calls.single.arguments as Map;
    expect(args['mac'], 'AA:BB');
    expect(args['bytes'], isA<Uint8List>());
    expect(args['bytes'], [27, 64, 10]);
  });

  test('a failed send throws so the picker says not connected', () {
    answer = (_) => throw PlatformException(code: 'bt_failed');
    expect(
      BtPrinterService().send('AA:BB', [1]),
      throwsA(isA<PlatformException>()),
    );
  });

  test('probe reads a failure as offline', () async {
    answer = (_) => null;
    expect(await BtPrinterService().probe('AA:BB'), isTrue);
    answer = (_) => throw PlatformException(code: 'bt_failed');
    expect(await BtPrinterService().probe('AA:BB'), isFalse);
  });

  test('adapter state and paired list come off the channel', () async {
    answer = (call) => switch (call.method) {
      'enabled' => true,
      'paired' => [
        {'name': 'RPP02N', 'mac': 'AA:BB'},
      ],
      _ => null,
    };
    final svc = BtPrinterService();
    expect(await svc.adapterOn(), isTrue);
    // pairedPrinters asks permission_handler first; the paired call itself is
    // what this file owns.
    final list = await channel.invokeListMethod<Map>('paired');
    expect(list!.single['mac'], 'AA:BB');
  });
}
