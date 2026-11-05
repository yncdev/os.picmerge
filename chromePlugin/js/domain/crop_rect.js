import { kMaxInputLongSide, kMinCropFraction } from './limits.js';

// 영역은 EXIF 반영 후 가로·세로에 대한 0~1 비율 좌표다 (DESIGN §2.1.6).
// { left, top, right, bottom }. null이면 전체다.

export const FULL_CROP = Object.freeze({ left: 0, top: 0, right: 1, bottom: 1 });

const EPSILON = 1e-6;
const clamp = (value, min, max) => Math.min(max, Math.max(min, value));

export function isFullCrop(crop) {
  return (
    !crop ||
    (crop.left <= EPSILON && crop.top <= EPSILON && crop.right >= 1 - EPSILON && crop.bottom >= 1 - EPSILON)
  );
}

/** 영역을 적용한 픽셀 크기. 크기·비율 계산은 모두 이 값으로 한다. */
export function croppedSize(width, height, crop) {
  if (!crop) return { width, height };
  return {
    width: Math.max(1, Math.round((crop.right - crop.left) * width)),
    height: Math.max(1, Math.round((crop.bottom - crop.top) * height)),
  };
}

/**
 * 끌기 결과. [start]는 끌기를 시작할 때의 영역, [dx]·[dy]는 시작점부터의 비율 이동량이다.
 * 시작 값을 기준으로 계산하므로 오차가 쌓이지 않는다.
 * @param {'move'|'n'|'s'|'e'|'w'|'ne'|'nw'|'se'|'sw'} handle
 */
export function dragCrop(start, handle, dx, dy, minFraction = kMinCropFraction) {
  if (handle === 'move') {
    const width = start.right - start.left;
    const height = start.bottom - start.top;
    const left = clamp(start.left + dx, 0, 1 - width);
    const top = clamp(start.top + dy, 0, 1 - height);
    return { left, top, right: left + width, bottom: top + height };
  }
  const crop = { ...start };
  if (handle.includes('w')) crop.left = clamp(start.left + dx, 0, start.right - minFraction);
  if (handle.includes('e')) crop.right = clamp(start.right + dx, start.left + minFraction, 1);
  if (handle.includes('n')) crop.top = clamp(start.top + dy, 0, start.bottom - minFraction);
  if (handle.includes('s')) crop.bottom = clamp(start.bottom + dy, start.top + minFraction, 1);
  return crop;
}

/**
 * 영역을 [targetWidth]×[targetHeight]로 그리려면 전체 이미지를 몇 픽셀로 디코딩하면 되는지.
 * 줄일 필요가 없으면(원본이 더 작거나 같으면) null이다. 큰 원본의 메모리와 화질을 위해 쓴다.
 * 입력 제한 때문에 영역의 긴 변은 4000px를 넘겨 디코딩하지 않는다. A3처럼 칸이 더 크면 그리면서 키운다 (DESIGN §2.1.2).
 */
export function decodeSizeForTarget(targetWidth, targetHeight, crop, sourceWidth, sourceHeight) {
  const area = crop ?? FULL_CROP;
  const cap = Math.min(1, kMaxInputLongSide / Math.max(targetWidth, targetHeight));
  const fullWidth = (targetWidth * cap) / (area.right - area.left);
  const fullHeight = (targetHeight * cap) / (area.bottom - area.top);
  if (fullWidth >= sourceWidth || fullHeight >= sourceHeight) return null;
  return { width: Math.ceil(fullWidth), height: Math.ceil(fullHeight) };
}
