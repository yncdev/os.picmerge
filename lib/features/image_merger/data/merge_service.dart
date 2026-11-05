import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../../core/config/limits.dart';
import '../../../core/errors/merge_exception.dart';
import '../../../core/platform/native_bridge.dart';
import '../../image_selection/domain/selected_image.dart';
import '../domain/layout_direction.dart';
import '../domain/output_format.dart';
import '../domain/output_settings.dart';
import '../domain/pdf_plan.dart';
import '../domain/png_plan.dart';
import 'merge_worker.dart';

/// 취소 신호. 취소되면 등록한 콜백(워커 종료)을 부른다.
class CancelToken {
  var _cancelled = false;
  final _listeners = <void Function()>[];

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }

  void onCancel(void Function() listener) {
    if (_cancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
  }

  void throwIfCancelled() {
    if (_cancelled) throw const MergeCancelled();
  }
}

sealed class MergeProgress {
  const MergeProgress();
}

/// [completed]장을 마쳤다.
class ProcessingImages extends MergeProgress {
  const ProcessingImages(this.completed, this.total);

  final int completed;
  final int total;
}

/// 인코딩(재인코딩 포함). 걸리는 시간을 알 수 없다.
class BuildingFile extends MergeProgress {
  const BuildingFile();
}

class MergeResult {
  const MergeResult({
    required this.tempPath,
    required this.bytes,
    required this.appliedScales,
    this.width,
    this.height,
    this.direction,
  });

  /// 작업 폴더 안의 결과 파일. 저장 폴더로 복사한 뒤 작업 폴더째 지운다.
  final String tempPath;
  final int bytes;

  /// 이미지별 원본 대비 최종 비율.
  final List<double> appliedScales;

  /// PNG만.
  final int? width;
  final int? height;
  final LayoutDirection? direction;
}

typedef WorkerFactory = Future<MergeWorker> Function();

/// 처리 흐름 2~3단계 (DESIGN §3.1). 한 장씩 네이티브로 디코딩해 워커로 넘긴다.
class MergeService {
  MergeService({required this._bridge, WorkerFactory? spawnWorker})
      : _spawnWorker = spawnWorker ?? MergeWorker.spawn;

  final NativeBridge _bridge;
  final WorkerFactory _spawnWorker;

  Future<MergeResult> merge({
    required List<SelectedImage> images,
    required OutputFormat format,
    required OutputSettings settings,
    required Directory jobDir,
    required CancelToken token,
    required void Function(MergeProgress progress) onProgress,
  }) async {
    if (images.isEmpty) throw ArgumentError.value(images, 'images', 'must not be empty');
    token.throwIfCancelled();
    final worker = await _spawnWorker();
    token.onCancel(worker.kill);
    try {
      return switch (format) {
        OutputFormat.png => await _mergePng(images, settings, jobDir, worker, token, onProgress),
        OutputFormat.pdf => await _mergePdf(images, settings, jobDir, worker, token, onProgress),
      };
    } finally {
      worker.close();
    }
  }

  Future<MergeResult> _mergePng(
    List<SelectedImage> images,
    OutputSettings settings,
    Directory jobDir,
    MergeWorker worker,
    CancelToken token,
    void Function(MergeProgress) onProgress,
  ) async {
    final plan = planPng([for (final i in images) i.size], settings);
    // 용지 캔버스는 이미지의 투명 픽셀을 흰색 위에 합치므로 투명도가 필요 없다.
    final channels = !plan.onPaper && images.any((i) => i.mayHaveAlpha) ? 4 : 3;
    await worker.startPng(
      width: plan.canvasWidth,
      height: plan.canvasHeight,
      channels: channels,
    );
    for (var i = 0; i < images.length; i++) {
      token.throwIfCancelled();
      onProgress(ProcessingImages(i, images.length));
      final place = plan.placements[i];
      final rawPath = p.join(jobDir.path, 'image_$i.raw');
      await _native(
        () => _bridge.decodeRaw(
          path: images[i].path,
          width: place.width,
          height: place.height,
          channels: channels,
          outPath: rawPath,
          crop: images[i].crop,
          grayscale: settings.grayscale,
        ),
        imageNumber: i + 1,
      );
      token.throwIfCancelled();
      await worker.addRaw(
        rawPath: rawPath,
        x: place.x,
        y: place.y,
        width: place.width,
        height: place.height,
      );
    }
    token.throwIfCancelled();
    await worker.drawDividers(plan.dividers);
    onProgress(ProcessingImages(images.length, images.length));
    onProgress(const BuildingFile());
    final outPath = p.join(jobDir.path, 'output.png');
    final out = await worker.finishPng(outPath: outPath, maxBytes: kMaxOutputBytes);
    return MergeResult(
      tempPath: outPath,
      bytes: out.bytes,
      width: out.width,
      height: out.height,
      direction: plan.direction,
      appliedScales: [for (final place in plan.placements) place.scale * out.scale],
    );
  }

  Future<MergeResult> _mergePdf(
    List<SelectedImage> images,
    OutputSettings settings,
    Directory jobDir,
    MergeWorker worker,
    CancelToken token,
    void Function(MergeProgress) onProgress,
  ) async {
    final budget = pdfImageBudget(images.length);
    final scales = <double>[];
    await worker.startPdf();
    for (final page in planPdf([for (final i in images) i.size], settings)) {
      for (final placed in page.images) {
        final i = placed.imageIndex;
        token.throwIfCancelled();
        onProgress(ProcessingImages(i, images.length));
        final image = images[i];
        final jpegPath = p.join(jobDir.path, 'image_$i.jpg');
        JpegAttempt? accepted;
        for (final attempt in pdfJpegAttempts(image.size)) {
          final bytes = await _native(
            () => _bridge.encodeJpeg(
              path: image.path,
              width: attempt.width,
              height: attempt.height,
              quality: attempt.quality,
              outPath: jpegPath,
              crop: image.crop,
              grayscale: settings.grayscale,
            ),
            imageNumber: i + 1,
          );
          token.throwIfCancelled();
          if (bytes <= budget) {
            accepted = attempt;
            break;
          }
        }
        if (accepted == null) {
          throw MergeException(MergeErrorCode.outputTooLarge, imageNumber: i + 1);
        }
        await worker.addPdfImage(jpegPath: jpegPath, rect: placed.rect);
        scales.add(accepted.width / image.size.width);
      }
      await worker.finishPdfPage(widthPt: page.widthPt, heightPt: page.heightPt);
    }
    onProgress(ProcessingImages(images.length, images.length));
    onProgress(const BuildingFile());
    final outPath = p.join(jobDir.path, 'output.pdf');
    final bytes = await worker.finishPdf(outPath: outPath);
    if (bytes > kMaxOutputBytes) {
      throw MergeException(MergeErrorCode.outputTooLarge, detail: '$bytes bytes');
    }
    return MergeResult(tempPath: outPath, bytes: bytes, appliedScales: scales);
  }

  Future<T> _native<T>(Future<T> Function() call, {required int imageNumber}) async {
    try {
      return await call();
    } on PlatformException catch (e) {
      throw MergeException.fromPlatform(e, imageNumber: imageNumber);
    }
  }
}
