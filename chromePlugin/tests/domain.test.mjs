// 기대값은 코드가 아니라 손으로 계산했다. 계산 과정을 주석에 남긴다.
import assert from 'node:assert/strict';
import { describe, test } from 'node:test';

import { dragCrop, croppedSize, decodeSizeForTarget, FULL_CROP, isFullCrop } from '../js/domain/crop_rect.js';
import { fileStamp, uniqueFileName } from '../js/domain/file_naming.js';
import { MergeError } from '../js/domain/errors.js';
import { formatBytes, formatDateTime } from '../js/domain/format.js';
import { addSession, markRunningAsCrashed, successRate, updateSession } from '../js/domain/history_model.js';
import { JobPhase, losesWorkOnLeave } from '../js/domain/job_phase.js';
import { decideDirection, LayoutDirection } from '../js/domain/layout_direction.js';
import { mmToPoints, paperCanvas, paperSizeMm, PAPERS } from '../js/domain/paper.js';
import { capLongSide, pdfJpegAttempts } from '../js/domain/pdf_plan.js';
import { nextPngFactor, planPng, planPngOriginal } from '../js/domain/png_plan.js';
import { sniffKind } from '../js/domain/sniff.js';
import { setTranslator } from '../js/ui/i18n.js';
import { directionText, errorMessage, paperLabel } from '../js/ui/labels.js';
import { translatorFor } from './i18n_helper.mjs';

// 문구는 _locales로 옮겼다. 한국어 번역기로 같은 문장을 확인한다.
setTranslator(translatorFor('ko'));

const size = (width, height) => ({ width, height });
const shot = size(1080, 2340);
const close = (actual, expected, tolerance = 0.01) =>
  assert.ok(Math.abs(actual - expected) <= tolerance, `${actual} is not within ${tolerance} of ${expected}`);
const original = { paper: 'original', orientation: 'portrait', grayscale: false };

describe('decideDirection', () => {
  test('세로형 스크린샷 3장은 가로 배치', () => {
    assert.equal(decideDirection([shot, shot, shot]), LayoutDirection.horizontal);
  });
  test('가로형 사진 3장은 세로 배치', () => {
    const photo = size(4000, 3000);
    assert.equal(decideDirection([photo, photo, photo]), LayoutDirection.vertical);
  });
  test('2:1과 1:2는 기하 평균이 정확히 1이라 세로 배치', () => {
    assert.equal(decideDirection([size(200, 100), size(100, 200)]), LayoutDirection.vertical);
  });
  test('산술 평균 1.33이어도 기하 평균 0.91이면 가로 배치', () => {
    // 비율 3, 0.5, 0.5: 산술 평균 4/3, 기하 평균 (3 × 0.25)^(1/3) ≈ 0.91
    assert.equal(decideDirection([size(300, 100), size(100, 200), size(100, 200)]), LayoutDirection.horizontal);
  });
  test('역수 쌍은 부동소수점 오차가 있어도 세로 배치', () => {
    assert.equal(decideDirection([size(3, 7), size(7, 3), size(10, 3), size(3, 10)]), LayoutDirection.vertical);
  });
  test('빈 목록은 오류', () => {
    assert.throws(() => decideDirection([]), RangeError);
  });
  test('안내 문구', () => {
    assert.equal(directionText(LayoutDirection.horizontal), '자동: 가로 배치 (왼쪽 → 오른쪽)');
    assert.equal(directionText(LayoutDirection.vertical), '자동: 세로 배치 (위 → 아래)');
  });
});

describe('용지', () => {
  // 픽셀 = mm ÷ 25.4 × 300, 반올림
  const cases = [
    ['a4', 'portrait', 2480, 3508], // 210→2480.31, 297→3507.87
    ['a4', 'landscape', 3508, 2480],
    ['a3', 'portrait', 3508, 4961], // 297→3507.87, 420→4960.63
    ['a5', 'portrait', 1748, 2480], // 148→1748.03, 210→2480.31
    ['b4', 'portrait', 3035, 4299], // JIS 257→3035.43, 364→4299.21
    ['b5', 'portrait', 2150, 3035], // JIS 182→2149.61, 257→3035.43
    ['letter', 'portrait', 2550, 3300], // 8.5in, 11in
    ['legal', 'portrait', 2550, 4200], // 8.5in, 14in
  ];
  for (const [paper, orientation, width, height] of cases) {
    test(`${paper} ${orientation} 300DPI = ${width}×${height}`, () => {
      assert.deepEqual(paperCanvas(paperSizeMm({ paper, orientation })), { width, height });
    });
  }
  test("'원본 크기'는 용지가 없다", () => {
    assert.equal(paperSizeMm(original), null);
  });
  test('목록은 A4가 맨 앞이고 원본 크기가 맨 뒤다', () => {
    assert.deepEqual(PAPERS.map((p) => paperLabel(p.code)), ['A4', 'A3', 'A5', 'B4', 'B5', 'Letter', 'Legal', '원본 크기']);
  });
  test('포인트: A4는 595.28×841.89, Letter는 612×792', () => {
    close(mmToPoints(210), 595.28);
    close(mmToPoints(297), 841.89);
    close(mmToPoints(215.9), 612);
    close(mmToPoints(279.4), 792);
  });
  test('캔버스 상한을 넘으면 같은 비율로 줄인다', () => {
    // 1000×1000mm@100DPI = 3937×3937 ≈ 1550만. 상한 100만이면 g = √(100만/1550만) → 1000×1000
    const canvas = paperCanvas({ widthMm: 1000, heightMm: 1000 }, { dpi: 100, maxPixels: 1000000 });
    assert.deepEqual(canvas, { width: 1000, height: 1000 });
  });
  test('알 수 없는 용지는 오류', () => {
    assert.throws(() => paperSizeMm({ paper: 'x', orientation: 'portrait' }), RangeError);
  });
});

describe('planPngOriginal', () => {
  test('스크린샷 3장: 옆으로 이어 붙이고 여백과 구분선을 넣는다', () => {
    // 공통 변 2340: 여백 117, 두께 round(7.02) = 7. 폭 = (117+1080+117)×3 + 7×2 = 3956, 높이 2574
    const plan = planPng([shot, shot, shot], original);
    assert.equal(plan.onPaper, false);
    assert.equal(plan.canvasWidth, 3956);
    assert.equal(plan.canvasHeight, 2574);
    assert.deepEqual(plan.placements.map((p) => p.x), [117, 1438, 2759]);
    assert.ok(plan.placements.every((p) => p.y === 117 && p.width === 1080 && p.height === 2340));
  });
  test('세로 배치는 폭을 가장 좁은 이미지에 맞춘다 (확대 안 함)', () => {
    // 공통 변 2000: 여백 100, 두께 6. 높이 (100+1500+100)×2 + 6 = 3406
    const plan = planPngOriginal([size(4000, 3000), size(2000, 1500)]);
    assert.equal(plan.canvasWidth, 2200);
    assert.equal(plan.canvasHeight, 3406);
    assert.equal(plan.placements[0].width, 2000);
    assert.equal(plan.placements[0].height, 1500);
    assert.equal(plan.placements[1].y, 1806);
  });
  test('여백·구분선까지 정확히 2,400만 픽셀이면 더 줄이지 않는다', () => {
    // 공통 변 3636: 여백 round(181.8) = 182, 두께 round(10.908) = 11. 폭 3636 + 364 = 4000
    // 높이 (182+2630+182) + 11 + (182+2631+182) = 2994 + 11 + 2995 = 6000. 4000 × 6000 = 24,000,000
    const plan = planPngOriginal([size(3636, 2630), size(3636, 2631)]);
    assert.equal(plan.canvasWidth, 4000);
    assert.equal(plan.canvasHeight, 6000);
    assert.equal(plan.placements[0].width, 3636);
  });
  test('1줄만 넘어도 줄인다. 여백·구분선도 상한에 들어간다', () => {
    // 4000 × 6001 = 24,004,000 → g = √(24000000/24004000) = 0.999917
    // 공통 변 floor(3635.70) = 3635, 장당 round(2629.78) = 2630, round(2631.78) = 2632, 여백 round(181.75) = 182, 두께 round(10.905) = 11
    // 폭 3635 + 364 = 3999, 높이 364×2 + 2630 + 2632 + 11 = 6001. 3999 × 6001 = 23,997,999
    const plan = planPngOriginal([size(3636, 2630), size(3636, 2632)]);
    assert.equal(plan.canvasWidth, 3999);
    assert.equal(plan.canvasHeight, 6001);
  });
  test('긴 변 4000px 초과 입력은 먼저 줄인다', () => {
    // 8000×6000 → 4000×3000. 여백 200, 두께 12. 4400 × ((200+3000+200)×2 + 12 = 6812) = 29,972,800 → g = 0.894833
    // 공통 변 floor(3579.33) = 3579, 장당 round(2684.499) = 2684, 여백 round(178.95) = 179, 두께 round(10.737) = 11
    // 폭 3579 + 358 = 3937, 높이 (358 + 2684)×2 + 11 = 6095. 23,996,015
    const plan = planPngOriginal([size(8000, 6000), size(4000, 3000)]);
    assert.equal(plan.canvasWidth, 3937);
    assert.equal(plan.canvasHeight, 6095);
    assert.ok(plan.canvasWidth * plan.canvasHeight <= 24000000);
  });
  test('캔버스가 2,400만 픽셀을 넘으면 전체를 같은 비율로 줄인다', () => {
    // 4400 × (3400×10 + 12×9 = 34108) = 150,075,200 → g = 0.3999
    // 공통 변 floor(1599.6) = 1599, 장당 round(1199.7) = 1200, 여백 80, 두께 5 → 폭 1759, 높이 (160 + 1200)×10 + 45 = 13645. 24,001,555라 아직 넘는다
    // 한 번 더: g × √(24000000/24001555) × 0.999 = 0.399487
    // 공통 변 floor(1597.95) = 1597, 장당 round(1198.46) = 1198, 여백 round(79.85) = 80, 두께 round(4.791) = 5
    // 폭 1597 + 160 = 1757, 높이 (160 + 1198)×10 + 45 = 13625. 23,939,125
    const plan = planPngOriginal(Array(10).fill(size(4000, 3000)));
    assert.equal(plan.canvasWidth, 1757);
    assert.equal(plan.canvasHeight, 13625);
    assert.ok(plan.canvasWidth * plan.canvasHeight <= 24000000);
  });
});

describe('nextPngFactor', () => {
  test('√(상한 ÷ 크기) × 0.9, 누적', () => {
    close(nextPngFactor(1, 80000000, 20000000), 0.45, 1e-9); // √0.25 × 0.9
    close(nextPngFactor(0.45, 80000000, 20000000), 0.2025, 1e-9);
  });
});

describe('PDF 다시 인코딩', () => {
  test('다시 인코딩 순서: 품질 85 → 70 → 긴 변 75%씩 3번', () => {
    const attempts = pdfJpegAttempts(size(8000, 6000)).map((a) => `${a.width}x${a.height} q${a.quality}`);
    assert.deepEqual(attempts, ['4000x3000 q85', '4000x3000 q70', '3000x2250 q70', '2250x1688 q70', '1688x1266 q70']);
  });
  test('작은 이미지는 원래 크기에서 시작', () => {
    assert.deepEqual(pdfJpegAttempts(size(800, 600))[0], { width: 800, height: 600, quality: 85 });
  });
  test('capLongSide', () => {
    assert.deepEqual(capLongSide(size(8000, 6000), 4000), size(4000, 3000));
    assert.deepEqual(capLongSide(size(1000, 2000), 512), size(256, 512));
    assert.deepEqual(capLongSide(size(10, 10), 512), size(10, 10));
  });
});

describe('영역', () => {
  const half = { left: 0, top: 0, right: 0.5, bottom: 0.5 };

  test('영역 크기', () => {
    assert.deepEqual(croppedSize(1000, 500, { left: 0.1, top: 0.2, right: 0.6, bottom: 0.8 }), size(500, 300));
    assert.deepEqual(croppedSize(1000, 500, null), size(1000, 500));
  });
  test('전체 판정', () => {
    assert.equal(isFullCrop(null), true);
    assert.equal(isFullCrop(FULL_CROP), true);
    assert.equal(isFullCrop(half), false);
  });
  test('모서리를 끌면 두 변이 움직이고 0~1을 넘지 않는다', () => {
    assert.deepEqual(dragCrop(half, 'se', 0.8, 0.1), { left: 0, top: 0, right: 1, bottom: 0.6 });
    assert.deepEqual(dragCrop({ left: 0.5, top: 0.5, right: 1, bottom: 1 }, 'nw', -0.9, -0.1), { left: 0, top: 0.4, right: 1, bottom: 1 });
  });
  test('변을 끌면 그 변만 움직인다', () => {
    assert.deepEqual(dragCrop(half, 'e', 0.1, 0.9), { left: 0, top: 0, right: 0.6, bottom: 0.5 });
    assert.deepEqual(dragCrop(half, 's', 0.9, 0.1), { left: 0, top: 0, right: 0.5, bottom: 0.6 });
  });
  test('2%보다 작아지지 않는다', () => {
    assert.deepEqual(dragCrop(half, 'e', -0.9, 0), { left: 0, top: 0, right: 0.02, bottom: 0.5 });
    assert.deepEqual(dragCrop(half, 's', 0, -0.9), { left: 0, top: 0, right: 0.5, bottom: 0.02 });
    assert.deepEqual(dragCrop({ left: 0.2, top: 0, right: 0.5, bottom: 1 }, 'w', 0.9, 0), { left: 0.48, top: 0, right: 0.5, bottom: 1 });
  });
  test('옮기기는 크기를 유지하고 경계에서 멈춘다', () => {
    assert.deepEqual(dragCrop(half, 'move', 0.2, 0.1), { left: 0.2, top: 0.1, right: 0.7, bottom: 0.6 });
    assert.deepEqual(dragCrop(half, 'move', 0.9, 0.9), { left: 0.5, top: 0.5, right: 1, bottom: 1 });
    assert.deepEqual(dragCrop(half, 'move', -0.9, -0.9), half);
  });
  test('디코딩 크기: 영역이 있으면 전체를 그만큼 크게 받는다', () => {
    // 영역이 폭·높이의 절반이고 목표가 500×300이면 전체는 1000×600
    assert.deepEqual(decodeSizeForTarget(500, 300, half, 4000, 3000), size(1000, 600));
    assert.deepEqual(decodeSizeForTarget(2000, 1500, null, 4000, 3000), size(2000, 1500));
  });
  test('디코딩 크기: 칸이 커도 영역 긴 변은 4000px까지만 받는다', () => {
    // A3 가로 칸 4961×3721에 8000×6000: 4000/4961을 곱하면 4000×3000.2 → 올림 4000×3001
    assert.deepEqual(decodeSizeForTarget(4961, 3721, null, 8000, 6000), size(4000, 3001));
    // 영역이 절반이면 전체를 두 배로 받아 영역이 4000px가 되게 한다
    assert.deepEqual(decodeSizeForTarget(4000, 2000, half, 10000, 5000), size(8000, 4000));
  });
  test('디코딩 크기: 원본보다 크면 줄이지 않는다', () => {
    assert.equal(decodeSizeForTarget(4000, 3000, null, 4000, 3000), null);
    assert.equal(decodeSizeForTarget(3000, 3000, half, 4000, 3000), null); // 전체 6000×6000 필요
  });
});

describe('탭을 떠날 때 확인', () => {
  // 공유 창이 열려 있는 finished에서 참이면 '메일 작성'의 mailto:와 새로 고침이 확인 창을 띄운다.
  const expected = { idle: false, preparing: false, merging: true, finished: false };
  test('단계 목록이 빠짐없다', () => {
    assert.deepEqual(Object.keys(JobPhase).sort(), Object.keys(expected).sort());
  });
  for (const [phase, answer] of Object.entries(expected)) {
    test(`${phase}: ${answer}`, () => assert.equal(losesWorkOnLeave(JobPhase[phase]), answer));
  }
});

describe('파일 이름', () => {
  const time = new Date(2026, 9, 30, 15, 36);
  test('YYYYMMDDHHMI: 자릿수를 채우고 24시간제다', () => {
    assert.equal(fileStamp(time), '202610301536');
    assert.equal(fileStamp(new Date(2026, 0, 5, 9, 7)), '202601050907');
    assert.equal(fileStamp(new Date(2026, 11, 31, 23, 59)), '202612312359');
    assert.equal(fileStamp(new Date(2027, 0, 1, 0, 0)), '202701010000');
  });
  test('설계서의 예: 첫 파일은 _1, 같은 분에 또 저장하면 _2', () => {
    assert.equal(uniqueFileName(time, 'png', []), '202610301536_1.png');
    assert.equal(uniqueFileName(time, 'png', ['202610301536_1.png']), '202610301536_2.png');
  });
  test('비어 있는 가장 작은 연번을 쓴다', () => {
    assert.equal(uniqueFileName(time, 'png', ['202610301536_2.png']), '202610301536_1.png');
    assert.equal(uniqueFileName(time, 'png', ['202610301536_1.png', '202610301536_3.png']), '202610301536_2.png');
    assert.equal(uniqueFileName(time, 'png', ['202610301536_3.png', '202610301536_2.png', '202610301536_1.png']), '202610301536_4.png');
  });
  test('자릿수를 채우지 않는다: 9 다음은 10', () => {
    const used = Array.from({ length: 9 }, (_, i) => `202610301536_${i + 1}.png`);
    assert.equal(uniqueFileName(time, 'png', used), '202610301536_10.png');
  });
  test('확장자가 다르면 연번을 따로 센다', () => {
    assert.equal(uniqueFileName(time, 'pdf', ['202610301536_1.png']), '202610301536_1.pdf');
    assert.equal(uniqueFileName(time, 'png', ['202610301536_1.pdf']), '202610301536_1.png');
  });
  test('다른 분의 파일과 다른 이름은 세지 않는다', () => {
    assert.equal(uniqueFileName(time, 'png', ['202610301535_1.png', '202610301537_1.png', 'photo.png', '202610301536_1 (1).png']), '202610301536_1.png');
  });
  test('대소문자만 다른 이름은 같은 파일이다', () => {
    assert.equal(uniqueFileName(time, 'png', ['202610301536_1.PNG']), '202610301536_2.png');
  });
  test('Set도 받는다', () => {
    assert.equal(uniqueFileName(time, 'png', new Set(['202610301536_1.png'])), '202610301536_2.png');
  });
  test('이름에 장수가 들어가지 않는다', () => {
    assert.doesNotMatch(uniqueFileName(time, 'png', []), /images/);
  });
});

describe('오류 문구', () => {
  test('번호가 있으면 몇 번째인지 말한다', () => {
    assert.equal(errorMessage('corrupt_file', 3), '3번째 이미지 파일이 손상되었습니다.');
    assert.equal(errorMessage('unsupported_format', 3), '3번째 이미지는 지원하지 않는 형식입니다.');
    assert.equal(errorMessage('source_unavailable', 3), '3번째 이미지를 열 수 없습니다. 다시 선택해 주세요.');
  });
  test('번호가 없는 코드', () => {
    assert.equal(errorMessage('output_too_large'), '결과 파일이 너무 큽니다. 이미지 수를 줄여 주세요.');
    assert.equal(errorMessage('out_of_memory'), '메모리가 부족합니다. 이미지 수를 줄여 주세요.');
    assert.equal(errorMessage('no_such_code'), '알 수 없는 오류가 발생했습니다.');
  });
  test('MergeError는 코드와 번호를 들고 있다', () => {
    const error = new MergeError('corrupt_file', { imageNumber: 2 });
    assert.equal(error.code, 'corrupt_file');
    assert.equal(errorMessage(error.code, error.imageNumber), '2번째 이미지 파일이 손상되었습니다.');
  });
});

describe('형식 판별', () => {
  const bytes = (...values) => new Uint8Array(values);
  const text = (value) => new TextEncoder().encode(value);

  test('JPEG, PNG, WebP, PDF', () => {
    assert.equal(sniffKind(bytes(0xff, 0xd8, 0xff, 0xe0)), 'jpeg');
    assert.equal(sniffKind(bytes(0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a)), 'png');
    assert.equal(sniffKind(text('RIFF\0\0\0\0WEBPVP8 ')), 'webp');
    assert.equal(sniffKind(text('%PDF-1.7\n')), 'pdf');
  });
  test('PDF 머리글은 앞쪽 1024바이트 안이면 된다', () => {
    assert.equal(sniffKind(text(`${' '.repeat(100)}%PDF-1.4`)), 'pdf');
    assert.equal(sniffKind(text(`${' '.repeat(2000)}%PDF-1.4`)), null);
  });
  test('HEIC와 그 밖의 형식은 null', () => {
    assert.equal(sniffKind(text('\0\0\0\x18ftypheic')), null);
    assert.equal(sniffKind(text('GIF89a')), null);
    assert.equal(sniffKind(text('RIFF\0\0\0\0WAVEfmt ')), null);
    assert.equal(sniffKind(new Uint8Array(0)), null);
  });
});

describe('표시 형식', () => {
  test('바이트', () => {
    assert.equal(formatBytes(999), '999B');
    assert.equal(formatBytes(1500), '2KB');
    assert.equal(formatBytes(800000), '800KB');
    assert.equal(formatBytes(20000000), '20.0MB');
  });
  test('날짜', () => {
    assert.equal(formatDateTime(new Date(2026, 0, 5, 9, 7)), '2026-01-05 09:07');
  });
});

describe('기록', () => {
  const session = (id, status, startedAt = '2026-11-01T00:00:00.000Z') => ({ id, status, startedAt });

  test('최신이 앞이고 50건을 넘으면 오래된 것을 버린다', () => {
    let sessions = [];
    for (let id = 1; id <= 53; id++) sessions = addSession(sessions, session(id, 'success'));
    assert.equal(sessions.length, 50);
    assert.equal(sessions[0].id, 53);
    assert.equal(sessions.at(-1).id, 4);
  });
  test('결과 갱신은 해당 세션만 바꾼다', () => {
    const updated = updateSession([session(1, 'running'), session(2, 'running')], 2, { status: 'failed', errorCode: 'unknown' });
    assert.equal(updated[0].status, 'running');
    assert.deepEqual(updated[1], { ...session(2, 'failed'), errorCode: 'unknown' });
  });
  test('running은 crashed로 바뀌고 수를 돌려준다', () => {
    const { sessions, crashed } = markRunningAsCrashed([session(1, 'running'), session(2, 'success'), session(3, 'running')]);
    assert.equal(crashed, 2);
    assert.deepEqual(sessions.map((s) => s.status), ['crashed', 'success', 'crashed']);
  });
  test('성공률: 30일 안, running 제외, 비정상 종료·취소는 분모에 포함', () => {
    const now = new Date('2026-11-05T00:00:00.000Z');
    const rate = successRate(
      [
        session(1, 'success', '2026-11-04T00:00:00.000Z'),
        session(2, 'failed', '2026-11-03T00:00:00.000Z'),
        session(3, 'cancelled', '2026-10-10T00:00:00.000Z'),
        session(4, 'crashed', '2026-10-07T00:00:00.000Z'),
        session(5, 'running', '2026-11-04T00:00:00.000Z'),
        session(6, 'success', '2026-10-01T00:00:00.000Z'), // 35일 전이라 뺀다
      ],
      now,
    );
    assert.deepEqual(rate, { success: 1, total: 4, ratio: 0.25 });
  });
  test('기록이 없으면 ratio는 null', () => {
    assert.equal(successRate([], new Date()).ratio, null);
  });
});
