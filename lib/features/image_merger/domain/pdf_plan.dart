import 'dart:math' as math;

import '../../../core/config/limits.dart';
import '../../../core/image_size.dart';
import 'output_settings.dart';
import 'page_layout.dart';

/// PDF 한 페이지와 거기에 놓을 이미지. 좌표는 포인트이고 왼쪽 위가 원점이다.
class PdfPagePlan {
  const PdfPagePlan({required this.widthPt, required this.heightPt, required this.images});

  final double widthPt;
  final double heightPt;
  final List<SheetImage> images;
}

class JpegAttempt {
  const JpegAttempt({required this.width, required this.height, required this.quality});

  final int width;
  final int height;
  final int quality;

  @override
  String toString() => '${width}x$height q$quality';
}

const double _pointsPerMm = 72 / 25.4;

/// 용지를 고르면 용지 한 장이 한 페이지이고 항목은 PNG 페이지와 같은 칸 배치 규칙대로 들어간다.
/// 구분선은 없다. '원본 크기'면 항목 하나당 한 페이지다 (DESIGN §2.1.3).
List<PdfPagePlan> planPdf(List<ImageSize> sizes, OutputSettings settings) {
  final paper = settings.paperDimensions;
  if (paper == null) {
    return [
      for (var i = 0; i < sizes.length; i++) _originalPage(i, sizes[i], settings.marginPercent),
    ];
  }
  final pageWidth = paper.widthMm * _pointsPerMm;
  final pageHeight = paper.heightMm * _pointsPerMm;
  return [
    for (final sheet in layoutSheets(
      sizes,
      pageWidth: pageWidth,
      pageHeight: pageHeight,
      settings: settings,
    ))
      PdfPagePlan(widthPt: pageWidth, heightPt: pageHeight, images: sheet),
  ];
}

/// 네 변에 이미지 짧은 변의 [marginPercent]%를 여백으로 둔다. 페이지 비율은 이미지와 여백을 합한
/// 비율이고 긴 변은 [longSideMm]다.
PdfPagePlan _originalPage(
  int index,
  ImageSize size,
  int marginPercent, {
  double longSideMm = kPdfPageLongSideMm,
}) {
  final padding = math.min(size.width, size.height) * marginPercent / 100;
  final contentWidth = size.width + 2 * padding;
  final contentHeight = size.height + 2 * padding;
  final scale = longSideMm * _pointsPerMm / math.max(contentWidth, contentHeight);
  return PdfPagePlan(
    widthPt: contentWidth * scale,
    heightPt: contentHeight * scale,
    images: [
      SheetImage(
        imageIndex: index,
        rect: LayoutRect(padding * scale, padding * scale, size.width * scale, size.height * scale),
      ),
    ],
  );
}

/// 이미지 한 장의 JPEG 바이트 예산. 한 페이지에 여러 장이 들어가도 장수로 나눈다.
int pdfImageBudget(
  int imageCount, {
  int maxBytes = kMaxOutputBytes,
  double ratio = kPdfBudgetRatio,
}) {
  if (imageCount <= 0) throw ArgumentError.value(imageCount, 'imageCount');
  return (maxBytes * ratio / imageCount).floor();
}

/// 예산 안에 들 때까지 차례로 시도할 인코딩 설정 (DESIGN §2.1.3).
/// 품질 85 → 품질 70 → 품질 70에서 긴 변을 직전의 75%로 (최대 3번). 다시 인코딩은 모두 최대 4회다.
List<JpegAttempt> pdfJpegAttempts(ImageSize size, {int maxLongSide = kMaxInputLongSide}) {
  final base = size.capLongSide(maxLongSide);
  final attempts = [
    JpegAttempt(width: base.width, height: base.height, quality: kPdfQualityHigh),
    JpegAttempt(width: base.width, height: base.height, quality: kPdfQualityLow),
  ];
  var w = base.width.toDouble();
  var h = base.height.toDouble();
  for (var i = 0; i < kPdfMaxShrinks; i++) {
    w *= kPdfShrinkFactor;
    h *= kPdfShrinkFactor;
    attempts.add(JpegAttempt(
      width: math.max(1, w.round()),
      height: math.max(1, h.round()),
      quality: kPdfQualityLow,
    ));
  }
  return attempts;
}
