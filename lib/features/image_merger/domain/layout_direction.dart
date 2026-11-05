import 'dart:math' as math;

import '../../../core/image_size.dart';
import 'output_settings.dart';

/// [vertical]은 위에서 아래로 쌓고, [horizontal]은 왼쪽에서 오른쪽으로 붙인다.
enum LayoutDirection {
  vertical('vertical'),
  horizontal('horizontal');

  const LayoutDirection(this.code);

  /// DB에 쓰는 값.
  final String code;

  static LayoutDirection? fromCode(String? code) {
    for (final d in values) {
      if (d.code == code) return d;
    }
    return null;
  }
}

/// 용지를 고르면 용지 비율로, '원본 크기'([paper]가 null)면 이미지 비율로 정한다 (DESIGN §2.1.2).
LayoutDirection pngDirection(Iterable<ImageSize> sizes, PaperDimensions? paper) =>
    paper == null ? decideDirection(sizes) : decideDirectionForPaper(paper);

/// A4 세로는 가로 배치(페이지를 옆으로), A4 가로는 세로 배치(위아래로)다.
LayoutDirection decideDirectionForPaper(PaperDimensions paper) =>
    paper.widthMm >= paper.heightMm ? LayoutDirection.vertical : LayoutDirection.horizontal;

/// 비율(가로÷세로)의 기하 평균이 1 이상이면 세로 배치, 1 미만이면 가로 배치 (DESIGN §2.1.2).
/// 결과가 정사각형에 가까워지게 하려는 규칙이다.
/// 기하 평균 ≥ 1 ⇔ Σ ln r ≥ 0. 부동소수점 오차로 1 바로 아래가 되는 경우를 위해 −1e−9까지 허용한다.
LayoutDirection decideDirection(Iterable<ImageSize> sizes) {
  var sum = 0.0;
  var count = 0;
  for (final s in sizes) {
    sum += math.log(s.width / s.height);
    count++;
  }
  if (count == 0) throw ArgumentError.value(sizes, 'sizes', 'must not be empty');
  return sum >= -1e-9 ? LayoutDirection.vertical : LayoutDirection.horizontal;
}
