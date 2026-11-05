import { ErrorCode, MergeCancelled, MergeError } from '../domain/errors.js';
import { kDividerColor, kMaxOutputBytes, kPngMaxReencodes } from '../domain/limits.js';
import { pdfImageBudget, pdfJpegAttempts, planPdf } from '../domain/pdf_plan.js';
import { buildPdf } from '../domain/pdf_writer.js';
import { nextPngFactor, planPng, scaleDividers } from '../domain/png_plan.js';
import { canvasToBlob, createCanvas, releaseCanvas } from './canvas.js';
import { drawItem, itemSize } from './items.js';

/** 취소 신호. 장 사이와 인코딩 전후에 확인한다 (DESIGN §5.2). */
export class CancelToken {
  cancelled = false;

  cancel() {
    this.cancelled = true;
  }

  throwIfCancelled() {
    if (this.cancelled) throw new MergeCancelled();
  }
}

/** 이미지 사이에서 화면이 다시 그려질 틈을 준다. */
const yieldToUi = () => new Promise((resolve) => setTimeout(resolve, 0));

/** 처리 중 예기치 못한 오류를 §3.4 코드로 바꾼다. */
function toMergeError(error, imageNumber) {
  if (error instanceof MergeError || error instanceof MergeCancelled) return error;
  const message = String(error?.message ?? error);
  const code = error instanceof RangeError || /memory|allocat/i.test(message) ? ErrorCode.outOfMemory : ErrorCode.unknown;
  return new MergeError(code, { imageNumber, detail: message });
}

/** 구분선은 흑백을 골라도 색이 같다 (DESIGN §2.1.2). */
function fillDividers(ctx, dividers) {
  ctx.fillStyle = kDividerColor;
  for (const { x, y, width, height } of dividers) ctx.fillRect(x, y, width, height);
}

/** 인코딩 결과가 상한을 넘으면 줄여 다시 인코딩한다. 그래도 넘으면 output_too_large (DESIGN §2.1.2). */
async function encodePng(canvas, plan, token, { maxBytes = kMaxOutputBytes, maxReencodes = kPngMaxReencodes } = {}) {
  let blob = await canvasToBlob(canvas, 'image/png');
  token.throwIfCancelled();
  let width = canvas.width;
  let height = canvas.height;
  let factor = 1;
  for (let i = 0; blob.size > maxBytes && i < maxReencodes; i++) {
    factor = nextPngFactor(factor, blob.size, maxBytes);
    width = Math.max(1, Math.floor(canvas.width * factor));
    height = Math.max(1, Math.floor(canvas.height * factor));
    const smaller = createCanvas(width, height, { opaque: plan.onPaper });
    try {
      smaller.ctx.drawImage(canvas, 0, 0, width, height);
      fillDividers(smaller.ctx, scaleDividers(plan, width, height));
      blob = await canvasToBlob(smaller.canvas, 'image/png');
    } finally {
      releaseCanvas(smaller.canvas);
    }
    token.throwIfCancelled();
  }
  if (blob.size > maxBytes) {
    throw new MergeError(ErrorCode.outputTooLarge, { detail: `${blob.size} bytes` });
  }
  return { blob, width, height };
}

/**
 * 페이지 또는 이미지를 이어 붙이고 사이에 구분선을 넣어 PNG 한 장을 만든다 (DESIGN §2.1.2).
 * @returns {Promise<{blob:Blob,width:number,height:number,direction:string}>}
 */
export async function mergePng(items, settings, { token, onProgress }) {
  const plan = planPng(items.map(itemSize), settings);
  let imageNumber = null;
  let canvas = null;
  try {
    const created = createCanvas(plan.canvasWidth, plan.canvasHeight, { opaque: plan.onPaper });
    canvas = created.canvas;
    if (!plan.onPaper) {
      // '원본 크기'의 여백은 불투명한 흰색이고, 이미지 안의 투명 픽셀은 그대로 둔다 (DESIGN §2.1.2).
      created.ctx.fillStyle = '#ffffff';
      created.ctx.fillRect(0, 0, plan.canvasWidth, plan.canvasHeight);
    }
    for (let i = 0; i < items.length; i++) {
      token.throwIfCancelled();
      onProgress({ phase: 'images', completed: i, total: items.length });
      await yieldToUi();
      imageNumber = i + 1;
      const place = plan.placements[i];
      // 지우지 않으면 투명 픽셀이 위의 흰색과 합쳐진다.
      if (!plan.onPaper) created.ctx.clearRect(place.x, place.y, place.width, place.height);
      await drawItem(created.ctx, items[i], place.x, place.y, place.width, place.height, {
        grayscale: settings.grayscale,
        imageNumber,
      });
    }
    imageNumber = null;
    token.throwIfCancelled();
    fillDividers(created.ctx, plan.dividers);
    onProgress({ phase: 'images', completed: items.length, total: items.length });
    onProgress({ phase: 'building' });
    await yieldToUi();
    const encoded = await encodePng(canvas, plan, token);
    return { ...encoded, direction: plan.direction.code };
  } catch (error) {
    throw toMergeError(error, imageNumber);
  } finally {
    if (canvas) releaseCanvas(canvas);
  }
}

/** 한 장을 예산 안에 드는 JPEG로 만든다. 예산을 넘으면 품질 → 크기 순으로 다시 인코딩한다 (DESIGN §2.1.3). */
async function encodeImage(item, settings, budget, imageNumber, token) {
  for (const attempt of pdfJpegAttempts(itemSize(item))) {
    const { canvas, ctx } = createCanvas(attempt.width, attempt.height, { opaque: true });
    try {
      await drawItem(ctx, item, 0, 0, attempt.width, attempt.height, {
        grayscale: settings.grayscale,
        imageNumber,
      });
      token.throwIfCancelled();
      const blob = await canvasToBlob(canvas, 'image/jpeg', attempt.quality / 100);
      token.throwIfCancelled();
      if (blob.size <= budget) return { blob, attempt };
    } finally {
      releaseCanvas(canvas);
    }
  }
  throw new MergeError(ErrorCode.outputTooLarge, { imageNumber });
}

/**
 * 용지 한 장이 한 페이지인 PDF를 만든다. 구분선은 넣지 않는다 (DESIGN §2.1.3).
 * @returns {Promise<{blob:Blob}>}
 */
export async function mergePdf(items, settings, { token, onProgress }) {
  const budget = pdfImageBudget(items.length);
  const pages = [];
  let completed = 0;
  let imageNumber = null;
  try {
    for (const { pageWidthPt, pageHeightPt, images } of planPdf(items.map(itemSize), settings)) {
      const encoded = [];
      for (const { index, ...place } of images) {
        token.throwIfCancelled();
        onProgress({ phase: 'images', completed, total: items.length });
        await yieldToUi();
        imageNumber = index + 1;
        const { blob, attempt } = await encodeImage(items[index], settings, budget, imageNumber, token);
        encoded.push({
          jpeg: new Uint8Array(await blob.arrayBuffer()),
          pixelWidth: attempt.width,
          pixelHeight: attempt.height,
          ...place,
        });
        completed++;
      }
      pages.push({ pageWidthPt, pageHeightPt, images: encoded });
    }
    imageNumber = null;
    onProgress({ phase: 'images', completed: items.length, total: items.length });
    onProgress({ phase: 'building' });
    await yieldToUi();
    const bytes = buildPdf(pages);
    token.throwIfCancelled();
    if (bytes.length > kMaxOutputBytes) {
      throw new MergeError(ErrorCode.outputTooLarge, { detail: `${bytes.length} bytes` });
    }
    return { blob: new Blob([bytes], { type: 'application/pdf' }) };
  } catch (error) {
    throw toMergeError(error, imageNumber);
  }
}
