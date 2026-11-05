/// 용지 종류 (DESIGN §2.1.5). B4·B5는 JIS 치수다. [original]은 용지 없이 이미지 묶음 크기 그대로다.
enum PaperSize {
  a4('A4', 210, 297),
  a3('A3', 297, 420),
  a5('A5', 148, 210),
  b4('B4', 257, 364),
  b5('B5', 182, 257),
  letter('Letter', 215.9, 279.4),
  legal('Legal', 215.9, 355.6),
  original(null, 0, 0);

  const PaperSize(this.standardName, this.shortMm, this.longMm);

  /// 언어와 무관한 규격 이름. '원본 크기'는 규격이 아니라 없다.
  final String? standardName;
  final double shortMm;
  final double longMm;
}

/// 종이를 세로로 쓸지 가로로 쓸지. 배치 방향(LayoutDirection)과는 별개다.
enum PaperOrientation { portrait, landscape }

/// 방향을 반영한 용지 크기 (mm).
class PaperDimensions {
  const PaperDimensions(this.widthMm, this.heightMm);

  final double widthMm;
  final double heightMm;

  double get aspectRatio => widthMm / heightMm;
}

/// 용지당 이미지 수 선택지 (DESIGN §2.1.5).
const kImagesPerPaperChoices = [1, 2, 3, 4, 6, 8, 9];

/// 이미지 크기 선택지. 칸에 맞춘 크기의 가로·세로 비율(%)이다 (DESIGN §2.1.5).
const kImageSizePercentChoices = [100, 50, 30];

/// 여백 선택지 (%). 페이지와 이미지 둘레의 흰 여백이고 칸 사이 간격도 함께 바뀐다 (DESIGN §2.1.5).
const kMarginPercentChoices = [0, 3, 5, 10];

/// 출력 설정. 기본값은 A4·세로·용지당 1개·100%·여백 5%·컬러이고, 기억하지 않는다 (DESIGN §2.1.5).
class OutputSettings {
  const OutputSettings({
    this.paper = PaperSize.a4,
    this.orientation = PaperOrientation.portrait,
    this.imagesPerPaper = 1,
    this.imageSizePercent = 100,
    this.marginPercent = 5,
    this.grayscale = false,
  });

  final PaperSize paper;
  final PaperOrientation orientation;

  /// 용지 없는 '원본 크기'에서는 쓰지 않는다.
  final int imagesPerPaper;

  /// 용지 없는 '원본 크기'에서는 쓰지 않는다.
  final int imageSizePercent;

  /// '원본 크기'에도 쓴다. 기준 변은 PNG가 공통 변, PDF가 이미지 짧은 변이다.
  final int marginPercent;
  final bool grayscale;

  /// 용지 없이('원본 크기') 만들면 null.
  PaperDimensions? get paperDimensions {
    if (paper == PaperSize.original) return null;
    return orientation == PaperOrientation.portrait
        ? PaperDimensions(paper.shortMm, paper.longMm)
        : PaperDimensions(paper.longMm, paper.shortMm);
  }

  OutputSettings copyWith({
    PaperSize? paper,
    PaperOrientation? orientation,
    int? imagesPerPaper,
    int? imageSizePercent,
    int? marginPercent,
    bool? grayscale,
  }) =>
      OutputSettings(
        paper: paper ?? this.paper,
        orientation: orientation ?? this.orientation,
        imagesPerPaper: imagesPerPaper ?? this.imagesPerPaper,
        imageSizePercent: imageSizePercent ?? this.imageSizePercent,
        marginPercent: marginPercent ?? this.marginPercent,
        grayscale: grayscale ?? this.grayscale,
      );
}
