import 'dart:math' as math;

import 'image_size.dart';

/// 영역 편집기에서 끄는 부위. [move]는 사각형 안쪽을 끌어 옮긴다.
enum CropHandle { topLeft, top, topRight, right, bottomRight, bottom, bottomLeft, left, move }

/// 비율 좌표 ([x], [y])에서 잡히는 부위. [toleranceX]·[toleranceY]는 비율 단위의 터치 허용 범위다.
/// 사각형 안쪽에서는 허용 범위를 변 길이의 1/3까지 줄여, 작은 영역도 가운데를 끌면 옮겨진다.
/// 두 변이 다 허용 범위 안이면 가까운 쪽을 잡는다. 어디에도 안 닿으면 null.
CropHandle? cropHandleAt(CropRect r, double x, double y, double toleranceX, double toleranceY) {
  final insideX = x > r.left && x < r.right;
  final insideY = y > r.top && y < r.bottom;
  if (x < r.left - toleranceX || x > r.right + toleranceX) return null;
  if (y < r.top - toleranceY || y > r.bottom + toleranceY) return null;

  final limitX = insideX ? math.min(toleranceX, r.width / 3) : toleranceX;
  final limitY = insideY ? math.min(toleranceY, r.height / 3) : toleranceY;
  final toLeft = (x - r.left).abs();
  final toRight = (x - r.right).abs();
  final toTop = (y - r.top).abs();
  final toBottom = (y - r.bottom).abs();
  final horizontal = math.min(toLeft, toRight) > limitX ? null : (toLeft <= toRight ? -1 : 1);
  final vertical = math.min(toTop, toBottom) > limitY ? null : (toTop <= toBottom ? -1 : 1);

  return switch ((horizontal, vertical)) {
    (-1, -1) => CropHandle.topLeft,
    (1, -1) => CropHandle.topRight,
    (1, 1) => CropHandle.bottomRight,
    (-1, 1) => CropHandle.bottomLeft,
    (null, -1) => CropHandle.top,
    (null, 1) => CropHandle.bottom,
    (-1, null) => CropHandle.left,
    (1, null) => CropHandle.right,
    _ => insideX && insideY ? CropHandle.move : null,
  };
}

/// 항목에서 쓸 영역. EXIF 반영 후 가로·세로에 대한 0~1 비율 좌표다 (DESIGN §2.1.6).
/// 원본 파일은 고치지 않고 디코딩할 때 적용한다.
class CropRect {
  const CropRect(this.left, this.top, this.right, this.bottom)
      : assert(left >= 0 && top >= 0 && right <= 1 && bottom <= 1),
        assert(left < right && top < bottom);

  static const full = CropRect(0, 0, 1, 1);

  /// 가로·세로 각각 원본 대비 최소 비율.
  static const double minFraction = 0.02;

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;
  bool get isFull => left <= 0 && top <= 0 && right >= 1 && bottom >= 1;

  /// 원본 크기 [source]에 적용한 픽셀 크기. 반올림해도 원본을 넘지 않고 최소 1px이다.
  ImageSize applyTo(ImageSize source) => ImageSize(
        (source.width * width).round().clamp(1, source.width),
        (source.height * height).round().clamp(1, source.height),
      );

  /// [handle]을 비율 좌표로 ([dx], [dy])만큼 끈 결과. 경계를 넘거나 최소 크기보다 작아지지 않는다.
  CropRect drag(CropHandle handle, double dx, double dy) {
    if (handle == CropHandle.move) {
      final x = (left + dx).clamp(0.0, 1 - width);
      final y = (top + dy).clamp(0.0, 1 - height);
      // 부동소수점 오차로 1을 살짝 넘지 않게 끝을 잘라 둔다.
      return CropRect(x, y, math.min(1.0, x + width), math.min(1.0, y + height));
    }
    var l = left, t = top, r = right, b = bottom;
    if (const {CropHandle.topLeft, CropHandle.left, CropHandle.bottomLeft}.contains(handle)) {
      l = (left + dx).clamp(0.0, right - minFraction);
    }
    if (const {CropHandle.topRight, CropHandle.right, CropHandle.bottomRight}.contains(handle)) {
      r = (right + dx).clamp(left + minFraction, 1.0);
    }
    if (const {CropHandle.topLeft, CropHandle.top, CropHandle.topRight}.contains(handle)) {
      t = (top + dy).clamp(0.0, bottom - minFraction);
    }
    if (const {CropHandle.bottomLeft, CropHandle.bottom, CropHandle.bottomRight}.contains(handle)) {
      b = (bottom + dy).clamp(top + minFraction, 1.0);
    }
    return CropRect(l, t, r, b);
  }

  /// 플랫폼 채널로 넘기는 값. 전체 영역이면 null이라 네이티브가 자르지 않는다.
  List<double>? toChannelValue() => isFull ? null : [left, top, right, bottom];

  @override
  bool operator ==(Object other) =>
      other is CropRect &&
      other.left == left &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);

  @override
  String toString() => 'CropRect($left, $top, $right, $bottom)';
}
