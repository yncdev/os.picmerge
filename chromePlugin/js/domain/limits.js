// DESIGN.md 부록 '가정' 값. lib/core/config/limits.dart와 숫자가 같아야 한다.

export const kMinImages = 2;
export const kMaxImages = 30;

/** 입력 이미지 긴 변 상한 (DESIGN §2.1.2, §2.1.3). */
export const kMaxInputLongSide = 4000;

/** PNG 캔버스 총 픽셀 상한 (DESIGN §2.1.2). */
export const kMaxCanvasPixels = 24000000;

/** 결과 파일 크기 상한. MB/MiB 어느 쪽으로 읽어도 넘지 않도록 10진 기준. */
export const kMaxOutputBytes = 20000000;

/** PNG가 20MB를 넘을 때 다시 인코딩하는 최대 횟수. */
export const kPngMaxReencodes = 2;

export const kPdfQualityHigh = 85;
export const kPdfQualityLow = 70;

/** PDF 이미지당 예산 = kPdfBudgetRatio × kMaxOutputBytes ÷ 장수. 나머지는 PDF 구조 용량. */
export const kPdfBudgetRatio = 0.95;

/** 품질 70으로도 예산을 넘을 때 긴 변을 줄이는 비율과 최대 횟수. */
export const kPdfShrinkFactor = 0.75;
export const kPdfMaxShrinks = 3;

/** '원본 크기'일 때 PDF 페이지 긴 변 (A4 긴 변). */
export const kPdfPageLongSideMm = 297;

/** 용지를 고른 PNG 캔버스 해상도 (DESIGN 부록). */
export const kPaperDpi = 300;

/** 여백 P의 기본값(%). 용지 짧은 변, '원본 크기'는 PNG가 공통 변, PDF가 이미지 짧은 변 기준이다 (DESIGN §2.1.5). */
export const kDefaultPadding = 5;

/** 칸 사이 간격 = 여백의 0.8배. 기본 P=5%면 짧은 변의 4%다 (DESIGN §2.1.2). */
export const kCellGapPerMargin = 0.8;

/** PNG 구분선: 색, 기준 변의 비율, 최소 두께 (DESIGN §2.1.2). */
export const kDividerColor = '#D0D0D0';
export const kDividerRatio = 0.003;
export const kDividerMinPx = 2;

/** 입력 PDF 페이지 이미지화 (DESIGN §2.1.1). */
export const kPdfRenderDpi = 300;
export const kPdfRenderQuality = 92;

/** 선택 목록·미리보기 썸네일. */
export const kThumbnailLongSide = 512;
export const kThumbnailQuality = 80;

/** 영역 편집 화면의 임시 이미지 (DESIGN §2.1.6). */
export const kCropPreviewLongSide = 1600;
export const kCropPreviewQuality = 90;

/** 영역은 가로·세로 각각 원본의 2% 이상 (DESIGN §2.1.6). */
export const kMinCropFraction = 0.02;

export const kHistoryLimit = 50;
export const kHistoryRateDays = 30;
