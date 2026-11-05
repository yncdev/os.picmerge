import 'dart:math' as math;

import '../../../core/config/limits.dart';
import '../../../core/image_size.dart';
import 'layout_direction.dart';
import 'output_settings.dart';
import 'page_layout.dart';

/// 캔버스 안에서 이미지 한 장이 차지하는 자리. [scale]은 원본 가로 대비 비율이다.
class PngPlacement {
  const PngPlacement({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.scale,
  });

  final int x;
  final int y;
  final int width;
  final int height;
  final double scale;
}

class PngPlan {
  const PngPlan({
    required this.direction,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.placements,
    required this.dividers,
    required this.dividerThickness,
    this.onPaper = false,
  });

  final LayoutDirection direction;
  final int canvasWidth;
  final int canvasHeight;
  final List<PngPlacement> placements;

  /// 캔버스 좌표의 구분선. 색은 어디서나 #D0D0D0이다.
  final List<PixelRect> dividers;
  final int dividerThickness;

  /// 용지 캔버스면 true. 투명도 없이(RGB) 만든다.
  final bool onPaper;

  int get pixelCount => canvasWidth * canvasHeight;
}

/// 총 픽셀이 상한을 넘을 때 곱할 비율. 두께 반올림과 최소 2px 때문에 한 번에 안 들 수 있어
/// 둘째부터는 조금 더 줄여 작은 초과에서 멈추지 않게 한다. Chrome 확장과 같아야 결과가 같다.
double _shrinkFactor(double ratio, int attempt) => math.sqrt(ratio) * (attempt == 0 ? 1 : 0.999);

/// PNG 합성 계획 (DESIGN §2.1.2). [sizes]는 영역 편집을 반영한 크기다.
/// 용지를 고르면 용지 여러 장을 구분선으로 이어 붙이고, '원본 크기'면 이미지 묶음 크기대로 만든다.
/// 캔버스는 어느 쪽이든 불투명한 흰색에서 시작하고 그 위에 이미지와 구분선을 놓는다.
PngPlan planPng(
  List<ImageSize> sizes,
  OutputSettings settings, {
  int maxLongSide = kMaxInputLongSide,
  int maxCanvasPixels = kMaxCanvasPixels,
  int paperDpi = kPngPaperDpi,
}) {
  if (sizes.isEmpty) throw ArgumentError.value(sizes, 'sizes', 'must not be empty');
  final paper = settings.paperDimensions;
  return paper == null
      ? _planOriginal(sizes, settings.marginPercent, maxLongSide, maxCanvasPixels)
      : _planOnPaper(sizes, settings, paper, maxCanvasPixels, paperDpi);
}

/// 1. 각 이미지 긴 변을 [maxLongSide]로 제한한다.
/// 2. 세로 배치는 폭, 가로 배치는 높이를 그 변의 최솟값에 맞춘다 (확대하지 않음).
/// 3. 이미지마다 네 변에 공통 변의 [marginPercent]%를 흰 여백으로 둔다.
/// 4. 이미지 사이에는 양쪽 여백 사이에 구분선을 넣는다: [여백][이미지][여백][선][여백][이미지][여백].
///    두께는 공통 변의 0.3%이고 캔버스 전체 길이로 긋는다.
/// 5. 여백과 구분선까지 합한 캔버스 총 픽셀이 [maxCanvasPixels]를 넘으면 전체를 같은 비율로 줄인다.
PngPlan _planOriginal(
  List<ImageSize> sizes,
  int marginPercent,
  int maxLongSide,
  int maxCanvasPixels,
) {
  final direction = decideDirection(sizes);
  final vertical = direction == LayoutDirection.vertical;

  // 반올림 오차가 쌓이지 않도록 실수로 계산한다.
  final capped = [
    for (final s in sizes)
      () {
        final f = math.min(1.0, maxLongSide / s.longSide);
        return (w: s.width * f, h: s.height * f);
      }(),
  ];
  final cross = capped.map((c) => vertical ? c.w : c.h).reduce(math.min);
  final mains = [
    for (final c in capped) vertical ? c.h * cross / c.w : c.w * cross / c.h,
  ];

  var g = 1.0;
  late int crossPx;
  late List<int> mainPx;
  late int thickness;
  late int padding;
  for (var attempt = 0;; attempt++) {
    // 공통 변은 내려 작은 이미지를 키우지 않는다. 1e-9는 정수로 딱 떨어지는 값이 오차로 1 작아지는 것을 막는다.
    // 다른 변은 반올림한다. 내리면 납작한 이미지가 찌그러진다 (2.87 → 2). 넘치는 몫은 이 반복이 줄인다.
    crossPx = math.max(1, (cross * g + 1e-9).floor());
    mainPx = [for (final m in mains) math.max(1, snapPx(m * g))];
    thickness = dividerThickness(crossPx);
    padding = snapPx(crossPx * marginPercent / 100);
    final length = mainPx.fold(0, (a, b) => a + b) +
        2 * padding * sizes.length +
        thickness * (sizes.length - 1);
    final pixels = (crossPx + 2 * padding) * length;
    if (pixels <= maxCanvasPixels || (crossPx == 1 && mainPx.every((m) => m == 1))) break;
    g *= _shrinkFactor(maxCanvasPixels / pixels, attempt);
  }

  final crossLength = crossPx + 2 * padding;
  final placements = <PngPlacement>[];
  final dividers = <PixelRect>[];
  var offset = 0;
  for (var i = 0; i < sizes.length; i++) {
    final w = vertical ? crossPx : mainPx[i];
    final h = vertical ? mainPx[i] : crossPx;
    placements.add(PngPlacement(
      x: vertical ? padding : offset + padding,
      y: vertical ? offset + padding : padding,
      width: w,
      height: h,
      scale: w / sizes[i].width,
    ));
    offset += mainPx[i] + 2 * padding;
    if (i < sizes.length - 1) {
      dividers.add(vertical
          ? PixelRect(0, offset, crossLength, thickness)
          : PixelRect(offset, 0, thickness, crossLength));
      offset += thickness;
    }
  }

  return PngPlan(
    direction: direction,
    canvasWidth: vertical ? crossLength : offset,
    canvasHeight: vertical ? offset : crossLength,
    placements: placements,
    dividers: dividers,
    dividerThickness: thickness,
  );
}

/// 항목을 N개씩 용지의 여백 안쪽 칸에 넣고, 용지 비율로 정한 방향으로 페이지를 이어 붙인다.
/// 페이지 사이는 구분선 두께만큼 띄우고 그 자리에 캔버스 전체 길이로 선을 긋는다.
/// 그래서 이웃한 페이지는 여백·선·여백 순으로 보이고, 여백 0%면 선만 있다.
PngPlan _planOnPaper(
  List<ImageSize> sizes,
  OutputSettings settings,
  PaperDimensions paper,
  int maxCanvasPixels,
  int dpi,
) {
  final direction = decideDirectionForPaper(paper);
  final vertical = direction == LayoutDirection.vertical;
  final pages = sheetCount(sizes.length, settings.imagesPerPaper);
  final baseWidth = (paper.widthMm / 25.4 * dpi).round();
  final baseHeight = (paper.heightMm / 25.4 * dpi).round();

  int canvasPixels(int w, int h, int t) =>
      vertical ? w * (pages * h + (pages - 1) * t) : h * (pages * w + (pages - 1) * t);

  // 두께는 줄어든 짧은 변에서 다시 재므로, 구분선까지 합해 상한 아래로 들어올 때까지 줄인다.
  var g = 1.0;
  late int pageWidth;
  late int pageHeight;
  late int thickness;
  for (var attempt = 0;; attempt++) {
    pageWidth = math.max(1, (baseWidth * g + 1e-9).floor());
    pageHeight = math.max(1, (baseHeight * g + 1e-9).floor());
    thickness = dividerThickness(math.min(pageWidth, pageHeight));
    final pixels = canvasPixels(pageWidth, pageHeight, thickness);
    if (pixels <= maxCanvasPixels || (pageWidth == 1 && pageHeight == 1)) break;
    g *= _shrinkFactor(maxCanvasPixels / pixels, attempt);
  }

  final sheets = layoutSheets(
    sizes,
    pageWidth: pageWidth.toDouble(),
    pageHeight: pageHeight.toDouble(),
    settings: settings,
    minGap: thickness.toDouble(),
  );
  final grid = pageGrid(settings.imagesPerPaper, settings.orientation);
  final stepX = vertical ? 0 : pageWidth + thickness;
  final stepY = vertical ? pageHeight + thickness : 0;
  final canvasWidth = vertical ? pageWidth : pages * pageWidth + (pages - 1) * thickness;
  final canvasHeight = vertical ? pages * pageHeight + (pages - 1) * thickness : pageHeight;

  final placements = <PngPlacement>[];
  final dividers = <PixelRect>[];
  for (var page = 0; page < pages; page++) {
    final originX = page * stepX;
    final originY = page * stepY;
    for (final placed in sheets[page]) {
      final rect = snapRect(placed.rect);
      placements.add(PngPlacement(
        x: originX + rect.x,
        y: originY + rect.y,
        width: rect.width,
        height: rect.height,
        scale: rect.width / sizes[placed.imageIndex].width,
      ));
    }
    for (final line in sheetDividers(
      pageWidth: pageWidth,
      pageHeight: pageHeight,
      grid: grid,
      filled: sheets[page].length,
      thickness: thickness,
      marginPercent: settings.marginPercent,
    )) {
      dividers.add(PixelRect(originX + line.x, originY + line.y, line.width, line.height));
    }
    if (page < pages - 1) {
      dividers.add(vertical
          ? PixelRect(0, originY + pageHeight, canvasWidth, thickness)
          : PixelRect(originX + pageWidth, 0, thickness, canvasHeight));
    }
  }

  return PngPlan(
    direction: direction,
    canvasWidth: canvasWidth,
    canvasHeight: canvasHeight,
    placements: placements,
    dividers: dividers,
    dividerThickness: thickness,
    onPaper: true,
  );
}
