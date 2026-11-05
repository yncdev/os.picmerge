import { kCellGapPerMargin, kDefaultPadding, kDividerMinPx, kDividerRatio } from './limits.js';

// 용지 한 장 안의 칸 배치 (DESIGN §2.1.2, §2.1.3).
// 단위가 없는 계산이라 PNG(픽셀), PDF(포인트), 미리보기(백분율)가 같은 함수를 쓴다.
// 좌표는 왼쪽 위가 원점이다. PDF는 pdf_plan.js에서 뒤집는다.

export const PER_SHEET_OPTIONS = Object.freeze([1, 2, 3, 4, 6, 8, 9]);
export const IMAGE_SIZE_OPTIONS = Object.freeze([100, 50, 30]);
export const PADDING_OPTIONS = Object.freeze([0, 3, 5, 10]);

/** 용지당 이미지 수 → [짧은 변 칸 수, 긴 변 칸 수]. */
const SHORT_BY_LONG = Object.freeze({
  1: [1, 1],
  2: [1, 2],
  3: [1, 3],
  4: [2, 2],
  6: [2, 3],
  8: [2, 4],
  9: [3, 3],
});

/** 칸 배치를 용지 방향에 맞춘다. 세로 용지 N=2는 위아래 2칸, 가로 용지 N=2는 좌우 2칸이다. */
export function gridFor(perSheet, orientation) {
  const entry = SHORT_BY_LONG[perSheet];
  if (!entry) throw new RangeError(`perSheet: ${perSheet}`);
  const [short, long] = entry;
  return orientation === 'landscape' ? { columns: long, rows: short } : { columns: short, rows: long };
}

/** 페이지 수 = ⌈항목 수 ÷ N⌉. */
export function sheetCount(itemCount, perSheet) {
  return Math.ceil(itemCount / perSheet);
}

/**
 * 페이지 여백과 칸 사이 간격. 여백은 용지 짧은 변의 P%, 간격은 여백의 0.8배다 (DESIGN §2.1.2).
 * @param {number} padding 여백 P(%)
 * @param {number} minGap 간격의 하한. PNG는 구분선 두께를 넘겨 P=0에서도 선 자리를 남긴다. PDF는 0이라 칸이 맞닿는다.
 */
export function pageSpacing(page, padding = kDefaultPadding, minGap = 0) {
  const margin = (Math.min(page.width, page.height) * padding) / 100;
  return { margin, gap: Math.max(margin * kCellGapPerMargin, minGap) };
}

/** 칸들의 자리. 왼쪽에서 오른쪽, 위에서 아래 순서다. 칸은 여백 안쪽에서 나눈다. */
export function cellRects(page, grid, { margin, gap } = pageSpacing(page)) {
  const width = (page.width - margin * 2 - gap * (grid.columns - 1)) / grid.columns;
  const height = (page.height - margin * 2 - gap * (grid.rows - 1)) / grid.rows;
  const cells = [];
  for (let row = 0; row < grid.rows; row++) {
    for (let column = 0; column < grid.columns; column++) {
      cells.push({ x: margin + column * (width + gap), y: margin + row * (height + gap), width, height });
    }
  }
  return cells;
}

/**
 * 비율을 유지해 칸 안에 가장 크게 맞춘 뒤 가로·세로에 F%를 곱하고 칸 가운데에 놓는다.
 * 원본이 칸보다 작아도 키운다.
 */
export function fitInCell(size, cell, imageSize = 100) {
  const scale = Math.min(cell.width / size.width, cell.height / size.height) * (imageSize / 100);
  const width = size.width * scale;
  const height = size.height * scale;
  return {
    x: cell.x + (cell.width - width) / 2,
    y: cell.y + (cell.height - height) / 2,
    width,
    height,
  };
}

/**
 * 항목을 순서대로 N개씩 묶어 페이지에 배치한다. 마지막 페이지에 남는 칸은 비워 둔다.
 * @param {{minGap?:number}} options PNG와 미리보기는 구분선 두께를 넘긴다. pageSpacing을 본다.
 * @returns {{grid:{columns:number,rows:number}, spacing:{margin:number,gap:number},
 *   pages:{index:number,x:number,y:number,width:number,height:number}[][]}}
 *   페이지별 이미지 자리. index는 항목 순번이고 좌표는 그 페이지 기준이다.
 */
export function layoutPages(
  sizes,
  page,
  { perSheet = 1, imageSize = 100, padding = kDefaultPadding, orientation = 'portrait' } = {},
  { minGap = 0 } = {},
) {
  const grid = gridFor(perSheet, orientation);
  const spacing = pageSpacing(page, padding, minGap);
  const cells = cellRects(page, grid, spacing);
  const pages = [];
  sizes.forEach((size, index) => {
    const slot = index % perSheet;
    if (slot === 0) pages.push([]);
    pages.at(-1).push({ index, ...fitInCell(size, cells[slot], imageSize) });
  });
  return { grid, spacing, pages };
}

/** 구분선 두께. 기준 변의 0.3%이고 최소 2px이다. */
export function dividerThickness(side) {
  return Math.max(kDividerMinPx, snap(side * kDividerRatio));
}

/** 반올림. 손으로 계산한 .5가 부동소수점 오차로 내려가지 않게 한다. */
export function snap(value) {
  return Math.floor(value + 0.5 + 1e-9);
}

/** 네 변을 각각 반올림한다. 칸 안의 이미지는 반올림한 칸 밖으로 나가지 않는다. */
export function snapRect({ x, y, width, height }) {
  const left = snap(x);
  const top = snap(y);
  return {
    x: left,
    y: top,
    width: Math.max(1, snap(x + width) - left),
    height: Math.max(1, snap(y + height) - top),
  };
}

/**
 * 페이지 안의 구분선(픽셀). 칸 사이 간격의 가운데에 긋는다 (DESIGN §2.1.2).
 * 가로줄은 아래 줄에 이미지가 있을 때 여백 안쪽 폭 전체로, 세로줄은 같은 줄의 양쪽 칸에 모두 이미지가 있을 때
 * 그 줄 높이만큼 긋는다.
 * @param {{width:number,height:number}} page 정수 픽셀 크기
 * @param {number} imageCount 이 페이지의 이미지 수
 */
export function pageDividers(page, grid, imageCount, thickness, spacing = pageSpacing(page)) {
  const { margin, gap } = spacing;
  const cells = cellRects(page, grid, spacing);
  const inset = (gap - thickness) / 2;
  const left = snap(margin);
  const lineWidth = snap(page.width - margin) - left;
  const dividers = [];
  for (let row = 0; row + 1 < grid.rows; row++) {
    if (imageCount <= (row + 1) * grid.columns) continue;
    const cell = cells[row * grid.columns];
    dividers.push({ x: left, y: snap(cell.y + cell.height + inset), width: lineWidth, height: thickness });
  }
  for (let row = 0; row < grid.rows; row++) {
    for (let column = 0; column + 1 < grid.columns; column++) {
      const leftCell = row * grid.columns + column;
      if (leftCell + 1 >= imageCount) continue;
      const cell = cells[leftCell];
      const top = snap(cell.y);
      dividers.push({
        x: snap(cell.x + cell.width + inset),
        y: top,
        width: thickness,
        height: snap(cell.y + cell.height) - top,
      });
    }
  }
  return dividers;
}
