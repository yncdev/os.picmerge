import { kDefaultPadding, kMaxCanvasPixels, kPaperDpi } from './limits.js';

const MM_PER_INCH = 25.4;
const POINTS_PER_INCH = 72;

/** 세로 방향 기준 치수(mm). B4·B5는 JIS 치수다 (DESIGN §2.1.5). */
export const PAPERS = Object.freeze([
  Object.freeze({ code: 'a4', widthMm: 210, heightMm: 297 }),
  Object.freeze({ code: 'a3', widthMm: 297, heightMm: 420 }),
  Object.freeze({ code: 'a5', widthMm: 148, heightMm: 210 }),
  Object.freeze({ code: 'b4', widthMm: 257, heightMm: 364 }),
  Object.freeze({ code: 'b5', widthMm: 182, heightMm: 257 }),
  Object.freeze({ code: 'letter', widthMm: 215.9, heightMm: 279.4 }),
  Object.freeze({ code: 'legal', widthMm: 215.9, heightMm: 355.6 }),
  Object.freeze({ code: 'original', widthMm: 0, heightMm: 0 }),
]);

/** 앱을 시작할 때 항상 이 값이다. 기억하지 않는다 (DESIGN §2.1.5). */
export const DEFAULT_SETTINGS = Object.freeze({
  paper: 'a4',
  orientation: 'portrait',
  perSheet: 1,
  imageSize: 100,
  padding: kDefaultPadding,
  grayscale: false,
});

/**
 * 방향을 반영한 용지 치수(mm). '원본 크기'면 null.
 * @param {{paper:string,orientation:string}} settings
 */
export function paperSizeMm(settings) {
  const paper = PAPERS.find((p) => p.code === settings.paper);
  if (!paper) throw new RangeError(`unknown paper: ${settings.paper}`);
  if (paper.code === 'original') return null;
  return settings.orientation === 'landscape'
    ? { widthMm: paper.heightMm, heightMm: paper.widthMm }
    : { widthMm: paper.widthMm, heightMm: paper.heightMm };
}

/** 용지를 고른 PNG 캔버스 크기. 상한을 넘으면 같은 비율로 줄인다 (DESIGN §2.1.2). */
export function paperCanvas(mm, { dpi = kPaperDpi, maxPixels = kMaxCanvasPixels } = {}) {
  const width = (mm.widthMm / MM_PER_INCH) * dpi;
  const height = (mm.heightMm / MM_PER_INCH) * dpi;
  const pixels = Math.round(width) * Math.round(height);
  if (pixels <= maxPixels) return { width: Math.round(width), height: Math.round(height) };
  const g = Math.sqrt(maxPixels / (width * height));
  return { width: Math.floor(width * g), height: Math.floor(height * g) };
}

export function mmToPoints(mm) {
  return (mm / MM_PER_INCH) * POINTS_PER_INCH;
}
