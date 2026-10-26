import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import 'video_task.dart';
import 'watermark_kit_platform_interface.dart';

/// Temporary OHOS implementation that completes requests without watermarking.
class OhosWatermarkKit extends WatermarkKitPlatform {
  static const MethodChannel _channel = MethodChannel('watermark_kit');
  static int _nextTaskId = 0;

  static void registerWith() {
    WatermarkKitPlatform.instance = OhosWatermarkKit();
  }

  @override
  Future<String?> getPlatformVersion() =>
      _channel.invokeMethod<String>('getPlatformVersion');

  @override
  Future<Uint8List> composeImage({
    required Uint8List inputImage,
    required Uint8List watermarkImage,
    String anchor = 'bottomRight',
    double margin = 16.0,
    double widthPercent = 0.18,
    double opacity = 0.6,
    String format = 'jpeg',
    double quality = 0.9,
    double offsetX = 0.0,
    double offsetY = 0.0,
    String marginUnit = 'px',
    String offsetUnit = 'px',
  }) async => inputImage;

  @override
  Future<Uint8List> composeTextImage({
    required Uint8List inputImage,
    required String text,
    String anchor = 'bottomRight',
    double margin = 16.0,
    String marginUnit = 'px',
    double offsetX = 0.0,
    double offsetY = 0.0,
    String offsetUnit = 'px',
    double widthPercent = 0.18,
    double opacity = 0.6,
    String format = 'jpeg',
    double quality = 0.9,
    String fontFamily = '.SFUI',
    double fontSizePt = 24.0,
    int fontWeight = 600,
    int colorArgb = 0xFFFFFFFF,
  }) async => inputImage;

  @override
  Future<VideoTask> composeVideo({
    required String inputVideoPath,
    String? outputVideoPath,
    Uint8List? watermarkImage,
    String? text,
    String anchor = 'bottomRight',
    double margin = 16.0,
    String marginUnit = 'px',
    double offsetX = 0.0,
    double offsetY = 0.0,
    String offsetUnit = 'px',
    double widthPercent = 0.18,
    double opacity = 0.6,
    String codec = 'h264',
    int? bitrateBps,
    double? maxFps,
    int? maxLongSide,
  }) async {
    final source = File(inputVideoPath);
    final path =
        outputVideoPath == null || outputVideoPath.isEmpty
            ? inputVideoPath
            : outputVideoPath;
    if (path == inputVideoPath) {
      if (!await source.exists()) {
        throw FileSystemException(
          'Video source does not exist',
          inputVideoPath,
        );
      }
    } else {
      await source.copy(path);
    }

    final taskId =
        'wm_ohos_${DateTime.now().microsecondsSinceEpoch}_${_nextTaskId++}';
    return VideoTask(
      taskId: taskId,
      progress: Stream<double>.value(1.0),
      done: Future<VideoResult>.value(
        VideoResult(
          path: path,
          width: 0,
          height: 0,
          durationMs: 0,
          codec: codec,
        ),
      ),
      cancel: () async {},
    );
  }

  @override
  Future<void> cancelVideo(String taskId) async {}
}
