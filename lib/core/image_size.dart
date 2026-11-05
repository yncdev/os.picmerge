import 'dart:math' as math;

/// EXIF 회전을 반영한 가로·세로 픽셀 크기.
class ImageSize {
  const ImageSize(this.width, this.height)
      : assert(width > 0),
        assert(height > 0);

  final int width;
  final int height;

  double get aspectRatio => width / height;

  int get longSide => math.max(width, height);

  /// 긴 변이 [maxLongSide]를 넘으면 비율을 유지하며 줄인다. 넘지 않으면 그대로.
  ImageSize capLongSide(int maxLongSide) {
    if (longSide <= maxLongSide) return this;
    final factor = maxLongSide / longSide;
    return ImageSize(
      math.max(1, (width * factor).round()),
      math.max(1, (height * factor).round()),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ImageSize && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => '${width}x$height';
}
