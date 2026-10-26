import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watermark_kit/watermark_kit.dart';
import 'package:watermark_kit/watermark_kit_ohos.dart';
import 'package:watermark_kit/watermark_kit_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late WatermarkKitPlatform previousPlatform;
  late Directory tempDir;

  setUp(() async {
    previousPlatform = WatermarkKitPlatform.instance;
    OhosWatermarkKit.registerWith();
    tempDir = await Directory.systemTemp.createTemp('watermark_kit_ohos_');
  });

  tearDown(() async {
    WatermarkKitPlatform.instance = previousPlatform;
    await tempDir.delete(recursive: true);
  });

  test('image and text requests return the original bytes', () async {
    final kit = WatermarkKit();
    final input = Uint8List.fromList([1, 2, 3, 4]);
    final watermark = Uint8List.fromList([5, 6]);

    expect(
      await kit.composeImage(inputImage: input, watermarkImage: watermark),
      input,
    );
    expect(await kit.composeTextImage(inputImage: input, text: 'test'), input);
  });

  test('video request copies the original file and completes', () async {
    final input = File('${tempDir.path}/input.mp4');
    final output = File('${tempDir.path}/output.mp4');
    await input.writeAsBytes([1, 2, 3, 4]);

    final task = await WatermarkKit().composeVideo(
      inputVideoPath: input.path,
      outputVideoPath: output.path,
      text: 'test',
      codec: 'hevc',
    );

    expect(await task.progress.toList(), [1.0]);
    final result = await task.done;
    expect(result.path, output.path);
    expect(result.codec, 'hevc');
    expect(result.width, 0);
    expect(result.height, 0);
    expect(result.durationMs, 0);
    expect(await output.readAsBytes(), await input.readAsBytes());
    await task.cancel();
    await WatermarkKitPlatform.instance.cancelVideo(task.taskId);
  });

  test('video request reuses source path when no output is supplied', () async {
    final input = File('${tempDir.path}/input.mp4');
    await input.writeAsBytes([7, 8]);

    final task = await WatermarkKit().composeVideo(inputVideoPath: input.path);

    expect((await task.done).path, input.path);
    expect(await input.readAsBytes(), [7, 8]);
  });

  test('missing input video reports a file error', () async {
    expect(
      WatermarkKit().composeVideo(
        inputVideoPath: '${tempDir.path}/missing.mp4',
      ),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('platform version uses the OHOS native channel', () async {
    const channel = MethodChannel('watermark_kit');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getPlatformVersion');
      return 'OpenHarmony';
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    expect(await WatermarkKit().getPlatformVersion(), 'OpenHarmony');
  });
}
