import { ErrorCode, MergeError } from '../domain/errors.js';

/**
 * 2D 캔버스를 만든다. 큰 캔버스를 만들 수 없으면 `out_of_memory`.
 * [opaque]면 흰색으로 채운 불투명 캔버스다. willReadFrequently는 GPU 메모리 상한을 피하려고 켠다.
 */
export function createCanvas(width, height, { opaque = false } = {}) {
  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext('2d', { alpha: !opaque, willReadFrequently: true });
  if (!ctx || canvas.width !== width || canvas.height !== height) {
    throw new MergeError(ErrorCode.outOfMemory, { detail: `canvas ${width}x${height}` });
  }
  ctx.imageSmoothingEnabled = true;
  ctx.imageSmoothingQuality = 'high';
  if (opaque) {
    ctx.fillStyle = '#ffffff';
    ctx.fillRect(0, 0, width, height);
  }
  return { canvas, ctx };
}

/** 캔버스 메모리를 바로 놓는다. GC를 기다리면 큰 캔버스 여러 장이 동시에 살아 있게 된다. */
export function releaseCanvas(canvas) {
  canvas.width = 0;
  canvas.height = 0;
}

export function canvasToBlob(canvas, type, quality) {
  return new Promise((resolve, reject) => {
    canvas.toBlob(
      (blob) => {
        if (blob) resolve(blob);
        else reject(new MergeError(ErrorCode.outOfMemory, { detail: `toBlob ${type} returned null` }));
      },
      type,
      quality,
    );
  });
}
