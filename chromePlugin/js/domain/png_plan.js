import { decideDirection, LayoutDirection } from './layout_direction.js';
import { kDefaultPadding, kDividerMinPx, kMaxCanvasPixels, kMaxInputLongSide } from './limits.js';
import { dividerThickness, layoutPages, pageDividers, sheetCount, snap, snapRect } from './page_layout.js';
import { paperCanvas, paperSizeMm } from './paper.js';

const FLOOR_EPSILON = 1e-9; // 정수로 딱 떨어지는 값이 오차로 1 작아지는 것을 막는다.

/** 첫 축소로 상한 안에 못 들었을 때 다음 축소에 곱한다. 작은 초과에서 축소가 멈추지 않게 한다. */
const RETRY_MARGIN = 0.999;

const sum = (values) => values.reduce((a, b) => a + b, 0);
const floorPx = (value) => Math.max(1, Math.floor(value + FLOOR_EPSILON));
/** 반올림. 내림하면 공통 변에 맞춰 줄인 작은 이미지가 납작해진다 (2.87 → 2). 상한은 shrinkToCap이 지킨다. Flutter와 같다. */
const roundPx = (value) => Math.max(1, snap(value));

/**
 * 총 픽셀이 상한 안에 들 때까지 같은 비율로 줄인다.
 * 두께 반올림과 최소 2px 때문에 한 번에 안 들 수 있어 반복한다.
 * @param {(scale:number)=>{canvasWidth:number,canvasHeight:number}} measure
 */
function shrinkToCap(measure, maxPixels) {
  let scale = 1;
  let result = measure(scale);
  for (let attempt = 0; result.canvasWidth * result.canvasHeight > maxPixels; attempt++) {
    scale *= Math.sqrt(maxPixels / (result.canvasWidth * result.canvasHeight)) * (attempt === 0 ? 1 : RETRY_MARGIN);
    result = measure(scale);
  }
  return result;
}

/**
 * PNG 배치 방향. 용지를 고르면 용지 비율로, '원본 크기'면 이미지 비율로 정한다 (DESIGN §2.1.2).
 * A4 세로는 가로 배치, A4 가로는 세로 배치다.
 */
export function pngDirection(sizes, settings) {
  const mm = paperSizeMm(settings);
  return decideDirection(mm ? [{ width: mm.widthMm, height: mm.heightMm }] : sizes);
}

/**
 * 출력 설정에 맞는 PNG 합성 계획. 크기는 영역 편집을 반영한 값이다 (DESIGN §2.1.2).
 * @param {{width:number,height:number}[]} sizes
 * @param {{paper:string,orientation:string,perSheet?:number,imageSize?:number,padding?:number}} settings
 * @returns {{direction:object,onPaper:boolean,canvasWidth:number,canvasHeight:number,dividerThickness:number,
 *   placements:object[],dividers:object[]}} placements는 항목 순서, dividers는 구분선 사각형이다.
 */
export function planPng(sizes, settings) {
  return paperSizeMm(settings) ? planPngOnPaper(sizes, settings) : planPngOriginal(sizes, { padding: settings.padding });
}

/**
 * '원본 크기': 긴 변 제한 → 공통 변을 최솟값에 맞춤(확대 안 함) → 여백·구분선 포함 캔버스 픽셀 상한.
 * 이미지마다 네 변에 공통 변의 P%를 흰 여백으로 두고, 양쪽 여백 사이에 구분선을 긋는다.
 * [여백][이미지][여백][선][여백][이미지][여백]. P=0이면 [이미지][선][이미지]다.
 */
export function planPngOriginal(
  sizes,
  { maxLongSide = kMaxInputLongSide, maxCanvasPixels = kMaxCanvasPixels, padding = kDefaultPadding } = {},
) {
  if (!sizes.length) throw new RangeError('sizes must not be empty');
  const direction = decideDirection(sizes);
  const vertical = direction === LayoutDirection.vertical;

  // 반올림 오차가 쌓이지 않도록 실수로 계산한다.
  const capped = sizes.map((s) => {
    const f = Math.min(1, maxLongSide / Math.max(s.width, s.height));
    return { w: s.width * f, h: s.height * f };
  });
  const cross = Math.min(...capped.map((c) => (vertical ? c.w : c.h)));
  const mains = capped.map((c) => (vertical ? (c.h * cross) / c.w : (c.w * cross) / c.h));

  const fit = shrinkToCap((scale) => {
    // 공통 변은 내림이다. 기준값은 최솟값이고 작은 이미지를 키우지 않는다 (DESIGN §2.1.2).
    const crossPx = floorPx(cross * scale);
    const mainPx = mains.map((main) => roundPx(main * scale));
    const thickness = dividerThickness(crossPx);
    const paddingPx = snap((crossPx * padding) / 100);
    const length = sum(mainPx) + paddingPx * 2 * mainPx.length + thickness * (mainPx.length - 1);
    const breadth = crossPx + paddingPx * 2;
    return {
      crossPx,
      mainPx,
      thickness,
      paddingPx,
      breadth,
      canvasWidth: vertical ? breadth : length,
      canvasHeight: vertical ? length : breadth,
    };
  }, maxCanvasPixels);

  const placements = [];
  const dividers = [];
  let offset = 0;
  fit.mainPx.forEach((main, i) => {
    if (i > 0) {
      dividers.push(
        vertical
          ? { x: 0, y: offset, width: fit.breadth, height: fit.thickness }
          : { x: offset, y: 0, width: fit.thickness, height: fit.breadth },
      );
      offset += fit.thickness;
    }
    offset += fit.paddingPx;
    placements.push(
      vertical
        ? { x: fit.paddingPx, y: offset, width: fit.crossPx, height: main }
        : { x: offset, y: fit.paddingPx, width: main, height: fit.crossPx },
    );
    offset += main + fit.paddingPx;
  });

  return {
    direction,
    onPaper: false,
    canvasWidth: fit.canvasWidth,
    canvasHeight: fit.canvasHeight,
    dividerThickness: fit.thickness,
    paddingPx: fit.paddingPx,
    placements,
    dividers,
  };
}

/**
 * 용지: 페이지 네 변에 흰 여백을 두고, 항목을 N개씩 페이지에 넣고, 페이지를 용지 비율로 정한 방향으로 잇는다.
 * 페이지와 구분선을 합한 캔버스가 상한을 넘으면 페이지 크기를 같은 비율로 줄인다.
 * 남는 곳은 흰색이다.
 */
export function planPngOnPaper(sizes, settings, { maxCanvasPixels = kMaxCanvasPixels } = {}) {
  if (!sizes.length) throw new RangeError('sizes must not be empty');
  const { perSheet = 1 } = settings;
  const base = paperCanvas(paperSizeMm(settings));
  const direction = pngDirection(sizes, settings);
  const vertical = direction === LayoutDirection.vertical;
  const pageCount = sheetCount(sizes.length, perSheet);

  const fit = shrinkToCap((scale) => {
    const width = floorPx(base.width * scale);
    const height = floorPx(base.height * scale);
    const thickness = dividerThickness(Math.min(width, height));
    const gaps = thickness * (pageCount - 1);
    return {
      width,
      height,
      thickness,
      canvasWidth: vertical ? width : width * pageCount + gaps,
      canvasHeight: vertical ? height * pageCount + gaps : height,
    };
  }, maxCanvasPixels);

  const page = { width: fit.width, height: fit.height };
  const { grid, spacing, pages } = layoutPages(sizes, page, settings, { minGap: fit.thickness });
  const placements = [];
  const dividers = [];
  pages.forEach((images, p) => {
    const originX = vertical ? 0 : p * (fit.width + fit.thickness);
    const originY = vertical ? p * (fit.height + fit.thickness) : 0;
    const shifted = (rect) => ({ ...rect, x: rect.x + originX, y: rect.y + originY });
    if (p > 0) {
      // 페이지 사이: 페이지를 두께만큼 띄운 자리에 캔버스 전체 길이로 긋는다.
      dividers.push(
        vertical
          ? { x: 0, y: originY - fit.thickness, width: fit.canvasWidth, height: fit.thickness }
          : { x: originX - fit.thickness, y: 0, width: fit.thickness, height: fit.canvasHeight },
      );
    }
    for (const { index, ...rect } of images) placements[index] = shifted(snapRect(rect));
    dividers.push(...pageDividers(page, grid, images.length, fit.thickness, spacing).map(shifted));
  });

  return {
    direction,
    onPaper: true,
    canvasWidth: fit.canvasWidth,
    canvasHeight: fit.canvasHeight,
    pageWidth: fit.width,
    pageHeight: fit.height,
    pageCount,
    dividerThickness: fit.thickness,
    placements,
    dividers,
  };
}

/**
 * 결과가 상한을 넘을 때 다음에 적용할 누적 축소 비율: 이전 × √(상한 ÷ 크기) × 0.9 (DESIGN §2.1.2).
 */
export function nextPngFactor(previousFactor, encodedBytes, maxBytes) {
  return previousFactor * Math.sqrt(maxBytes / encodedBytes) * 0.9;
}

/**
 * 다시 인코딩하려고 캔버스를 [width]×[height]로 줄였을 때 다시 그을 구분선.
 * 그냥 줄이면 선이 흐려져 색이 옅어지고 2px보다 가늘어진다 (DESIGN §2.1.2).
 */
export function scaleDividers(plan, width, height) {
  const scaleX = width / plan.canvasWidth;
  const scaleY = height / plan.canvasHeight;
  const thickness = Math.max(kDividerMinPx, snap(plan.dividerThickness * Math.min(scaleX, scaleY)));
  const along = (start, length, scale) => {
    const from = snap(start * scale);
    return [from, Math.max(1, snap((start + length) * scale) - from)];
  };
  const across = (start, length, scale) => snap((start + length / 2) * scale - thickness / 2);
  return plan.dividers.map((d) => {
    if (d.width < d.height) {
      const [y, h] = along(d.y, d.height, scaleY);
      return { x: across(d.x, d.width, scaleX), y, width: thickness, height: h };
    }
    const [x, w] = along(d.x, d.width, scaleX);
    return { x, y: across(d.y, d.height, scaleY), width: w, height: thickness };
  });
}
