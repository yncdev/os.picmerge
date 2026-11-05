import { dividerThickness, layoutPages } from '../domain/page_layout.js';
import { paperCanvas, paperSizeMm } from '../domain/paper.js';
import { planPngOriginal, pngDirection } from '../domain/png_plan.js';
import { itemSize } from '../data/items.js';
import { byId, h } from './dom.js';
import { t } from './i18n.js';
import { directionText, previewNote } from './labels.js';

/** 페이지 테두리와 그림자가 상자에 잘리지 않게 둘 여유(px). */
const SHEET_MARGIN = 6;
/** 페이지 번호 줄과 가로 스크롤 막대 몫(px). */
const NUMBER_HEIGHT = 34;

let sheetSize = null;

/** 상자 크기에 맞춰 페이지 크기만 다시 잡는다. 창 크기가 바뀔 때도 부른다. */
export function fitPreviewFrame() {
  if (!sheetSize) return;
  const box = byId('preview-box');
  const scale = Math.min(
    (box.clientWidth - SHEET_MARGIN * 2) / sheetSize.width,
    (box.clientHeight - SHEET_MARGIN * 2 - NUMBER_HEIGHT) / sheetSize.height,
  );
  const width = `${Math.max(1, sheetSize.width * scale)}px`;
  const height = `${Math.max(1, sheetSize.height * scale)}px`;
  for (const sheet of box.querySelectorAll('.preview-sheet')) {
    sheet.style.width = width;
    sheet.style.height = height;
  }
}

/** 썸네일을 페이지 안의 자리에 백분율로 놓는다. */
function placedImage(item, rect, size) {
  const image = h('img', { src: item.thumbUrl, alt: '', draggable: 'false' });
  image.style.left = `${(rect.x / size.width) * 100}%`;
  image.style.top = `${(rect.y / size.height) * 100}%`;
  image.style.width = `${(rect.width / size.width) * 100}%`;
  image.style.height = `${(rect.height / size.height) * 100}%`;
  return image;
}

function pageElement(images, number) {
  return h(
    'figure',
    { class: 'preview-page' },
    h('div', { class: 'preview-sheet' }, ...images),
    number === null ? null : h('figcaption', { class: 'preview-number', 'aria-label': t('preview_page_label', number) }, String(number)),
  );
}

/**
 * 페이지 미리보기 (DESIGN §2.2). 실제 합성은 하지 않고 실제 출력과 같은 Domain 계산으로 썸네일을 놓는다.
 * 여백은 그리고 구분선은 그리지 않는다. PDF에는 선이 없고 미리보기는 두 형식이 함께 쓰기 때문이다.
 * 썸네일은 이미 영역이 반영되어 있다. 배치 방향을 바꾸는 컨트롤은 없다.
 */
export function renderPreview(items, settings) {
  const pages = byId('preview-pages');
  const summary = byId('preview-direction');
  const note = byId('preview-note');
  const mm = paperSizeMm(settings);

  pages.classList.toggle('grayscale', settings.grayscale);
  if (items.length === 0) {
    // 항목이 없어도 고른 용지를 보여준다. '원본 크기'는 크기를 알 수 없어 비운다.
    sheetSize = mm ? paperCanvas(mm) : null;
    pages.replaceChildren(...(mm ? [pageElement([], null)] : []));
    summary.hidden = true;
    note.hidden = true;
    fitPreviewFrame();
    return;
  }

  const sizes = items.map(itemSize);
  if (mm) {
    // 페이지 수에 따라 줄어드는 실제 픽셀과 달리 미리보기 비율은 그대로라 300DPI 크기로 계산한다.
    const base = paperCanvas(mm);
    const layout = layoutPages(sizes, base, settings, { minGap: dividerThickness(Math.min(base.width, base.height)) });
    sheetSize = base;
    pages.replaceChildren(
      ...layout.pages.map((images, p) =>
        pageElement(images.map((rect) => placedImage(items[rect.index], rect, base)), p + 1),
      ),
    );
    summary.textContent = t('preview_summary', layout.pages.length, settings.perSheet);
    note.textContent = previewNote(pngDirection(sizes, settings), true);
  } else {
    const plan = planPngOriginal(sizes, { padding: settings.padding });
    sheetSize = { width: plan.canvasWidth, height: plan.canvasHeight };
    pages.replaceChildren(pageElement(items.map((item, i) => placedImage(item, plan.placements[i], sheetSize)), null));
    summary.textContent = directionText(plan.direction);
    note.textContent = previewNote(plan.direction, false);
  }
  summary.hidden = false;
  note.hidden = false;
  fitPreviewFrame();
}
