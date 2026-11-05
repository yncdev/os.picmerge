import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../../core/config/limits.dart';
import '../../../core/errors/merge_exception.dart';
import '../domain/page_layout.dart';

class PngResult {
  const PngResult({
    required this.bytes,
    required this.width,
    required this.height,
    required this.scale,
  });

  final Uint8List bytes;
  final int width;
  final int height;

  /// 20MB를 맞추려고 추가로 줄인 비율. 줄이지 않았으면 1.
  final double scale;
}

/// PNG 캔버스. 별도 isolate 안에서만 쓴다 (DESIGN §3.1).
/// 캔버스는 한 벌만 둔다: [img.Image]의 픽셀 버퍼에 직접 복사하고 그대로 인코딩한다.
/// (`Image.fromBytes`는 버퍼를 복사하므로 쓰지 않는다.)
class PngCompositor {
  /// 캔버스는 4채널이어도 불투명한 흰색에서 시작해 이미지가 닿지 않는 곳이 흰 여백으로 남는다.
  /// 이미지의 투명 픽셀은 복사가 자리를 통째로 덮어쓰므로 그대로 투명하다 (DESIGN §2.1.2).
  PngCompositor({
    required this.width,
    required this.height,
    required this.channels,
  })  : assert(channels == 3 || channels == 4),
        _canvas = img.Image(width: width, height: height, numChannels: channels) {
    _pixels = _canvas.toUint8List(); // 복사가 아니라 같은 버퍼의 뷰, 행 간격 = width × channels
    _pixels.fillRange(0, _pixels.length, 255);
  }

  final int width;
  final int height;
  final int channels;
  final img.Image _canvas;
  late final Uint8List _pixels;

  /// 줄여서 다시 인코딩할 때 다시 그을 구분선.
  var _dividers = const <PixelRect>[];

  int get _canvasRowBytes => width * channels;

  /// raw 픽셀(행 단위, 패딩 없음)을 ([x], [y]) 위치에 복사한다.
  void blit(Uint8List raw, {required int x, required int y, required int width, required int height}) {
    final rowBytes = _checkPlacement(raw.length, x: x, y: y, width: width, height: height);
    for (var r = 0; r < height; r++) {
      final dst = (y + r) * _canvasRowBytes + x * channels;
      _pixels.setRange(dst, dst + rowBytes, raw, r * rowBytes);
    }
  }

  /// 네이티브가 쓴 raw 파일을 행 단위로 캔버스에 바로 읽어 들인다. 파일 전체를 메모리에 올리지 않는다.
  void blitFile(File file, {required int x, required int y, required int width, required int height}) {
    final raf = file.openSync();
    try {
      final rowBytes = _checkPlacement(raf.lengthSync(), x: x, y: y, width: width, height: height);
      for (var r = 0; r < height; r++) {
        final dst = (y + r) * _canvasRowBytes + x * channels;
        var filled = 0;
        while (filled < rowBytes) {
          final read = raf.readIntoSync(_pixels, dst + filled, dst + rowBytes);
          if (read <= 0) {
            throw const MergeException(MergeErrorCode.corruptFile, detail: 'raw file ended early');
          }
          filled += read;
        }
      }
    } finally {
      raf.closeSync();
    }
  }

  int _checkPlacement(int length, {required int x, required int y, required int width, required int height}) {
    final rowBytes = width * channels;
    if (length != rowBytes * height) {
      throw MergeException(
        MergeErrorCode.corruptFile,
        detail: 'raw size $length != ${rowBytes * height}',
      );
    }
    if (x < 0 || y < 0 || x + width > this.width || y + height > this.height) {
      throw ArgumentError('placement ($x,$y ${width}x$height) is outside the canvas');
    }
    return rowBytes;
  }

  /// 구분선(#D0D0D0)을 칠한다. 4채널 캔버스에서도 불투명이다 (DESIGN §2.1.2).
  void drawDividers(List<PixelRect> dividers) {
    for (final d in dividers) {
      if (d.x < 0 || d.y < 0 || d.x + d.width > width || d.y + d.height > height) {
        throw ArgumentError('divider $d is outside the canvas');
      }
    }
    _dividers = dividers;
    _paintDividers(_pixels, width, height, dividers);
  }

  /// 줄인 캔버스는 선이 끝에 걸릴 수 있어 캔버스 안쪽만 칠한다.
  void _paintDividers(Uint8List pixels, int canvasWidth, int canvasHeight, List<PixelRect> dividers) {
    final canvasRowBytes = canvasWidth * channels;
    for (final d in dividers) {
      final left = math.max(0, d.x);
      final right = math.min(canvasWidth, d.x + d.width);
      final top = math.max(0, d.y);
      final bottom = math.min(canvasHeight, d.y + d.height);
      if (left >= right || top >= bottom) continue;
      final rowBytes = (right - left) * channels;
      final row = Uint8List(rowBytes)..fillRange(0, rowBytes, kDividerGray);
      if (channels == 4) {
        for (var i = 3; i < rowBytes; i += 4) {
          row[i] = 255;
        }
      }
      for (var r = top; r < bottom; r++) {
        final dst = r * canvasRowBytes + left * channels;
        pixels.setRange(dst, dst + rowBytes, row);
      }
    }
  }

  /// 캔버스를 [w]×[h]로 줄인 사본. 줄인 픽셀마다 그 자리의 원본 픽셀을 평균한다.
  /// 4채널은 알파를 곱한 값으로 평균한다. 그대로 평균하면 투명 픽셀(0,0,0,0)의 검정이 섞여
  /// 흰색의 가장자리가 127,127,127,127처럼 어두워진다. 캔버스 사본은 이것 하나뿐이다.
  img.Image shrink(int w, int h) {
    final out = img.Image(width: w, height: h, numChannels: channels);
    final dst = out.toUint8List();
    final rowBytes = _canvasRowBytes;
    var d = 0;
    for (var y = 0; y < h; y++) {
      final top = y * height ~/ h;
      final bottom = math.max(top + 1, (y + 1) * height ~/ h);
      for (var x = 0; x < w; x++) {
        final left = x * width ~/ w;
        final right = math.max(left + 1, (x + 1) * width ~/ w);
        var r = 0;
        var g = 0;
        var b = 0;
        var a = 0;
        for (var sy = top; sy < bottom; sy++) {
          var s = sy * rowBytes + left * channels;
          for (var sx = left; sx < right; sx++, s += channels) {
            if (channels == 4) {
              final alpha = _pixels[s + 3];
              r += _pixels[s] * alpha;
              g += _pixels[s + 1] * alpha;
              b += _pixels[s + 2] * alpha;
              a += alpha;
            } else {
              r += _pixels[s];
              g += _pixels[s + 1];
              b += _pixels[s + 2];
            }
          }
        }
        final count = (bottom - top) * (right - left);
        // 색의 분모는 4채널이면 알파의 합, 3채널이면 픽셀 수다. 0.5는 올린다.
        final weight = channels == 4 ? a : count;
        if (weight > 0) {
          dst[d] = (2 * r + weight) ~/ (2 * weight);
          dst[d + 1] = (2 * g + weight) ~/ (2 * weight);
          dst[d + 2] = (2 * b + weight) ~/ (2 * weight);
        }
        if (channels == 4) dst[d + 3] = (2 * a + count) ~/ (2 * count);
        d += channels;
      }
    }
    return out;
  }

  /// 인코딩 결과가 [maxBytes]를 넘으면 √(maxBytes ÷ 크기) × 0.9 비율로 줄여 다시 인코딩한다
  /// (최대 [maxReencodes]회). 그래도 넘으면 output_too_large (DESIGN §2.1.2).
  /// 줄이면 구분선이 흐려지므로 줄인 캔버스에 다시 긋는다. 줄인 사본은 그 회차의 인코딩이 끝나면 놓는다.
  PngResult encode({
    int maxBytes = kMaxOutputBytes,
    int maxReencodes = kPngMaxReencodes,
  }) {
    var png = img.encodePng(_canvas);
    var factor = 1.0;
    var w = width;
    var h = height;
    for (var i = 0; png.length > maxBytes && i < maxReencodes; i++) {
      factor *= math.sqrt(maxBytes / png.length) * 0.9;
      w = math.max(1, (width * factor).floor());
      h = math.max(1, (height * factor).floor());
      final resized = shrink(w, h);
      _paintDividers(
        resized.toUint8List(),
        w,
        h,
        scaleDividers(
          _dividers,
          fromWidth: width,
          fromHeight: height,
          toWidth: w,
          toHeight: h,
        ),
      );
      png = img.encodePng(resized);
    }
    if (png.length > maxBytes) {
      throw MergeException(MergeErrorCode.outputTooLarge, detail: '${png.length} bytes');
    }
    return PngResult(bytes: png, width: w, height: h, scale: w / width);
  }
}
