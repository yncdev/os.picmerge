// DESIGN.md 부록 '가정' 값. 바꿀 때는 DESIGN.md도 함께 고친다.

const int kMinImages = 2;
const int kMaxImages = 30;

/// 입력 이미지 긴 변 상한 (DESIGN §2.1.2, §2.1.3).
const int kMaxInputLongSide = 4000;

/// PNG 캔버스 총 픽셀 상한 (DESIGN §2.1.2).
const int kMaxCanvasPixels = 24000000;

/// 결과 파일 크기 상한. MB/MiB 어느 쪽으로 읽어도 넘지 않도록 10진 기준.
const int kMaxOutputBytes = 20000000;

/// PNG가 20MB를 넘을 때 다시 인코딩하는 최대 횟수.
const int kPngMaxReencodes = 2;

const int kPdfQualityHigh = 85;
const int kPdfQualityLow = 70;

/// PDF 페이지 예산 = kPdfBudgetRatio × kMaxOutputBytes ÷ 장수. 나머지는 PDF 구조 용량.
const double kPdfBudgetRatio = 0.95;

/// 품질 70으로도 예산을 넘을 때 긴 변을 줄이는 비율과 최대 횟수.
const double kPdfShrinkFactor = 0.75;
const int kPdfMaxShrinks = 3;

/// PDF 페이지 긴 변 (A4 긴 변).
const double kPdfPageLongSideMm = 297;

/// 용지를 고른 PNG 캔버스의 해상도 (DESIGN §2.1.2).
const int kPngPaperDpi = 300;

/// 칸 사이 간격 = 페이지 여백 × 이 값. 기본 여백 5%면 짧은 변의 4%다 (DESIGN §2.1.2).
const double kCellGapPerMargin = 0.8;

/// 구분선 두께 = 기준 변 × 이 값, 최소 [kMinDividerPx] (DESIGN §2.1.2).
const double kDividerRatio = 0.003;
const int kMinDividerPx = 2;

/// 구분선 색 #D0D0D0의 R·G·B 값. 흑백을 골라도 같다.
const int kDividerGray = 0xD0;

/// 입력 PDF 페이지를 이미지로 만드는 설정 (DESIGN §2.1.1).
const int kPdfRenderDpi = 300;
const int kPdfRenderQuality = 92;

/// 영역 편집기 화면에 쓰는 임시 미리보기 (DESIGN §2.1.6).
const int kCropPreviewLongSide = 1600;
const int kCropPreviewQuality = 85;

/// 선택 목록·미리보기 썸네일. 원본을 화면용으로 통째 디코딩하지 않으려고 네이티브로 만든다.
const int kThumbnailLongSide = 512;
const int kThumbnailQuality = 80;

const int kHistoryLimit = 50;
const int kHistoryRateDays = 30;
