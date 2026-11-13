// Every photo pick holds SatSet in the foreground (CaptureGuardService.kt) and
// always lets go — a release that a failure skips leaves a notification up and
// the process pinned until Android's three-minute limit.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:satset/ui/core/widgets/proof_photo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const guard = MethodChannel('satset/capture');
  final log = <String>[];
  late ImagePickerPlatform original;

  void stubGuard({bool refuse = false}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(guard, (call) async {
          log.add(call.method);
          if (refuse) throw PlatformException(code: 'capture_guard');
          return null;
        });
  }

  setUp(() {
    log.clear();
    original = ImagePickerPlatform.instance;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    ImagePickerPlatform.instance = original;
    debugDefaultTargetPlatformOverride = null;
  });

  test('the camera opens inside the hold', () async {
    stubGuard();
    ImagePickerPlatform.instance = _Picker(() {
      log.add('camera');
      return XFile.fromData(Uint8List.fromList([1, 2]), name: 'p.jpg');
    });
    expect(await shootProofPhoto(), [1, 2]);
    expect(log, ['hold', 'camera', 'release']);
  });

  test('a failed capture still releases, and the failure reaches the caller', () async {
    stubGuard();
    ImagePickerPlatform.instance = _Picker(
      () => throw PlatformException(code: 'camera_access_denied'),
    );
    await expectLater(shootProofPhoto(), throwsA(isA<PlatformException>()));
    expect(log, ['hold', 'release']);
  });

  test('a refused hold does not stop the camera', () async {
    stubGuard(refuse: true);
    ImagePickerPlatform.instance = _Picker(() {
      log.add('camera');
      return null;
    });
    expect(await shootProofPhoto(), isNull);
    expect(log, ['hold', 'camera', 'release']);
  });
}

class _Picker extends ImagePickerPlatform {
  _Picker(this.shoot);
  final XFile? Function() shoot;

  @override
  Future<XFile?> getImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async => shoot();
}
