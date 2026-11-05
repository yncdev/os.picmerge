import { croppedSize, decodeSizeForTarget, FULL_CROP } from '../domain/crop_rect.js';
import { ErrorCode, MergeError } from '../domain/errors.js';
import {
  kCropPreviewLongSide,
  kCropPreviewQuality,
  kThumbnailLongSide,
  kThumbnailQuality,
} from '../domain/limits.js';
import { capLongSide } from '../domain/pdf_plan.js';
import { SNIFF_LENGTH, sniffKind } from '../domain/sniff.js';
import { canvasToBlob, createCanvas, releaseCanvas } from './canvas.js';

// 항목 하나: { id, blob, displayName, width, height, bytes, crop, thumbUrl }
// blob만 들고 있고 디코딩한 비트맵은 들고 있지 않는다. 저장할 때 한 장씩 디코딩한다 (DESIGN §3.1).
// width·height는 EXIF 반영 후 원본 크기다. 영역을 반영한 크기는 itemSize()로 얻는다.

let nextId = 1;

export function itemSize(item) {
  return croppedSize(item.width, item.height, item.crop);
}

/** @returns {Promise<'jpeg'|'png'|'webp'|'pdf'|null>} */
export async function sniffFile(file) {
  const head = await file.slice(0, SNIFF_LENGTH).arrayBuffer();
  return sniffKind(new Uint8Array(head));
}

async function thumbnailFrom(source, width, height) {
  const size = capLongSide({ width, height }, kThumbnailLongSide);
  const { canvas, ctx } = createCanvas(size.width, size.height, { opaque: true });
  try {
    ctx.drawImage(source, 0, 0, size.width, size.height);
    return await canvasToBlob(canvas, 'image/jpeg', kThumbnailQuality / 100);
  } finally {
    releaseCanvas(canvas);
  }
}

/** 이미지 파일을 항목으로 만든다. 디코딩할 수 없으면 예외를 던진다. */
export async function createImageItem(file) {
  const bitmap = await createImageBitmap(file, { imageOrientation: 'from-image' });
  try {
    const thumb = await thumbnailFrom(bitmap, bitmap.width, bitmap.height);
    return {
      id: nextId++,
      blob: file,
      displayName: file.name,
      width: bitmap.width,
      height: bitmap.height,
      bytes: file.size,
      crop: null,
      thumbUrl: URL.createObjectURL(thumb),
    };
  } finally {
    bitmap.close();
  }
}

/** 이미 이미지가 된 PDF 페이지를 항목으로 만든다. [canvas]는 렌더링 결과다. */
export async function createPageItem(jpeg, canvas, displayName) {
  const thumb = await thumbnailFrom(canvas, canvas.width, canvas.height);
  return {
    id: nextId++,
    blob: jpeg,
    displayName,
    width: canvas.width,
    height: canvas.height,
    bytes: jpeg.size,
    crop: null,
    thumbUrl: URL.createObjectURL(thumb),
  };
}

/** 목록에서 빠질 때 부른다. */
export function discardItem(item) {
  URL.revokeObjectURL(item.thumbUrl);
}

/**
 * 디코딩 실패의 원인을 §3.4 코드로 바꾼다. 파일을 고른 뒤 지우거나 바꾸면 읽기가 실패한다.
 */
async function classifyDecodeFailure(item, error, imageNumber) {
  if (error instanceof MergeError) return error;
  try {
    await item.blob.slice(0, 1).arrayBuffer();
  } catch (readError) {
    return new MergeError(ErrorCode.sourceUnavailable, { imageNumber, detail: readError.message });
  }
  const message = String(error?.message ?? error);
  if (/allocat|memory/i.test(message)) {
    return new MergeError(ErrorCode.outOfMemory, { imageNumber, detail: message });
  }
  if (error?.name === 'InvalidStateError') {
    return new MergeError(ErrorCode.corruptFile, { imageNumber, detail: message });
  }
  return new MergeError(ErrorCode.unknown, { imageNumber, detail: message });
}

/**
 * 항목의 영역을 ([x], [y]) 위치에 [width]×[height]로 그린다. 한 장 디코딩하고 바로 해제한다.
 * 큰 원본은 그릴 크기에 맞춰 줄여서 디코딩한다.
 */
export async function drawItem(ctx, item, x, y, width, height, { grayscale = false, imageNumber = null, crop = item.crop } = {}) {
  const decodeSize = decodeSizeForTarget(width, height, crop, item.width, item.height);
  const options = { imageOrientation: 'from-image' };
  if (decodeSize) {
    options.resizeWidth = decodeSize.width;
    options.resizeHeight = decodeSize.height;
    options.resizeQuality = 'high';
  }
  let bitmap;
  try {
    bitmap = await createImageBitmap(item.blob, options);
  } catch (error) {
    throw await classifyDecodeFailure(item, error, imageNumber);
  }
  try {
    const area = crop ?? FULL_CROP;
    ctx.save();
    if (grayscale) ctx.filter = 'grayscale(1)';
    ctx.drawImage(
      bitmap,
      area.left * bitmap.width,
      area.top * bitmap.height,
      (area.right - area.left) * bitmap.width,
      (area.bottom - area.top) * bitmap.height,
      x,
      y,
      width,
      height,
    );
    ctx.restore();
  } finally {
    bitmap.close();
  }
}

/** 영역을 적용한 썸네일로 바꾼다 (DESIGN §2.1.6). */
export async function refreshThumbnail(item) {
  const size = capLongSide(itemSize(item), kThumbnailLongSide);
  const { canvas, ctx } = createCanvas(size.width, size.height, { opaque: true });
  try {
    await drawItem(ctx, item, 0, 0, size.width, size.height);
    const blob = await canvasToBlob(canvas, 'image/jpeg', kThumbnailQuality / 100);
    URL.revokeObjectURL(item.thumbUrl);
    item.thumbUrl = URL.createObjectURL(blob);
  } finally {
    releaseCanvas(canvas);
  }
}

/** 영역 편집 화면용 임시 이미지(전체). 닫을 때 URL을 해제한다. */
export async function createCropPreview(item) {
  const size = capLongSide({ width: item.width, height: item.height }, kCropPreviewLongSide);
  const { canvas, ctx } = createCanvas(size.width, size.height, { opaque: true });
  try {
    await drawItem(ctx, item, 0, 0, size.width, size.height, { crop: null });
    const blob = await canvasToBlob(canvas, 'image/jpeg', kCropPreviewQuality / 100);
    return URL.createObjectURL(blob);
  } finally {
    releaseCanvas(canvas);
  }
}
