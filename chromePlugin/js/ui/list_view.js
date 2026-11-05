import { formatBytes } from '../domain/format.js';
import { itemSize } from '../data/items.js';
import { h, icon } from './dom.js';
import { t } from './i18n.js';

const ITEM_MIME = 'application/x-picmerge-item';

/**
 * 선택 목록을 그린다. 순서는 드래그 앤 드롭으로 바꾼다 (DESIGN §2.1.1).
 * 손잡이에 초점을 두고 위·아래 화살표로도 옮길 수 있다.
 * @param {HTMLElement} list
 * @param {object[]} items
 * @param {{enabled:boolean,onRemove:Function,onCrop:Function,onReorder:(from:number,to:number)=>void}} handlers
 */
export function renderList(list, items, { enabled, onRemove, onCrop, onReorder }) {
  const focusedId = document.activeElement?.closest?.('.item')?.dataset.id;
  list.replaceChildren(...items.map((item, index) => renderItem(item, index, items.length, { enabled, onRemove, onCrop, onReorder })));
  if (focusedId) list.querySelector(`.item[data-id="${focusedId}"] .drag-handle`)?.focus();
}

function renderItem(item, index, count, { enabled, onRemove, onCrop, onReorder }) {
  const size = itemSize(item);
  const details = [`${size.width}×${size.height}`, formatBytes(item.bytes)];
  if (item.crop) details.push(t('item_cropped'));

  const row = h(
    'li',
    { class: 'item', 'data-id': item.id, draggable: enabled ? 'true' : 'false' },
    h(
      'div',
      { class: 'thumb' },
      h('img', { src: item.thumbUrl, alt: '', draggable: 'false' }),
      h('span', { class: 'badge' }, String(index + 1)),
    ),
    h(
      'div',
      { class: 'meta' },
      h('div', { class: 'name', title: item.displayName }, item.displayName),
      h('div', { class: 'sub' }, details.join(' · ')),
    ),
    h(
      'button',
      {
        type: 'button',
        class: item.crop ? 'icon-button active' : 'icon-button',
        title: t('crop_title'),
        'aria-label': t('item_crop_label', index + 1),
        disabled: !enabled,
        onclick: () => onCrop(item),
      },
      icon('crop'),
    ),
    h(
      'button',
      {
        type: 'button',
        class: 'icon-button',
        title: t('item_remove_title'),
        'aria-label': t('item_remove_label', index + 1),
        disabled: !enabled,
        onclick: () => onRemove(item),
      },
      icon('close'),
    ),
    h(
      'span',
      {
        class: enabled ? 'drag-handle' : 'drag-handle disabled',
        tabindex: enabled ? '0' : null,
        role: 'button',
        title: t('item_drag_title'),
        'aria-label': t('item_drag_label', index + 1),
        onkeydown: (event) => {
          if (!enabled) return;
          const target = event.key === 'ArrowUp' ? index - 1 : event.key === 'ArrowDown' ? index + 1 : null;
          if (target === null) return;
          event.preventDefault();
          if (target >= 0 && target < count) onReorder(index, target);
        },
      },
      icon('drag'),
    ),
  );

  if (enabled) attachDrag(row, index, onReorder);
  return row;
}

function attachDrag(row, index, onReorder) {
  const clearMarks = () => row.classList.remove('drop-before', 'drop-after');
  const isItemDrag = (event) => event.dataTransfer.types.includes(ITEM_MIME);
  const dropsAfter = (event) => {
    const box = row.getBoundingClientRect();
    return event.clientY > box.top + box.height / 2;
  };

  row.addEventListener('dragstart', (event) => {
    event.dataTransfer.setData(ITEM_MIME, String(index));
    event.dataTransfer.effectAllowed = 'move';
    row.classList.add('dragging');
  });
  row.addEventListener('dragend', () => row.classList.remove('dragging'));
  row.addEventListener('dragover', (event) => {
    if (!isItemDrag(event)) return;
    event.preventDefault();
    event.dataTransfer.dropEffect = 'move';
    const after = dropsAfter(event);
    row.classList.toggle('drop-after', after);
    row.classList.toggle('drop-before', !after);
  });
  row.addEventListener('dragleave', clearMarks);
  row.addEventListener('drop', (event) => {
    if (!isItemDrag(event)) return;
    event.preventDefault();
    event.stopPropagation();
    clearMarks();
    const from = Number(event.dataTransfer.getData(ITEM_MIME));
    const slot = dropsAfter(event) ? index + 1 : index; // 빼기 전 목록 기준 끼워 넣을 자리
    const to = from < slot ? slot - 1 : slot;
    if (to !== from) onReorder(from, to);
  });
}
