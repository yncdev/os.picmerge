import {
  kDefaultPadding,
  kMaxInputLongSide,
  kMaxOutputBytes,
  kPdfBudgetRatio,
  kPdfMaxShrinks,
  kPdfPageLongSideMm,
  kPdfQualityHigh,
  kPdfQualityLow,
  kPdfShrinkFactor,
} from './limits.js';
import { layoutPages } from './page_layout.js';
import { mmToPoints, paperSizeMm } from './paper.js';

/** 긴 변이 maxLongSide를 넘으면 비율을 유지하며 줄인다. 넘지 않으면 그대로. */
export function capLongSide(size, maxLongSide) {
  const longSide = Math.max(size.width, size.height);
  if (longSide <= maxLongSide) return { width: size.width, height: size.height };
  const factor = maxLongSide / longSide;
  return {
    width: Math.max(1, Math.round(size.width * factor)),
    height: Math.max(1, Math.round(size.height * factor)),
  };
}

/**
 * PDF 페이지 계획(포인트). PDF 좌표는 왼쪽 아래가 원점이다.
 * 용지가 있으면 PNG 페이지와 같은 계산(여백 P, 칸 간격 0.8P, 칸 안에 맞춘 뒤 F)으로 N개씩 넣는다. P=0이면 칸이 맞닿는다.
 * '원본 크기'면 항목마다 한 페이지로, 이미지 짧은 변의 P%를 네 변에 두고 긴 변을 297mm에 맞춘다.
 * 구분선은 PNG에만 있다 (DESIGN §2.1.3).
 * @returns {{pageWidthPt:number,pageHeightPt:number,images:{index:number,xPt:number,yPt:number,widthPt:number,heightPt:number}[]}[]}
 */
export function planPdf(sizes, settings) {
  const mm = paperSizeMm(settings);
  if (!mm) {
    const longPt = mmToPoints(kPdfPageLongSideMm);
    return sizes.map((size, index) => {
      const padding = (Math.min(size.width, size.height) * (settings.padding ?? kDefaultPadding)) / 100;
      const contentWidth = size.width + padding * 2;
      const contentHeight = size.height + padding * 2;
      const scale = longPt / Math.max(contentWidth, contentHeight);
      return {
        pageWidthPt: contentWidth * scale,
        pageHeightPt: contentHeight * scale,
        images: [
          {
            index,
            xPt: padding * scale,
            yPt: padding * scale,
            widthPt: size.width * scale,
            heightPt: size.height * scale,
          },
        ],
      };
    });
  }
  const pageWidthPt = mmToPoints(mm.widthMm);
  const pageHeightPt = mmToPoints(mm.heightMm);
  const { pages } = layoutPages(sizes, { width: pageWidthPt, height: pageHeightPt }, settings);
  return pages.map((images) => ({
    pageWidthPt,
    pageHeightPt,
    images: images.map(({ index, x, y, width, height }) => ({
      index,
      xPt: x,
      yPt: pageHeightPt - y - height,
      widthPt: width,
      heightPt: height,
    })),
  }));
}

/** 이미지 한 장의 JPEG 바이트 예산. 페이지가 아니라 이미지마다 둔다 (DESIGN §2.1.3). */
export function pdfImageBudget(imageCount, { maxBytes = kMaxOutputBytes, ratio = kPdfBudgetRatio } = {}) {
  if (!(imageCount > 0)) throw new RangeError(`imageCount: ${imageCount}`);
  return Math.floor((maxBytes * ratio) / imageCount);
}

/**
 * 예산 안에 들 때까지 차례로 시도할 인코딩 설정 (DESIGN §2.1.3).
 * 품질 85 → 품질 70 → 품질 70에서 긴 변을 직전의 75%로 (최대 3번). 다시 인코딩은 모두 최대 4회다.
 */
export function pdfJpegAttempts(size, { maxLongSide = kMaxInputLongSide } = {}) {
  const base = capLongSide(size, maxLongSide);
  const attempts = [
    { width: base.width, height: base.height, quality: kPdfQualityHigh },
    { width: base.width, height: base.height, quality: kPdfQualityLow },
  ];
  let w = base.width;
  let h = base.height;
  for (let i = 0; i < kPdfMaxShrinks; i++) {
    w *= kPdfShrinkFactor;
    h *= kPdfShrinkFactor;
    attempts.push({ width: Math.max(1, Math.round(w)), height: Math.max(1, Math.round(h)), quality: kPdfQualityLow });
  }
  return attempts;
}
