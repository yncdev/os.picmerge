// 페이지 배치, 구분선, PNG·PDF 계획 (DESIGN §2.1.2, §2.1.3, §2.1.5).
// 기대값은 코드가 아니라 손으로 계산했다. 계산 과정을 주석에 남긴다.
import assert from 'node:assert/strict';
import { describe, test } from 'node:test';

import { LayoutDirection } from '../js/domain/layout_direction.js';
import {
  cellRects,
  dividerThickness,
  fitInCell,
  gridFor,
  IMAGE_SIZE_OPTIONS,
  layoutPages,
  pageDividers,
  pageSpacing,
  PADDING_OPTIONS,
  PER_SHEET_OPTIONS,
  sheetCount,
} from '../js/domain/page_layout.js';
import { DEFAULT_SETTINGS, PAPERS } from '../js/domain/paper.js';
import { pdfImageBudget, planPdf } from '../js/domain/pdf_plan.js';
import { planPng, planPngOnPaper, planPngOriginal, pngDirection, scaleDividers } from '../js/domain/png_plan.js';

const size = (width, height) => ({ width, height });
const close = (actual, expected, tolerance = 0.001) =>
  assert.ok(Math.abs(actual - expected) <= tolerance, `${actual} is not within ${tolerance} of ${expected}`);
const a4 = (overrides = {}) => ({ paper: 'a4', orientation: 'portrait', grayscale: false, ...overrides });
const a4Landscape = (overrides = {}) => a4({ orientation: 'landscape', ...overrides });
const rect = (x, y, width, height) => ({ x, y, width, height });

const PORTRAIT = size(2480, 3508);
const LANDSCAPE = size(3508, 2480);
const shot = size(1080, 2340);
const photo = size(1200, 1600);
const square = size(1000, 1000);

describe('기본값', () => {
  test('N=1, F=100%, P=5%, A4 세로, 컬러', () => {
    assert.deepEqual(DEFAULT_SETTINGS, { paper: 'a4', orientation: 'portrait', perSheet: 1, imageSize: 100, padding: 5, grayscale: false });
  });
  test('고를 수 있는 값', () => {
    assert.deepEqual(PER_SHEET_OPTIONS, [1, 2, 3, 4, 6, 8, 9]);
    assert.deepEqual(IMAGE_SIZE_OPTIONS, [100, 50, 30]);
    assert.deepEqual(PADDING_OPTIONS, [0, 3, 5, 10]);
  });
});

describe('칸 배치와 페이지 수', () => {
  // 표: N → 짧은 변 × 긴 변. 세로 용지는 가로=짧은 변, 가로 용지는 가로=긴 변.
  const grids = [
    [1, 1, 1, 1, 1],
    [2, 1, 2, 2, 1],
    [3, 1, 3, 3, 1],
    [4, 2, 2, 2, 2],
    [6, 2, 3, 3, 2],
    [8, 2, 4, 4, 2],
    [9, 3, 3, 3, 3],
  ];
  for (const [n, portraitColumns, portraitRows, landscapeColumns, landscapeRows] of grids) {
    test(`N=${n}: 세로 용지 ${portraitColumns}×${portraitRows}, 가로 용지 ${landscapeColumns}×${landscapeRows}`, () => {
      assert.deepEqual(gridFor(n, 'portrait'), { columns: portraitColumns, rows: portraitRows });
      assert.deepEqual(gridFor(n, 'landscape'), { columns: landscapeColumns, rows: landscapeRows });
    });
  }
  test('표에 없는 N은 오류', () => {
    assert.throws(() => gridFor(5, 'portrait'), RangeError);
    assert.throws(() => gridFor(0, 'portrait'), RangeError);
  });
  test('페이지 수 = ⌈항목 ÷ N⌉', () => {
    assert.equal(sheetCount(3, 1), 3);
    assert.equal(sheetCount(3, 2), 2);
    assert.equal(sheetCount(4, 2), 2);
    assert.equal(sheetCount(8, 8), 1);
    assert.equal(sheetCount(9, 8), 2);
    assert.equal(sheetCount(30, 9), 4); // 30 ÷ 9 = 3.33
  });
});

describe('간격과 여백', () => {
  // A4 300DPI: 여백 = 2480 × P%, 간격 = 여백 × 0.8
  const cases = [
    [0, 0, 0],
    [3, 74.4, 59.52],
    [5, 124, 99.2],
    [10, 248, 198.4],
  ];
  for (const [padding, margin, gap] of cases) {
    test(`A4 P=${padding}%: 여백 ${margin}, 간격 ${gap}`, () => {
      for (const page of [PORTRAIT, LANDSCAPE]) {
        const spacing = pageSpacing(page, padding);
        close(spacing.margin, margin);
        close(spacing.gap, gap);
      }
    });
  }
  test('기본 P=5%면 간격은 짧은 변의 4%다', () => {
    const { margin, gap } = pageSpacing(PORTRAIT);
    close(margin, 124);
    close(gap, 2480 * 0.04);
  });
  test('포인트로도 같은 비율이다: A4 595.2756pt의 5% = 29.7638, 4% = 23.811', () => {
    const page = size(595.2756, 841.8898);
    close(pageSpacing(page).margin, 29.7638);
    const [top, bottom] = cellRects(page, gridFor(2, 'portrait'));
    close(top.x, 29.7638);
    close(top.y, 29.7638);
    close(bottom.y - top.y - top.height, 23.811);
  });
  test('간격의 하한: P=0에서 PNG는 구분선 두께만큼, PDF는 0', () => {
    assert.deepEqual(pageSpacing(PORTRAIT, 0), { margin: 0, gap: 0 });
    assert.deepEqual(pageSpacing(PORTRAIT, 0, 7), { margin: 0, gap: 7 });
    close(pageSpacing(PORTRAIT, 10, 7).gap, 198.4); // 하한보다 크면 그대로
  });
});

// 칸 폭 = (용지 폭 − 여백×2 − 간격 × (열−1)) ÷ 열. 간격 99.2, 여백 124 → 여백 안쪽 2232×3260.
// 3칸 (3260 − 198.4)/3 = 1020.5333, 2칸 (3260 − 99.2)/2 = 1580.4, 4칸 (3260 − 297.6)/4 = 740.6
// 2열 (2232 − 99.2)/2 = 1066.4, 3열 (2232 − 198.4)/3 = 677.8667
// 둘째 칸 시작 = 여백 + 칸 + 간격. 예: 124 + 1580.4 + 99.2 = 1803.6
describe('칸 자리 (여백 124)', () => {
  const cases = [
    [1, 'portrait', 2232, 3260, null, null],
    [1, 'landscape', 3260, 2232, null, null],
    [2, 'portrait', 2232, 1580.4, null, 1803.6],
    [2, 'landscape', 1580.4, 2232, 1803.6, null],
    [3, 'portrait', 2232, 1020.5333, null, 1243.7333],
    [3, 'landscape', 1020.5333, 2232, 1243.7333, null],
    [4, 'portrait', 1066.4, 1580.4, 1289.6, 1803.6],
    [4, 'landscape', 1580.4, 1066.4, 1803.6, 1289.6],
    [6, 'portrait', 1066.4, 1020.5333, 1289.6, 1243.7333],
    [6, 'landscape', 1020.5333, 1066.4, 1243.7333, 1289.6],
    [8, 'portrait', 1066.4, 740.6, 1289.6, 963.8],
    [8, 'landscape', 740.6, 1066.4, 963.8, 1289.6],
    [9, 'portrait', 677.8667, 1020.5333, 901.0667, 1243.7333],
    [9, 'landscape', 1020.5333, 677.8667, 1243.7333, 901.0667],
  ];
  for (const [n, orientation, width, height, secondX, secondY] of cases) {
    test(`N=${n} ${orientation}`, () => {
      const page = orientation === 'portrait' ? PORTRAIT : LANDSCAPE;
      const grid = gridFor(n, orientation);
      const cells = cellRects(page, grid);
      assert.equal(cells.length, n);
      close(cells[0].x, 124);
      close(cells[0].y, 124);
      close(cells[0].width, width);
      close(cells[0].height, height);
      if (secondX !== null) close(cells[1].x, secondX);
      if (secondY !== null) close(cells[grid.columns].y, secondY);
      // 마지막 칸은 여백 안쪽 끝에 닿는다.
      close(cells.at(-1).x + cells.at(-1).width, page.width - 124);
      close(cells.at(-1).y + cells.at(-1).height, page.height - 124);
    });
  }
  test('왼쪽에서 오른쪽, 위에서 아래 순서로 채운다', () => {
    const cells = cellRects(PORTRAIT, gridFor(4, 'portrait'));
    assert.deepEqual(cells.map((c) => [c.x > 124, c.y > 124]), [
      [false, false],
      [true, false],
      [false, true],
      [true, true],
    ]);
  });
});

describe('칸 안에 맞추고 F를 곱해 가운데에 놓기', () => {
  const page = { x: 0, y: 0, ...PORTRAIT };
  // 1000×1000: 배율 = min(2480/1000, 3508/1000) → 2480×2480
  test('F=100%는 칸에 꽉 차고 위아래 가운데', () => {
    assert.deepEqual(fitInCell(square, page, 100), rect(0, 514, 2480, 2480)); // (3508 − 2480) ÷ 2
  });
  test('F=50%는 변이 절반이고 칸 가운데', () => {
    // 1240×1240, x = (2480 − 1240) ÷ 2 = 620, y = (3508 − 1240) ÷ 2 = 1134
    assert.deepEqual(fitInCell(square, page, 50), rect(620, 1134, 1240, 1240));
  });
  test('F=30%는 변이 30%이고 칸 가운데', () => {
    // 744×744, x = (2480 − 744) ÷ 2 = 868, y = (3508 − 744) ÷ 2 = 1382
    const fitted = fitInCell(square, page, 30);
    close(fitted.width, 744);
    close(fitted.height, 744);
    close(fitted.x, 868);
    close(fitted.y, 1382);
  });
  test('F는 넓이가 아니라 변의 비율이다 (50%면 넓이 25%)', () => {
    const full = fitInCell(photo, page, 100);
    const half = fitInCell(photo, page, 50);
    close((half.width * half.height) / (full.width * full.height), 0.25);
  });
  test('원본이 칸보다 작아도 키운다', () => {
    assert.deepEqual(fitInCell(size(10, 10), page, 100), rect(0, 514, 2480, 2480));
  });
  test('칸 시작 위치를 더한다', () => {
    // 칸 (100,200) 400×400에 200×100, F=50%: 배율 2 × 0.5 = 1 → 200×100, x = 100 + 100, y = 200 + 150
    assert.deepEqual(fitInCell(size(200, 100), rect(100, 200, 400, 400), 50), rect(200, 350, 200, 100));
  });
});

describe('페이지 나누기', () => {
  test('N개씩 묶고 마지막 페이지의 남는 칸은 비운다', () => {
    const { grid, pages } = layoutPages(Array(5).fill(square), PORTRAIT, { perSheet: 2, orientation: 'portrait' });
    assert.deepEqual(grid, { columns: 1, rows: 2 });
    assert.deepEqual(pages.map((images) => images.map((image) => image.index)), [[0, 1], [2, 3], [4]]);
  });
  test('페이지마다 첫 칸부터 다시 채운다', () => {
    const { pages } = layoutPages(Array(3).fill(square), PORTRAIT, { perSheet: 2, orientation: 'portrait' });
    assert.equal(pages[1][0].y, pages[0][0].y);
  });
  test('단위가 없다: 포인트 크기로도 같은 비율이다', () => {
    const inPixels = layoutPages([square], size(1000, 2000), { perSheet: 2, imageSize: 50 }).pages[0][0];
    const inPoints = layoutPages([square], size(100, 200), { perSheet: 2, imageSize: 50 }).pages[0][0];
    close(inPixels.x, inPoints.x * 10);
    close(inPixels.width, inPoints.width * 10);
  });
  test('칸은 여백 안쪽에서 나눈다', () => {
    // 2480×3508, 여백 124, N=1: 안쪽 2232×3260. 1000×1000 → 2232×2232, y = 124 + (3260 − 2232)/2 = 638
    const { pages } = layoutPages([square], PORTRAIT, { orientation: 'portrait' });
    assert.deepEqual(pages[0][0], { index: 0, ...rect(124, 638, 2232, 2232) });
  });
});

describe('구분선 두께', () => {
  const cases = [
    [2480, 7], // 7.44
    [2340, 7], // 7.02
    [2500, 8], // 7.5는 올림
    [1300, 4], // 3.9
    [751, 2], // 2.253
    [400, 2], // 1.2지만 최소 2px
    [1, 2],
  ];
  for (const [side, expected] of cases) {
    test(`${side}px → ${expected}px`, () => assert.equal(dividerThickness(side), expected));
  }
});

// 간격 99.2, 두께 7 → 간격 안에서 선까지 (99.2 − 7) ÷ 2 = 46.1. 선 시작 = 칸 끝 + 46.1
describe('페이지 안 구분선 (A4 300DPI, 두께 7, 여백 124)', () => {
  const dividers = (n, orientation, count) =>
    pageDividers(orientation === 'portrait' ? PORTRAIT : LANDSCAPE, gridFor(n, orientation), count, 7);

  test('N=1에는 없다', () => {
    assert.deepEqual(dividers(1, 'portrait', 1), []);
  });
  test('N=2 세로 용지: 가로줄 하나가 여백 안쪽 폭 전체', () => {
    // y = 124 + 1580.4 + 46.1 = 1750.5 → 1751, x 124 ~ 2356 (폭 2232)
    assert.deepEqual(dividers(2, 'portrait', 2), [rect(124, 1751, 2232, 7)]);
  });
  test('N=2 가로 용지: 세로줄 하나가 줄 높이 전체', () => {
    // x = 1750.5 → 1751, 줄 124 ~ 2356
    assert.deepEqual(dividers(2, 'landscape', 2), [rect(1751, 124, 7, 2232)]);
  });
  test('N=2 마지막 페이지에 이미지 하나면 선이 없다', () => {
    assert.deepEqual(dividers(2, 'portrait', 1), []);
    assert.deepEqual(dividers(2, 'landscape', 1), []);
  });
  test('N=3 세로 용지: 가로줄 둘, 빈 줄 쪽은 없다', () => {
    // 124 + 1020.5333 + 46.1 = 1190.6333 → 1191 / 1243.7333 + 1020.5333 + 46.1 = 2310.3667 → 2310
    assert.deepEqual(dividers(3, 'portrait', 3), [rect(124, 1191, 2232, 7), rect(124, 2310, 2232, 7)]);
    assert.deepEqual(dividers(3, 'portrait', 2), [rect(124, 1191, 2232, 7)]);
  });
  test('N=3 가로 용지: 세로줄 둘, 빈 칸 쪽은 없다', () => {
    assert.deepEqual(dividers(3, 'landscape', 3), [rect(1191, 124, 7, 2232), rect(2310, 124, 7, 2232)]);
    assert.deepEqual(dividers(3, 'landscape', 2), [rect(1191, 124, 7, 2232)]);
  });
  test('N=4 가득 찬 페이지', () => {
    // 가로줄 y = 1751, 세로줄 x = 124 + 1066.4 + 46.1 = 1236.5 → 1237
    // 첫 줄 124 ~ 1704.4 → 124 ~ 1704 (높이 1580), 둘째 줄 1803.6 ~ 3384 → 1804 ~ 3384 (높이 1580)
    assert.deepEqual(dividers(4, 'portrait', 4), [
      rect(124, 1751, 2232, 7),
      rect(1237, 124, 7, 1580),
      rect(1237, 1804, 7, 1580),
    ]);
  });
  test('N=4 이미지 3개: 아래 줄의 빈 칸 쪽으로 세로줄을 긋지 않는다', () => {
    assert.deepEqual(dividers(4, 'portrait', 3), [rect(124, 1751, 2232, 7), rect(1237, 124, 7, 1580)]);
  });
  test('N=4 이미지 2개: 아래 줄이 비면 가로줄도 없다', () => {
    assert.deepEqual(dividers(4, 'portrait', 2), [rect(1237, 124, 7, 1580)]);
  });
  test('N=4 이미지 1개: 선이 없다', () => {
    assert.deepEqual(dividers(4, 'portrait', 1), []);
  });
  test('N=6 가로 용지 (3열 2줄), 일부만 찬 페이지', () => {
    // 가로줄 y = 124 + 1066.4 + 46.1 = 1236.5 → 1237, 폭 3508 − 248 = 3260. 세로줄 x = 1191, 2310
    // 첫 줄 124 ~ 1190.4 → 높이 1066, 둘째 줄 1289.6 ~ 2356 → 1290 ~ 2356, 높이 1066
    assert.deepEqual(dividers(6, 'landscape', 6), [
      rect(124, 1237, 3260, 7),
      rect(1191, 124, 7, 1066),
      rect(2310, 124, 7, 1066),
      rect(1191, 1290, 7, 1066),
      rect(2310, 1290, 7, 1066),
    ]);
    assert.deepEqual(dividers(6, 'landscape', 5), [
      rect(124, 1237, 3260, 7),
      rect(1191, 124, 7, 1066),
      rect(2310, 124, 7, 1066),
      rect(1191, 1290, 7, 1066),
    ]);
    assert.deepEqual(dividers(6, 'landscape', 4), [
      rect(124, 1237, 3260, 7),
      rect(1191, 124, 7, 1066),
      rect(2310, 124, 7, 1066),
    ]);
  });
  test('N=8 세로 용지 (2열 4줄)', () => {
    // 칸 높이 740.6, 줄 시작 124, 963.8, 1803.6, 2643.4
    // 가로줄: 124+740.6+46.1=910.7→911, 963.8+740.6+46.1=1750.5→1751, 1803.6+740.6+46.1=2590.3→2590
    // 줄 범위 반올림: 124~865 (741), 964~1704 (740), 1804~2544 (740), 2643~3384 (741)
    assert.deepEqual(dividers(8, 'portrait', 8), [
      rect(124, 911, 2232, 7),
      rect(124, 1751, 2232, 7),
      rect(124, 2590, 2232, 7),
      rect(1237, 124, 7, 741),
      rect(1237, 964, 7, 740),
      rect(1237, 1804, 7, 740),
      rect(1237, 2643, 7, 741),
    ]);
  });
  test('N=9 이미지 7개와 8개', () => {
    // 칸 677.8667×1020.5333. 세로줄 x: 124+677.8667+46.1=847.9667→848, 901.0667+677.8667+46.1=1625.0333→1625
    // 줄 범위 반올림: 124~1145 (1021), 1244~2264 (1020), 2363~3384 (1021)
    const seven = dividers(9, 'portrait', 7);
    assert.deepEqual(seven, [
      rect(124, 1191, 2232, 7),
      rect(124, 2310, 2232, 7),
      rect(848, 124, 7, 1021),
      rect(1625, 124, 7, 1021),
      rect(848, 1244, 7, 1020),
      rect(1625, 1244, 7, 1020),
    ]);
    assert.deepEqual(dividers(9, 'portrait', 8), [...seven, rect(848, 2363, 7, 1021)]);
  });
});

describe('PNG 방향은 용지 비율로 정한다', () => {
  const wide = size(4000, 1000);
  const tall = size(1000, 4000);
  test('A4 세로는 가로 배치: 이미지가 가로형이어도 그렇다', () => {
    assert.equal(pngDirection([wide, wide], a4()), LayoutDirection.horizontal);
    assert.equal(planPng([wide, wide], a4()).direction, LayoutDirection.horizontal);
  });
  test('A4 가로는 세로 배치: 이미지가 세로형이어도 그렇다', () => {
    assert.equal(pngDirection([tall, tall], a4Landscape()), LayoutDirection.vertical);
    assert.equal(planPng([tall, tall], a4Landscape()).direction, LayoutDirection.vertical);
  });
  for (const { code } of PAPERS.filter((p) => p.code !== 'original')) {
    test(`${code}: 세로 용지는 가로 배치, 가로 용지는 세로 배치`, () => {
      assert.equal(pngDirection([wide], { paper: code, orientation: 'portrait' }), LayoutDirection.horizontal);
      assert.equal(pngDirection([tall], { paper: code, orientation: 'landscape' }), LayoutDirection.vertical);
    });
  }
  test("'원본 크기'만 이미지 비율을 본다", () => {
    const original = { paper: 'original', orientation: 'portrait' };
    assert.equal(pngDirection([wide, wide], original), LayoutDirection.vertical);
    assert.equal(pngDirection([tall, tall], original), LayoutDirection.horizontal);
    assert.equal(planPng([wide, wide], original).direction, LayoutDirection.vertical);
  });
});

describe('PNG 용지 계획 (여백 124, 간격 99.2)', () => {
  test('기본값: 2장이면 A4 2쪽을 옆으로 잇고 사이에 구분선', () => {
    // 2480×2 + 7 = 4967. 17,424,236픽셀이라 줄이지 않는다.
    // 안쪽 2232×3260. 1200×1600: 배율 min(1.86, 2.0375) = 1.86 → 2232×2976, y = 124 + 142 = 266
    const plan = planPng([photo, photo], a4({ perSheet: 1, imageSize: 100 }));
    assert.equal(plan.onPaper, true);
    assert.equal(plan.pageCount, 2);
    assert.equal(plan.canvasWidth, 4967);
    assert.equal(plan.canvasHeight, 3508);
    assert.equal(plan.dividerThickness, 7);
    assert.deepEqual(plan.placements, [rect(124, 266, 2232, 2976), rect(2611, 266, 2232, 2976)]); // 2487 + 124
    assert.deepEqual(plan.dividers, [rect(2480, 0, 7, 3508)]);
  });
  test('이웃한 쪽은 여백·선·여백으로 보인다', () => {
    // 첫 이미지 끝 2356, 여백 124 → 2480, 선 7 → 2487, 여백 124 → 2611
    const plan = planPng([photo, photo], a4());
    const [first, second] = plan.placements;
    assert.equal(first.x + first.width, 2356);
    assert.equal(plan.dividers[0].x - (first.x + first.width), 124);
    assert.equal(second.x - (plan.dividers[0].x + plan.dividers[0].width), 124);
  });
  test('A4 가로 2장: 위아래로 잇고 사이에 구분선', () => {
    // 3508 × 4967. 안쪽 3260×2232. 4000×3000: 배율 2232/3000 → 2976×2232, x = 124 + 142 = 266, y = 124
    const plan = planPng([size(4000, 3000), size(4000, 3000)], a4Landscape());
    assert.equal(plan.canvasWidth, 3508);
    assert.equal(plan.canvasHeight, 4967);
    assert.deepEqual(plan.placements, [rect(266, 124, 2976, 2232), rect(266, 2611, 2976, 2232)]);
    assert.deepEqual(plan.dividers, [rect(0, 2480, 3508, 7)]);
  });
  test('N=2, 3장: 2쪽이고 마지막 쪽의 빈 칸에는 선이 없다', () => {
    // 칸 2232×1580.4. 1200×1600: 배율 0.98775 → 1185.3×1580.4
    // x = 124 + 523.35 = 647.35 → 647, 끝 1832.65 → 1833 (폭 1186)
    // y = 124 ~ 1704.4 → 124 ~ 1704, 둘째 칸 1803.6 → 1804 ~ 3384. 둘째 쪽 시작 2487
    const plan = planPng([photo, photo, photo], a4({ perSheet: 2 }));
    assert.equal(plan.pageCount, 2);
    assert.equal(plan.canvasWidth, 4967);
    assert.equal(plan.canvasHeight, 3508);
    assert.deepEqual(plan.placements, [
      rect(647, 124, 1186, 1580),
      rect(647, 1804, 1186, 1580),
      rect(3134, 124, 1186, 1580),
    ]);
    assert.deepEqual(plan.dividers, [rect(124, 1751, 2232, 7), rect(2480, 0, 7, 3508)]);
  });
  test('둘째 쪽의 안쪽 선은 쪽 시작만큼 옮긴다', () => {
    // 첫 쪽 가로줄 x=124, 쪽 사이 x=2480, 둘째 쪽 가로줄 x=2487+124=2611
    const plan = planPng(Array(4).fill(photo), a4({ perSheet: 2 }));
    assert.deepEqual(plan.dividers, [rect(124, 1751, 2232, 7), rect(2480, 0, 7, 3508), rect(2611, 1751, 2232, 7)]);
  });
  test('F=50%, N=1: 페이지 가운데에 놓고 나머지는 비운다', () => {
    // 1.86 × 0.5 = 0.93 → 1116×1488, x = 124 + 558 = 682, y = 124 + 886 = 1010
    const plan = planPng([photo, photo], a4({ imageSize: 50 }));
    assert.deepEqual(plan.placements[0], rect(682, 1010, 1116, 1488));
    assert.deepEqual(plan.placements[1], rect(3169, 1010, 1116, 1488)); // 2487 + 682
  });
  test('F=30%, N=1', () => {
    // 669.6×892.8, x = 905.2 → 905, 끝 1574.8 → 1575 (폭 670), y = 1307.6 → 1308, 끝 2200.4 → 2200 (높이 892)
    assert.deepEqual(planPng([photo, photo], a4({ imageSize: 30 })).placements[0], rect(905, 1308, 670, 892));
  });
  test('F=50%, N=4: 칸마다 가운데', () => {
    // 칸 1066.4×1580.4, 1000×1000 → 1066.4 × 0.5 = 533.2
    // 첫 칸 x = 124 + 266.6 = 390.6 → 391, 끝 923.8 → 924 (폭 533), y = 124 + 523.6 = 647.6 → 648, 끝 1180.8 → 1181 (높이 533)
    // 둘째 칸 x = 1289.6 + 266.6 = 1556.2 → 1556, 끝 2089.4 → 2089
    // 셋째 칸 y = 1803.6 + 523.6 = 2327.2 → 2327, 끝 2860.4 → 2860
    const plan = planPng(Array(3).fill(square), a4({ perSheet: 4, imageSize: 50 }));
    assert.deepEqual(plan.placements, [
      rect(391, 648, 533, 533),
      rect(1556, 648, 533, 533),
      rect(391, 2327, 533, 533),
    ]);
  });
});

describe('PNG 캔버스 상한은 구분선까지 포함한다', () => {
  test('A4 2쪽은 줄이지 않는다', () => {
    const plan = planPng([photo, photo], a4());
    assert.equal(plan.canvasWidth * plan.canvasHeight, 17424236); // 4967 × 3508
  });
  test('A4 3쪽: 약 288DPI', () => {
    // 줄이기 전 (2480×3 + 7×2) × 3508 = 7454 × 3508 = 26,148,632 → g = √(24000000/26148632) = 0.958034
    // 쪽 폭 floor(2375.92) = 2375, 높이 floor(3360.78) = 3360, 두께 round(7.125) = 7
    // 캔버스 2375×3 + 14 = 7139 × 3360 = 23,987,040
    const plan = planPng(Array(3).fill(photo), a4());
    assert.equal(plan.pageWidth, 2375);
    assert.equal(plan.pageHeight, 3360);
    assert.equal(plan.dividerThickness, 7);
    assert.equal(plan.canvasWidth, 7139);
    assert.equal(plan.canvasHeight, 3360);
    close((plan.pageWidth / 2480) * 300, 287.3, 0.1);
    // 여백도 줄어든 쪽의 짧은 변 기준이다: 2375 × 5% = 118.75. 안쪽 2137.5×3122.5
    // 1200×1600 → 2137.5×2850, x = 118.75 → 119, 끝 2256.25 → 2256 (폭 2137), y = 118.75 + 136.25 = 255
    assert.deepEqual(plan.placements[0], rect(119, 255, 2137, 2850));
    assert.deepEqual(plan.placements[2], rect(4883, 255, 2137, 2850)); // 둘째 쪽까지 (2375 + 7) × 2 = 4764 + 119
  });
  test('A4 10쪽: 약 158DPI', () => {
    // 줄이기 전 (24800 + 63) × 3508 = 87,219,404 → g = 0.524565
    // 쪽 1300×1840, 두께 round(3.9) = 4, 캔버스 13000 + 36 = 13036 × 1840 = 23,986,240
    const plan = planPng(Array(10).fill(photo), a4());
    assert.equal(plan.pageWidth, 1300);
    assert.equal(plan.pageHeight, 1840);
    assert.equal(plan.dividerThickness, 4);
    assert.equal(plan.canvasWidth, 13036);
    assert.equal(plan.canvasHeight, 1840);
  });
  test('A4 30쪽: 약 91DPI, 두께는 최소값 근처로 줄어든다', () => {
    // 줄이기 전 (74400 + 203) × 3508 = 74603 × 3508 = 261,707,324 → g = 0.302829
    // 쪽 floor(751.02) = 751, floor(1062.32) = 1062, 두께 round(2.253) = 2
    // 캔버스 751×30 + 2×29 = 22588 × 1062 = 23,988,456
    const plan = planPng(Array(30).fill(photo), a4());
    assert.equal(plan.pageWidth, 751);
    assert.equal(plan.pageHeight, 1062);
    assert.equal(plan.dividerThickness, 2);
    assert.equal(plan.canvasWidth, 22588);
    assert.equal(plan.canvasHeight, 1062);
    assert.equal(plan.dividers.length, 29);
    assert.deepEqual(plan.dividers[0], rect(751, 0, 2, 1062));
    assert.deepEqual(plan.dividers[28], rect(21835, 0, 2, 1062)); // 29쪽 끝 = 751×29 + 2×28
    // 마지막 쪽 시작 (751 + 2) × 29 = 21837, 여백 751 × 5% = 37.55 → 38
    assert.equal(plan.placements[29].x, 21837 + 38);
    close((plan.pageWidth / 2480) * 300, 90.8, 0.1);
  });
  test('A4 가로 30쪽은 세로로 같은 값', () => {
    const plan = planPng(Array(30).fill(photo), a4Landscape());
    assert.equal(plan.canvasWidth, 1062);
    assert.equal(plan.canvasHeight, 22588);
    assert.deepEqual(plan.dividers[0], rect(0, 751, 1062, 2));
  });
  test('구분선을 빼고 계산하면 넘지 않는 경계에서도 줄인다', () => {
    // 상한을 쪽 2장 넓이 그대로 둔다. 쪽만 세면 딱 맞지만 구분선 때문에 넘는다.
    const plan = planPngOnPaper([square, square], a4(), { maxCanvasPixels: 2480 * 3508 * 2 });
    // (2480×2 + 7) × 3508 = 17,424,236 > 17,399,680 → g = √(17399680/17424236) = 0.999295
    // 쪽 floor(2478.25) = 2478, floor(3505.53) = 3505, 두께 round(7.434) = 7, 캔버스 4963 × 3505
    assert.equal(plan.pageWidth, 2478);
    assert.equal(plan.pageHeight, 3505);
    assert.equal(plan.canvasWidth, 4963);
    assert.equal(plan.canvasHeight, 3505);
    assert.ok(plan.canvasWidth * plan.canvasHeight <= 2480 * 3508 * 2);
  });
  test('모든 용지·N·F·방향·쪽 수에서 상한을 지키고 자리가 어긋나지 않는다', () => {
    const papers = PAPERS.filter((p) => p.code !== 'original').map((p) => p.code);
    for (const paper of papers) {
      for (const orientation of ['portrait', 'landscape']) {
        for (const perSheet of PER_SHEET_OPTIONS) {
          for (const imageSize of IMAGE_SIZE_OPTIONS) {
            for (const padding of PADDING_OPTIONS) {
            for (const count of [1, 2, 3, 7, 13, 30]) {
              const sizes = Array.from({ length: count }, (_, i) => (i % 2 ? size(4000, 1000) : size(900, 2000)));
              const plan = planPng(sizes, { paper, orientation, perSheet, imageSize, padding });
              const label = `${paper} ${orientation} N=${perSheet} F=${imageSize} P=${padding} ${count}장`;
              assert.ok(plan.canvasWidth * plan.canvasHeight <= 24000000, `cap ${label}`);
              assert.ok(plan.dividerThickness >= 2, `thickness ${label}`);
              assert.equal(plan.placements.length, count, label);
              const inside = (r) =>
                r.x >= 0 && r.y >= 0 && r.x + r.width <= plan.canvasWidth && r.y + r.height <= plan.canvasHeight;
              assert.ok(plan.placements.every(inside), `placement ${label}`);
              assert.ok(plan.dividers.every(inside), `divider ${label}`);
              const overlaps = (a, b) =>
                a.x < b.x + b.width && b.x < a.x + a.width && a.y < b.y + b.height && b.y < a.y + a.height;
              for (const image of plan.placements) {
                for (const divider of plan.dividers) assert.ok(!overlaps(image, divider), `overlap ${label}`);
              }
              // 모든 이미지가 자기 쪽의 여백 안쪽에 있다.
              const margin = Math.floor((Math.min(plan.pageWidth, plan.pageHeight) * padding) / 100);
              const stepX = plan.canvasWidth > plan.pageWidth ? plan.pageWidth + plan.dividerThickness : 0;
              const stepY = plan.canvasHeight > plan.pageHeight ? plan.pageHeight + plan.dividerThickness : 0;
              plan.placements.forEach((r, i) => {
                const p = Math.floor(i / perSheet);
                const left = r.x - p * stepX;
                const top = r.y - p * stepY;
                assert.ok(left >= margin && left + r.width <= plan.pageWidth - margin, `margin x ${label}`);
                assert.ok(top >= margin && top + r.height <= plan.pageHeight - margin, `margin y ${label}`);
              });
            }
            }
          }
        }
      }
    }
  });
});

describe("'원본 크기' 여백과 구분선", () => {
  const original = { paper: 'original', orientation: 'portrait', perSheet: 4, imageSize: 30 };

  test('스크린샷 3장: [여백][이미지][여백][선][여백][이미지][여백]…', () => {
    // 공통 변(높이) 2340: 여백 × 5% = 117, 두께 × 0.3% = 7.02 → 7. N과 F는 쓰지 않는다.
    // 폭 (117 + 1080 + 117)×3 + 7×2 = 3956, 높이 117 + 2340 + 117 = 2574
    // 이미지 x: 117, 1438 (117+1080+117+7+117), 2759. 선 x: 1314, 2635. 선은 캔버스 높이 전체다.
    const plan = planPng([shot, shot, shot], original);
    assert.equal(plan.onPaper, false);
    assert.equal(plan.paddingPx, 117);
    assert.equal(plan.dividerThickness, 7);
    assert.equal(plan.canvasWidth, 3956);
    assert.equal(plan.canvasHeight, 2574);
    assert.deepEqual(plan.placements, [rect(117, 117, 1080, 2340), rect(1438, 117, 1080, 2340), rect(2759, 117, 1080, 2340)]);
    assert.deepEqual(plan.dividers, [rect(1314, 0, 7, 2574), rect(2635, 0, 7, 2574)]);
  });
  test('세로 배치: 공통 변(폭 2000)의 5%, 0.3%', () => {
    // 여백 100, 두께 6. 폭 2200, 높이 (100 + 1500 + 100)×2 + 6 = 3406
    // 첫 이미지 y 100, 선 y 1700, 둘째 이미지 y 1806
    const plan = planPngOriginal([size(4000, 3000), size(2000, 1500)]);
    assert.equal(plan.paddingPx, 100);
    assert.equal(plan.dividerThickness, 6);
    assert.equal(plan.canvasWidth, 2200);
    assert.equal(plan.canvasHeight, 3406);
    assert.deepEqual(plan.placements, [rect(100, 100, 2000, 1500), rect(100, 1806, 2000, 1500)]);
    assert.deepEqual(plan.dividers, [rect(0, 1700, 2200, 6)]);
  });
  test('공통 변이 작으면 두께는 최소 2px', () => {
    // 공통 변 300: 여백 15, 두께 0.9 → 2. 폭 330, 높이 (15 + 200 + 15)×2 + 2 = 462
    const plan = planPngOriginal([size(300, 200), size(300, 200)]);
    assert.equal(plan.paddingPx, 15);
    assert.equal(plan.dividerThickness, 2);
    assert.equal(plan.canvasWidth, 330);
    assert.equal(plan.canvasHeight, 462);
  });
  test('이미지가 여백과 선에 겹치지 않는다', () => {
    const plan = planPngOriginal([shot, size(4000, 3000), size(900, 1600), shot]);
    for (const image of plan.placements) {
      for (const d of plan.dividers) {
        const apart = image.x + image.width <= d.x || d.x + d.width <= image.x || image.y + image.height <= d.y || d.y + d.height <= image.y;
        assert.ok(apart, JSON.stringify([image, d]));
      }
      assert.ok(image.x >= plan.paddingPx && image.y >= plan.paddingPx);
      assert.ok(image.x + image.width <= plan.canvasWidth - plan.paddingPx);
      assert.ok(image.y + image.height <= plan.canvasHeight - plan.paddingPx);
    }
  });
});

describe('여백 P: PNG 용지 (A4 300DPI, 두께 7)', () => {
  test('P=10%: 여백 248, 간격 198.4', () => {
    // 칸 1984×1406.8, 1200×1600 → 1055.1×1406.8. x = 248 + 464.45 = 712.45 → 712, 끝 1767.55 → 1768 (폭 1056)
    // 위 칸 248 ~ 1654.8 → 1655 (높이 1407), 아래 칸 1853.2 → 1853 ~ 3260 (높이 1407)
    // 가로줄 y = 248 + 1406.8 + 95.7 = 1750.5 → 1751, x 248 ~ 2232
    const plan = planPng([photo, photo], a4({ perSheet: 2, padding: 10 }));
    assert.deepEqual(plan.placements, [rect(712, 248, 1056, 1407), rect(712, 1853, 1056, 1407)]);
    assert.deepEqual(plan.dividers, [rect(248, 1751, 1984, 7)]);
  });
  test('P=3%: 여백 74.4, 간격 59.52', () => {
    // 칸 2331.2×1649.84, 1200×1600 → 1237.38×1649.84. x = 74.4 + 546.91 = 621.31 → 621, 끝 1858.69 → 1859 (폭 1238)
    // 위 칸 74.4 → 74 ~ 1724.24 → 1724 (높이 1650), 아래 칸 1783.76 → 1784 ~ 3433.6 → 3434 (높이 1650)
    // 가로줄 x 74.4 → 74, 끝 2405.6 → 2406 (폭 2332)
    const plan = planPng([photo, photo], a4({ perSheet: 2, padding: 3 }));
    assert.deepEqual(plan.placements, [rect(621, 74, 1238, 1650), rect(621, 1784, 1238, 1650)]);
    assert.deepEqual(plan.dividers, [rect(74, 1751, 2332, 7)]);
  });
  test('P=0%: 간격이 구분선 두께와 같고 선이 간격을 꽉 채운다', () => {
    // 칸 2480×1750.5, 1200×1600 → 1312.875×1750.5. x = 583.5625 → 584, 끝 1896.4375 → 1896 (폭 1312)
    // 위 칸 0 ~ 1750.5 → 1751, 선 1751 ~ 1758, 아래 칸 1757.5 → 1758 ~ 3508 (높이 1750)
    const plan = planPng([photo, photo], a4({ perSheet: 2, padding: 0 }));
    assert.deepEqual(plan.placements, [rect(584, 0, 1312, 1751), rect(584, 1758, 1312, 1750)]);
    assert.deepEqual(plan.dividers, [rect(0, 1751, 2480, 7)]);
    const [top, bottom] = plan.placements;
    const [line] = plan.dividers;
    assert.equal(line.y, top.y + top.height); // 이미지에 바로 붙는다
    assert.equal(bottom.y, line.y + line.height);
  });
  test('P=0%, N=4: 세로줄도 간격을 꽉 채운다', () => {
    // 칸 1236.5×1750.5. 세로줄 x = 1236.5 → 1237, 첫 줄 0 ~ 1751, 둘째 줄 1757.5 → 1758 ~ 3508 (높이 1750)
    const plan = planPng(Array(4).fill(photo), a4({ perSheet: 4, padding: 0 }));
    assert.deepEqual(plan.dividers, [rect(0, 1751, 2480, 7), rect(1237, 0, 7, 1751), rect(1237, 1758, 7, 1750)]);
  });
  test('P=0%, N=1: 페이지 사이에도 선뿐이다 [이미지][선][이미지]', () => {
    // 1200×1600 → 2480×3306.67, y = 100.67 → 101, 끝 3407.33 → 3407 (높이 3306). 둘째 쪽 시작 2487
    const plan = planPng([photo, photo], a4({ padding: 0 }));
    assert.deepEqual(plan.placements, [rect(0, 101, 2480, 3306), rect(2487, 101, 2480, 3306)]);
    assert.deepEqual(plan.dividers, [rect(2480, 0, 7, 3508)]);
  });
  test('P=0%, 가로 용지 N=2: 세로줄이 간격을 꽉 채운다', () => {
    // 칸 1750.5×2480, 4000×3000 → 1750.5×1312.875. y = 583.5625 → 584, 끝 1896.4375 → 1896 (높이 1312)
    // 왼쪽 0 ~ 1751, 선 1751 ~ 1758, 오른쪽 1757.5 → 1758 ~ 3508 (폭 1750)
    const plan = planPng([size(4000, 3000), size(4000, 3000)], a4Landscape({ perSheet: 2, padding: 0 }));
    assert.deepEqual(plan.placements, [rect(0, 584, 1751, 1312), rect(1758, 584, 1750, 1312)]);
    assert.deepEqual(plan.dividers, [rect(1751, 0, 7, 2480)]);
  });
  test('P는 캔버스 크기를 바꾸지 않는다. 페이지 크기와 구분선으로 정해진다', () => {
    for (const padding of PADDING_OPTIONS) {
      const plan = planPng(Array(3).fill(photo), a4({ padding }));
      assert.deepEqual([plan.canvasWidth, plan.canvasHeight], [7139, 3360], `P=${padding}`);
    }
  });
});

describe("여백 P: '원본 크기' PNG", () => {
  const original = (padding) => ({ paper: 'original', orientation: 'portrait', padding });
  // 스크린샷 3장, 공통 변 2340, 두께 7. 폭 = (여백×2 + 1080)×3 + 14, 높이 = 2340 + 여백×2
  const cases = [
    [0, 0, 3254, 2340],
    [3, 70, 3674, 2480], // 2340 × 3% = 70.2 → 70
    [5, 117, 3956, 2574],
    [10, 234, 4658, 2808],
  ];
  for (const [padding, paddingPx, width, height] of cases) {
    test(`P=${padding}%: 여백 ${paddingPx}, 캔버스 ${width}×${height}`, () => {
      const plan = planPng([shot, shot, shot], original(padding));
      assert.equal(plan.paddingPx, paddingPx);
      assert.deepEqual([plan.canvasWidth, plan.canvasHeight], [width, height]);
      assert.equal(plan.placements[0].x, paddingPx);
      assert.equal(plan.placements[0].y, paddingPx);
    });
  }
  test('P=0%: [이미지][선][이미지]이고 여백이 없다', () => {
    const plan = planPng([shot, shot, shot], original(0));
    assert.deepEqual(plan.placements, [rect(0, 0, 1080, 2340), rect(1087, 0, 1080, 2340), rect(2174, 0, 1080, 2340)]);
    assert.deepEqual(plan.dividers, [rect(1080, 0, 7, 2340), rect(2167, 0, 7, 2340)]);
  });
  test('P=10%는 상한에도 들어간다', () => {
    // 4000×3000 10장: 여백 400, 폭 4800, 높이 (800 + 3000)×10 + 12×9 = 38108. 182,918,400 → g = 0.362224
    // 공통 변 floor(1448.89) = 1448, 장당 round(1086.67) = 1087, 여백 round(144.8) = 145, 두께 round(4.344) = 4
    // 폭 1448 + 290 = 1738, 높이 (290 + 1087)×10 + 36 = 13806. 23,994,828
    const plan = planPngOriginal(Array(10).fill(size(4000, 3000)), { padding: 10 });
    assert.equal(plan.canvasWidth, 1738);
    assert.equal(plan.canvasHeight, 13806);
    assert.ok(plan.canvasWidth * plan.canvasHeight <= 24000000);
  });
  test('P와 무관하게, 비율이 다른 이미지가 섞여도 상한을 지킨다 (반올림으로 커져도)', () => {
    let seed = 11;
    const next = (max) => {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return 1 + (seed % max);
    };
    for (let trial = 0; trial < 400; trial++) {
      const sizes = Array.from({ length: next(30) }, () => size(next(9000), next(9000)));
      for (const padding of PADDING_OPTIONS) {
        const plan = planPngOriginal(sizes, { padding });
        assert.ok(plan.canvasWidth * plan.canvasHeight <= 24000000, `trial ${trial} P=${padding}`);
      }
    }
  });
});

describe("'원본 크기' PNG는 반올림한다: 작은 이미지가 납작해지지 않는다", () => {
  test('501×90 + 90×501 + 16×16: 16×2가 아니라 16×3', () => {
    // Σ ln r = 0이라 세로 배치. 공통 폭 16. 90 × 16/501 = 2.874 → 3, 501 × 16/90 = 89.07 → 89, 16 → 16
    // P=0: 두께 2(최소). 높이 3 + 2 + 89 + 2 + 16 = 112
    const plan = planPngOriginal([size(501, 90), size(90, 501), size(16, 16)], { padding: 0 });
    assert.deepEqual(plan.placements, [rect(0, 0, 16, 3), rect(0, 5, 16, 89), rect(0, 96, 16, 16)]);
    assert.deepEqual([plan.canvasWidth, plan.canvasHeight], [16, 112]);
  });
  test('501×90 + 32×32: 32×5가 아니라 32×6', () => {
    // 세로 배치. 공통 폭 32. 90 × 32/501 = 5.749 → 6, 32 → 32. P=0: 높이 6 + 2 + 32 = 40
    const plan = planPngOriginal([size(501, 90), size(32, 32)], { padding: 0 });
    assert.deepEqual(plan.placements, [rect(0, 0, 32, 6), rect(0, 8, 32, 32)]);
    assert.deepEqual([plan.canvasWidth, plan.canvasHeight], [32, 40]);
  });
  test('기본 P=5%에서도 같다', () => {
    // 공통 폭 16: 여백 round(0.8) = 1, 폭 18, 높이 (2+3) + 2 + (2+89) + 2 + (2+16) = 118
    const first = planPngOriginal([size(501, 90), size(90, 501), size(16, 16)]);
    assert.deepEqual(first.placements[0], rect(1, 1, 16, 3));
    assert.deepEqual([first.canvasWidth, first.canvasHeight], [18, 118]);
    // 공통 폭 32: 여백 round(1.6) = 2, 폭 36, 높이 (4+6) + 2 + (4+32) = 48
    const second = planPngOriginal([size(501, 90), size(32, 32)]);
    assert.deepEqual(second.placements[0], rect(2, 2, 32, 6));
    assert.deepEqual([second.canvasWidth, second.canvasHeight], [36, 48]);
  });
  test('.5는 올린다', () => {
    // 공통 폭 10. 100×25 → 2.5 → 3, 100×35 → 3.5 → 4
    assert.equal(planPngOriginal([size(100, 25), size(10, 10)], { padding: 0 }).placements[0].height, 3);
    assert.equal(planPngOriginal([size(100, 35), size(10, 10)], { padding: 0 }).placements[0].height, 4);
  });
  test('아주 납작해도 1px은 남는다', () => {
    // 공통 폭 10, 9000×1 → 0.0011 → 1. 가로형이 많아야 세로 배치다.
    const plan = planPngOriginal([size(9000, 1), size(10, 10)], { padding: 0 });
    assert.equal(plan.placements[0].height, 1);
  });
  test('공통 변은 내림이다: 기준값인 최솟값을 넘겨 키우지 않는다', () => {
    // 6001×8000은 4000px 제한으로 3000.5×4000이다. 8000×1000 두 장은 4000×500.
    // 비율 0.75, 8, 8이라 세로 배치, 공통 폭은 최솟값 3000.5 → 3000 (반올림이면 3001이 된다)
    // 장당 4000, 500 × 3000.5/4000 = 375.06 → 375
    const plan = planPngOriginal([size(6001, 8000), size(8000, 1000), size(8000, 1000)], { padding: 0 });
    assert.deepEqual(plan.placements.map((p) => [p.width, p.height]), [[3000, 4000], [3000, 375], [3000, 375]]);
  });
  test('Flutter와 맞춘 값: 사진 10장은 두 번 줄여 1757×13625', () => {
    const plan = planPngOriginal(Array(10).fill(size(4000, 3000)));
    assert.deepEqual([plan.canvasWidth, plan.canvasHeight], [1757, 13625]);
  });
  test('용지의 페이지 크기는 그대로 내림이다', () => {
    // A4 3쪽: floor(2375.92) = 2375, floor(3360.78) = 3360
    const plan = planPng(Array(3).fill(photo), a4());
    assert.deepEqual([plan.pageWidth, plan.pageHeight], [2375, 3360]);
  });
});

describe('다시 인코딩한 뒤의 구분선', () => {
  const plan = {
    canvasWidth: 1000,
    canvasHeight: 2000,
    dividerThickness: 8,
    dividers: [rect(0, 996, 1000, 8), rect(496, 0, 8, 996)],
  };
  test('절반으로 줄이면 두께도 절반이고 가운데를 유지한다', () => {
    // 두께 4. 가로줄 가운데 (996 + 4) × 0.5 = 500 → y = 498. 세로줄 가운데 (496 + 4) × 0.5 = 250 → x = 248
    assert.deepEqual(scaleDividers(plan, 500, 1000), [rect(0, 498, 500, 4), rect(248, 0, 4, 498)]);
  });
  test('두께는 2px 아래로 내려가지 않는다', () => {
    // 8 × 0.1 = 0.8 → 2. 가로줄 가운데 100 → y = 99
    const scaled = scaleDividers(plan, 100, 200);
    assert.ok(scaled.every((d) => Math.min(d.width, d.height) === 2));
    assert.equal(scaled[0].y, 99);
  });
});

describe('PDF 계획', () => {
  // A4 = 595.2756 × 841.8898pt, 여백 × 5% = 29.7638pt, 간격 × 4% = 23.811pt. 여백 안쪽 535.748 × 782.3622pt.
  test('N=1, F=100%: 이미지 하나당 한 페이지, 여백 안쪽에 꽉 차게', () => {
    // 배율 535.748/4000. 높이 3000 × 배율 = 401.811. y = (841.8898 − 401.811)/2 = 220.0394
    const pages = planPdf([size(4000, 3000), size(4000, 3000)], a4());
    assert.equal(pages.length, 2);
    assert.equal(pages[0].images.length, 1);
    close(pages[0].pageWidthPt, 595.2756);
    close(pages[0].pageHeightPt, 841.8898);
    close(pages[0].images[0].widthPt, 535.748);
    close(pages[0].images[0].heightPt, 401.811);
    close(pages[0].images[0].xPt, 29.7638);
    close(pages[0].images[0].yPt, 220.0394);
    assert.equal(pages[1].images[0].index, 1);
  });
  test('N=2, F=50%, 3장: 2페이지, 첫 칸이 위쪽', () => {
    // 칸 높이 (782.3622 − 23.811)/2 = 379.2756. 정사각형 → 379.2756 × 0.5 = 189.6378
    // x = (595.2756 − 189.6378)/2 = 202.8189
    // 위 칸 위에서 y = 29.7638 + 94.8189 = 124.5827 → PDF y = 841.8898 − 124.5827 − 189.6378 = 527.6693
    // 아래 칸 위에서 y = 29.7638 + 379.2756 + 23.811 + 94.8189 = 527.6693 → PDF y = 124.5827
    const pages = planPdf(Array(3).fill(square), a4({ perSheet: 2, imageSize: 50 }));
    assert.equal(pages.length, 2);
    assert.deepEqual(pages.map((page) => page.images.map((image) => image.index)), [[0, 1], [2]]);
    const [top, bottom] = pages[0].images;
    close(top.widthPt, 189.6378);
    close(top.heightPt, 189.6378);
    close(top.xPt, 202.8189);
    close(top.yPt, 527.6693);
    close(bottom.xPt, 202.8189);
    close(bottom.yPt, 124.5827);
  });
  test('A4 가로, N=4, F=30%: 칸마다 가운데', () => {
    // 칸 (841.8898 − 59.5276 − 23.811)/2 = 379.2756 × (595.2756 − 59.5276 − 23.811)/2 = 255.9685
    // 정사각형 → 255.9685 × 0.3 = 76.7906
    // 첫 칸 x = 29.7638 + (379.2756 − 76.7906)/2 = 181.0063, 위에서 y = 29.7638 + (255.9685 − 76.7906)/2 = 119.3528
    //   PDF y = 595.2756 − 119.3528 − 76.7906 = 399.1323
    // 넷째 칸 x = 29.7638 + 379.2756 + 23.811 + 151.2425 = 584.0929, PDF y = 119.3528
    const [page] = planPdf(Array(4).fill(square), a4Landscape({ perSheet: 4, imageSize: 30 }));
    close(page.pageWidthPt, 841.8898);
    close(page.pageHeightPt, 595.2756);
    assert.equal(page.images.length, 4);
    close(page.images[0].widthPt, 76.7906);
    close(page.images[0].xPt, 181.0063);
    close(page.images[0].yPt, 399.1323);
    close(page.images[3].xPt, 584.0929);
    close(page.images[3].yPt, 119.3528);
  });
  test('PNG 페이지와 같은 기하다: 페이지에 대한 비율이 같다', () => {
    // PNG는 2480×3508에 x = 647.35, 폭 1185.3, 위 124, 높이 1580.4 ('PNG 용지 계획'의 N=2 계산)
    // 그 비율: 0.26103, 0.47794, 0.03535, 0.45051
    // 2480×3508은 210×297mm를 픽셀로 반올림한 값이라 비율이 소수 넷째 자리에서 조금 다르다.
    const [page] = planPdf([photo, photo], a4({ perSheet: 2 }));
    const [image] = page.images;
    close(image.xPt / page.pageWidthPt, 647.35 / 2480, 1e-3);
    close(image.widthPt / page.pageWidthPt, 1185.3 / 2480, 1e-3);
    close(image.heightPt / page.pageHeightPt, 1580.4 / 3508, 1e-3);
    close((page.pageHeightPt - image.yPt - image.heightPt) / page.pageHeightPt, 124 / 3508, 1e-3);
  });
  // 정사각형 N=2. 칸 높이 = (841.8898 − 여백×2 − 간격)/2, 크기는 칸 높이와 같다 (폭 쪽이 넉넉하다).
  const squares = [
    [0, 420.9449, 87.1654, 420.9449, 0], // 여백 0, 간격 0: 위아래 칸이 맞닿는다
    [3, 395.9433, 99.6661, 428.0882, 17.8583], // 여백 17.8583, 간격 14.2866
    [5, 379.2756, 108, 432.8504, 29.7638], // 여백 29.7638, 간격 23.811
    [10, 337.6063, 128.8346, 444.7559, 59.5276], // 여백 59.5276, 간격 47.622
  ];
  for (const [padding, side, x, topY, bottomY] of squares) {
    test(`P=${padding}%, N=2: 크기 ${side}, 위 칸 y ${topY}, 아래 칸 y ${bottomY}`, () => {
      const [page] = planPdf([square, square], a4({ perSheet: 2, padding }));
      const [top, bottom] = page.images;
      close(top.widthPt, side);
      close(top.heightPt, side);
      close(top.xPt, x);
      close(top.yPt, topY);
      close(bottom.xPt, x);
      close(bottom.yPt, bottomY);
    });
  }
  test('P=0%: 칸이 맞닿고 페이지 끝까지 쓴다', () => {
    const [page] = planPdf([square, square], a4({ perSheet: 2, padding: 0 }));
    const [top, bottom] = page.images;
    close(bottom.yPt + bottom.heightPt, top.yPt); // 아래 칸 위쪽이 위 칸 아래쪽이다
    close(bottom.yPt, 0);
    close(top.yPt + top.heightPt, page.pageHeightPt);
  });
  // '원본 크기' 1000×2000. 여백 = 1000 × P%, 합 (1000 + 여백×2)×(2000 + 여백×2), 배율 = 841.8898 ÷ 긴 변
  const tall = [
    [0, 420.9449, 420.9449, 841.8898, 0],
    [3, 433.2054, 408.6844, 817.3687, 12.2605], // 여백 30, 합 1060×2060
    [5, 440.9899, 400.8999, 801.7998, 20.045], // 여백 50, 합 1100×2100
    [10, 459.2126, 382.6772, 765.3543, 38.2677], // 여백 100, 합 1200×2200
  ];
  for (const [padding, pageWidth, width, height, at] of tall) {
    test(`'원본 크기' P=${padding}%: 페이지 폭 ${pageWidth}, 이미지 ${width}×${height}, 자리 ${at}`, () => {
      const [page] = planPdf([size(1000, 2000)], { paper: 'original', orientation: 'portrait', padding });
      close(page.pageWidthPt, pageWidth);
      close(page.pageHeightPt, 841.8898);
      close(page.images[0].widthPt, width);
      close(page.images[0].heightPt, height);
      close(page.images[0].xPt, at);
      close(page.images[0].yPt, at);
    });
  }
  test("'원본 크기' P=0%: 페이지 비율이 이미지 비율과 같다", () => {
    // 4000×3000 → 841.8898 × 3/4 = 631.4173
    const [page] = planPdf([size(4000, 3000)], { paper: 'original', orientation: 'portrait', padding: 0 });
    close(page.pageWidthPt, 841.8898);
    close(page.pageHeightPt, 631.4173);
    close(page.pageWidthPt / page.pageHeightPt, 4000 / 3000, 1e-9);
  });
  test('N과 페이지 수: 칸 수만큼 묶는다', () => {
    const count = (perSheet) => planPdf(Array(30).fill(square), a4({ perSheet })).length;
    assert.deepEqual(PER_SHEET_OPTIONS.map(count), [30, 15, 10, 8, 5, 4, 4]);
  });
  test("'원본 크기' 1000×2000: 이미지 짧은 변의 5%를 네 변에, 긴 변은 297mm", () => {
    // 여백 50, 합한 크기 1100×2100, 긴 변 841.8898pt → 배율 841.8898/2100 = 0.4008999
    // 페이지 1100 × 배율 = 440.9899 × 841.8898, 이미지 400.8999×801.7998, 자리 50 × 배율 = 20.045
    const [page] = planPdf([size(1000, 2000)], { paper: 'original', orientation: 'portrait' });
    close(page.pageWidthPt, 440.9899);
    close(page.pageHeightPt, 841.8898);
    close(page.images[0].widthPt, 400.8999);
    close(page.images[0].heightPt, 801.7998);
    close(page.images[0].xPt, 20.045);
    close(page.images[0].yPt, 20.045);
  });
  test("'원본 크기' 가로형과 정사각형", () => {
    // 4000×3000: 여백 150, 합 4300×3300, 배율 841.8898/4300 = 0.1957883
    //   페이지 841.8898×646.1014, 이미지 783.1533×587.365, 자리 29.3682
    // 500×500: 여백 25, 합 550×550, 배율 1.5307087. 작은 이미지도 긴 변을 297mm로 맞춘다.
    //   페이지 841.8898×841.8898, 이미지 765.3543, 자리 38.2677
    const [wide, even] = planPdf([size(4000, 3000), size(500, 500)], { paper: 'original', orientation: 'portrait' });
    close(wide.pageWidthPt, 841.8898);
    close(wide.pageHeightPt, 646.1014);
    close(wide.images[0].widthPt, 783.1533);
    close(wide.images[0].heightPt, 587.365);
    close(wide.images[0].xPt, 29.3682);
    close(wide.images[0].yPt, 29.3682);
    close(even.pageWidthPt, 841.8898);
    close(even.pageHeightPt, 841.8898);
    close(even.images[0].widthPt, 765.3543);
    close(even.images[0].xPt, 38.2677);
  });
  test("'원본 크기': 네 변의 여백이 같고 N과 F를 쓰지 않는다", () => {
    // 1080×2340: 여백 54, 합 1188×2448, 배율 841.8898/2448 = 0.3439092. 페이지 408.5642×841.8898, 이미지 371.422×804.7476, 자리 18.5711
    const pages = planPdf([shot, shot], { paper: 'original', orientation: 'portrait', perSheet: 4, imageSize: 30 });
    assert.equal(pages.length, 2);
    const [page] = pages;
    close(page.pageWidthPt, 408.5642);
    close(page.images[0].widthPt, 371.422);
    close(page.images[0].heightPt, 804.7476);
    const { xPt, yPt, widthPt, heightPt } = page.images[0];
    close(page.pageWidthPt - xPt - widthPt, xPt);
    close(page.pageHeightPt - yPt - heightPt, yPt);
    close(xPt, 18.5711);
  });
  test('계획에 구분선이 없다. 구분선은 PNG에만 있다', () => {
    for (const settings of [a4({ perSheet: 4 }), { paper: 'original', orientation: 'portrait' }]) {
      for (const page of planPdf(Array(4).fill(square), settings)) {
        assert.deepEqual(Object.keys(page).sort(), ['images', 'pageHeightPt', 'pageWidthPt']);
      }
    }
  });
  test('예산은 페이지가 아니라 이미지마다: 0.95 × 20,000,000 ÷ 장수 (내림)', () => {
    assert.equal(pdfImageBudget(10), 1900000);
    assert.equal(pdfImageBudget(30), 633333);
    assert.throws(() => pdfImageBudget(0), RangeError);
  });
});
