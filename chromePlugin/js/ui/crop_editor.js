import { croppedSize, dragCrop, FULL_CROP, isFullCrop } from '../domain/crop_rect.js';
import { createCropPreview } from '../data/items.js';
import { byId } from './dom.js';

/**
 * 영역 편집 화면 (DESIGN §2.1.6). 긴 변 1600px 임시 이미지를 쓰고 닫을 때 해제한다.
 * @returns {Promise<{crop:object|null}|null>} 적용하면 새 영역(전체면 crop=null), 취소하면 null.
 */
export async function openCropEditor(item) {
  const dialog = byId('crop-dialog');
  const stage = byId('crop-stage');
  const wrap = byId('crop-wrap');
  const image = byId('crop-image');
  const box = byId('crop-box');
  const loading = byId('crop-loading');
  const sizeLabel = byId('crop-size');
  const applyButton = byId('crop-apply');
  const resetButton = byId('crop-reset');
  const cancelButton = byId('crop-cancel');

  let crop = item.crop ?? FULL_CROP;
  let drag = null;
  let previewUrl = null;

  const paint = () => {
    box.style.left = `${crop.left * 100}%`;
    box.style.top = `${crop.top * 100}%`;
    box.style.width = `${(crop.right - crop.left) * 100}%`;
    box.style.height = `${(crop.bottom - crop.top) * 100}%`;
    const size = croppedSize(item.width, item.height, crop);
    sizeLabel.textContent = `${size.width}×${size.height}`;
  };

  // 이미지가 무대에 꼭 맞도록 표시 크기를 직접 잡는다. 영역 상자는 이 크기의 백분율이다.
  const fit = () => {
    const scale = Math.min(stage.clientWidth / item.width, stage.clientHeight / item.height);
    wrap.style.width = `${Math.max(1, item.width * scale)}px`;
    wrap.style.height = `${Math.max(1, item.height * scale)}px`;
  };

  const onPointerDown = (event) => {
    if (event.button !== 0) return;
    event.preventDefault();
    box.setPointerCapture(event.pointerId);
    drag = {
      pointerId: event.pointerId,
      handle: event.target.dataset.handle ?? 'move',
      start: crop,
      x: event.clientX,
      y: event.clientY,
    };
  };
  const onPointerMove = (event) => {
    if (!drag || event.pointerId !== drag.pointerId) return;
    const bounds = wrap.getBoundingClientRect();
    crop = dragCrop(drag.start, drag.handle, (event.clientX - drag.x) / bounds.width, (event.clientY - drag.y) / bounds.height);
    paint();
  };
  const onPointerUp = (event) => {
    if (drag && event.pointerId === drag.pointerId) drag = null;
  };
  const onReset = () => {
    crop = FULL_CROP;
    paint();
  };

  applyButton.disabled = true;
  resetButton.disabled = true;
  wrap.hidden = true;
  loading.hidden = false;
  byId('crop-name').textContent = item.displayName;
  image.removeAttribute('src');

  return new Promise((resolve, reject) => {
    const resizeObserver = new ResizeObserver(fit);

    const onApply = () => dialog.close('apply');
    const onCancel = () => dialog.close('cancel');
    const finish = () => {
      box.removeEventListener('pointerdown', onPointerDown);
      box.removeEventListener('pointermove', onPointerMove);
      box.removeEventListener('pointerup', onPointerUp);
      box.removeEventListener('pointercancel', onPointerUp);
      resetButton.removeEventListener('click', onReset);
      applyButton.removeEventListener('click', onApply);
      cancelButton.removeEventListener('click', onCancel);
      resizeObserver.disconnect();
      image.removeAttribute('src');
      if (previewUrl) URL.revokeObjectURL(previewUrl);
      previewUrl = null;
    };

    dialog.addEventListener(
      'close',
      () => {
        finish();
        resolve(dialog.returnValue === 'apply' ? { crop: isFullCrop(crop) ? null : crop } : null);
      },
      { once: true },
    );

    box.addEventListener('pointerdown', onPointerDown);
    box.addEventListener('pointermove', onPointerMove);
    box.addEventListener('pointerup', onPointerUp);
    box.addEventListener('pointercancel', onPointerUp);
    resetButton.addEventListener('click', onReset);
    applyButton.addEventListener('click', onApply);
    cancelButton.addEventListener('click', onCancel);

    dialog.returnValue = '';
    dialog.showModal();
    resizeObserver.observe(stage);
    fit();
    paint();

    createCropPreview(item).then(
      (url) => {
        previewUrl = url;
        if (!dialog.open) {
          URL.revokeObjectURL(url); // 그사이 닫혔다.
          previewUrl = null;
          return;
        }
        image.src = url;
        loading.hidden = true;
        wrap.hidden = false;
        applyButton.disabled = false;
        resetButton.disabled = false;
        fit();
      },
      (error) => {
        if (dialog.open) dialog.close('cancel');
        reject(error);
      },
    );
  });
}
