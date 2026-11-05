import 'dart:math' as math;

import '../../../core/config/limits.dart';
import '../../../core/image_size.dart';
import 'output_settings.dart';

/// 용지 한 장의 칸 배치.
class PageGrid {
  const PageGrid({required this.columns, required this.rows});

  final int columns;
  final int rows;

  @override
  bool operator ==(Object other) => other is PageGrid && other.columns == columns && other.rows == rows;

  @override
  int get hashCode => Object.hash(columns, rows);

  @override
  String toString() => '$columns×$rows';
}

/// 용지 위의 사각형. 단위는 부르는 쪽이 정한다 (PNG는 픽셀, PDF는 포인트, 미리보기는 논리 픽셀).
class LayoutRect {
  const LayoutRect(this.left, this.top, this.width, this.height);

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;

  @override
  String toString() => 'LayoutRect($left, $top, $width, $height)';
}

/// 정수 픽셀 사각형. 구분선은 PNG에만 있어 픽셀로 잰다.
class PixelRect {
  const PixelRect(this.x, this.y, this.width, this.height);

  final int x;
  final int y;
  final int width;
  final int height;

  @override
  bool operator ==(Object other) =>
      other is PixelRect && other.x == x && other.y == y && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(x, y, width, height);

  @override
  String toString() => 'PixelRect($x, $y, $width, $height)';
}

/// 용지 한 장 안에 놓인 이미지.
class SheetImage {
  const SheetImage({required this.imageIndex, required this.rect});

  /// 입력 목록에서의 위치 (0부터).
  final int imageIndex;
  final LayoutRect rect;
}

/// 용지당 이미지 수와 용지 방향으로 칸 배치를 정한다 (DESIGN §2.1.2 표).
/// 표의 값은 '짧은 변 칸 수 × 긴 변 칸 수'라 세로 용지의 짧은 변은 폭, 가로 용지의 짧은 변은 높이다.
PageGrid pageGrid(int imagesPerPaper, PaperOrientation orientation) {
  final (shortCells, longCells) = switch (imagesPerPaper) {
    1 => (1, 1),
    2 => (1, 2),
    3 => (1, 3),
    4 => (2, 2),
    6 => (2, 3),
    8 => (2, 4),
    9 => (3, 3),
    _ => throw ArgumentError.value(imagesPerPaper, 'imagesPerPaper', 'unsupported'),
  };
  return orientation == PaperOrientation.portrait
      ? PageGrid(columns: shortCells, rows: longCells)
      : PageGrid(columns: longCells, rows: shortCells);
}

/// 페이지 수 = ⌈항목 수 ÷ 용지당 이미지 수⌉.
int sheetCount(int itemCount, int imagesPerPaper) => (itemCount + imagesPerPaper - 1) ~/ imagesPerPaper;

/// 칸을 왼쪽에서 오른쪽, 위에서 아래 순으로 돌려준다.
/// 네 변의 여백은 짧은 변의 [marginPercent]%이고 칸은 그 안쪽에서 나눈다.
/// 칸 사이 간격은 여백의 0.8배다. PNG는 구분선이 들어갈 자리로 [minGap]에 두께를 준다.
/// 그래서 여백 0%면 PDF는 칸이 맞닿고 PNG는 칸 사이가 정확히 구분선 두께다.
/// 여백·간격·칸 크기는 실수 그대로 두고, 픽셀이 필요하면 사각형의 각 변을 [snapRect]로 맞춘다.
List<LayoutRect> cellRects(
  double pageWidth,
  double pageHeight,
  PageGrid grid, {
  required int marginPercent,
  double minGap = 0,
}) {
  final margin = math.min(pageWidth, pageHeight) * marginPercent / 100;
  final gap = math.max(minGap, margin * kCellGapPerMargin);
  final width = (pageWidth - 2 * margin - gap * (grid.columns - 1)) / grid.columns;
  final height = (pageHeight - 2 * margin - gap * (grid.rows - 1)) / grid.rows;
  return [
    for (var row = 0; row < grid.rows; row++)
      for (var column = 0; column < grid.columns; column++)
        LayoutRect(margin + column * (width + gap), margin + row * (height + gap), width, height),
  ];
}

/// 비율을 유지해 칸에 가장 크게 맞춘 뒤 가로·세로에 [factor]를 곱하고 칸 가운데에 놓는다.
/// 작은 이미지도 칸에 맞춰 키운다.
LayoutRect fitInCell(ImageSize image, LayoutRect cell, double factor) {
  final scale = math.min(cell.width / image.width, cell.height / image.height) * factor;
  final width = image.width * scale;
  final height = image.height * scale;
  return LayoutRect(
    cell.left + (cell.width - width) / 2,
    cell.top + (cell.height - height) / 2,
    width,
    height,
  );
}

/// 항목을 순서대로 N개씩 묶어 용지마다 칸에 넣는다. PNG·PDF·미리보기가 모두 이 계산을 쓴다.
List<List<SheetImage>> layoutSheets(
  List<ImageSize> sizes, {
  required double pageWidth,
  required double pageHeight,
  required OutputSettings settings,
  double minGap = 0,
}) {
  final n = settings.imagesPerPaper;
  final cells = cellRects(
    pageWidth,
    pageHeight,
    pageGrid(n, settings.orientation),
    marginPercent: settings.marginPercent,
    minGap: minGap,
  );
  final factor = settings.imageSizePercent / 100;
  return [
    for (var sheet = 0; sheet < sheetCount(sizes.length, n); sheet++)
      [
        for (var i = sheet * n; i < math.min(sizes.length, (sheet + 1) * n); i++)
          SheetImage(imageIndex: i, rect: fitInCell(sizes[i], cells[i - sheet * n], factor)),
      ],
  ];
}

/// 반올림(0.5는 올림). 손으로 계산한 .5가 부동소수점 오차로 내려가지 않게 작은 값을 더한다.
/// Chrome 확장의 `snap`과 같아야 두 플랫폼의 결과가 같다 (DESIGN §2.1.2).
int snapPx(double value) => (value + 0.5 + 1e-9).floor();

/// 사각형의 네 변을 각각 반올림한다. 폭을 더해 가지 않아 반올림 오차가 쌓이지 않는다.
PixelRect snapRect(LayoutRect rect) {
  final left = snapPx(rect.left);
  final top = snapPx(rect.top);
  return PixelRect(
    left,
    top,
    math.max(1, snapPx(rect.right) - left),
    math.max(1, snapPx(rect.bottom) - top),
  );
}

/// 구분선 두께 = 기준 변의 0.3%, 최소 2px (DESIGN §2.1.2).
int dividerThickness(int side) => math.max(kMinDividerPx, snapPx(side * kDividerRatio));

/// 캔버스를 줄인 뒤 다시 그을 구분선. 그대로 줄이면 선이 흐려져 색이 옅어지고 2px보다 가늘어진다
/// (DESIGN §2.1.2). 줄인 칸 i는 원본 [⌊i × 원본 ÷ 줄인 크기⌋, ⌊(i + 1) × 원본 ÷ 줄인 크기⌋)의 평균이므로,
/// 옛 선이 닿은 칸을 모두 덮어 옆에 중간 색이 남지 않게 한다. 두께는 최소 2px이다.
List<PixelRect> scaleDividers(
  List<PixelRect> dividers, {
  required int fromWidth,
  required int fromHeight,
  required int toWidth,
  required int toHeight,
}) {
  (int, int) covered(int start, int length, int from, int to, {int minSize = 1}) {
    var first = ((start + 1) * to + from - 1) ~/ from - 1;
    final size = math.max(minSize, ((start + length) * to + from - 1) ~/ from - first);
    if (first + size > to) first = math.max(0, to - size);
    return (first, size);
  }

  return [
    for (final d in dividers)
      () {
        final vertical = d.width < d.height;
        final (x, width) = covered(
          d.x,
          d.width,
          fromWidth,
          toWidth,
          minSize: vertical ? kMinDividerPx : 1,
        );
        final (y, height) = covered(
          d.y,
          d.height,
          fromHeight,
          toHeight,
          minSize: vertical ? 1 : kMinDividerPx,
        );
        return PixelRect(x, y, width, height);
      }(),
  ];
}

/// 용지 한 장 안의 구분선 (용지 좌표). 구분선은 PNG에만 있다.
/// [filled]는 이 용지에 이미지가 들어간 칸 수다.
/// 가로줄은 아래 줄에 이미지가 있을 때 여백 안쪽 폭 전체로, 세로줄은 같은 줄의 양쪽 칸에 모두 이미지가
/// 있을 때 그 줄 높이만큼 칸 사이 간격의 가운데에 긋는다.
List<PixelRect> sheetDividers({
  required int pageWidth,
  required int pageHeight,
  required PageGrid grid,
  required int filled,
  required int thickness,
  required int marginPercent,
}) {
  final cells = cellRects(
    pageWidth.toDouble(),
    pageHeight.toDouble(),
    grid,
    marginPercent: marginPercent,
    minGap: thickness.toDouble(),
  );
  final gap = grid.rows > 1
      ? cells[grid.columns].top - cells.first.bottom
      : grid.columns > 1
          ? cells[1].left - cells.first.right
          : 0.0;
  final inset = (gap - thickness) / 2;
  final left = snapPx(cells.first.left);
  final right = snapPx(cells.last.right);
  LayoutRect cell(int row, int column) => cells[row * grid.columns + column];
  final dividers = <PixelRect>[];
  for (var row = 0; row < grid.rows; row++) {
    if (row > 0 && filled > row * grid.columns) {
      dividers.add(PixelRect(left, snapPx(cell(row - 1, 0).bottom + inset), right - left, thickness));
    }
    for (var column = 1; column < grid.columns; column++) {
      if (row * grid.columns + column >= filled) break;
      final previous = cell(row, column - 1);
      final top = snapPx(previous.top);
      dividers.add(PixelRect(
        snapPx(previous.right + inset),
        top,
        thickness,
        snapPx(previous.bottom) - top,
      ));
    }
  }
  return dividers;
}
