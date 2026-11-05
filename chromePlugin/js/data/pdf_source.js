import { kMaxInputLongSide, kPdfRenderDpi, kPdfRenderQuality } from '../domain/limits.js';
import { canvasToBlob, createCanvas, releaseCanvas } from './canvas.js';
import { createPageItem, discardItem } from './items.js';

const POINTS_PER_INCH = 72;

let pdfjsPromise = null;

/** pdf.js는 PDF를 고를 때만 불러온다. 모두 확장 안의 파일이고 원격 코드는 없다 (DESIGN §5.2). */
function loadPdfjs() {
  pdfjsPromise ??= import('../../vendor/pdfjs/pdf.min.mjs').then((pdfjs) => {
    pdfjs.GlobalWorkerOptions.workerSrc = chrome.runtime.getURL('vendor/pdfjs/pdf.worker.min.mjs');
    return pdfjs;
  });
  return pdfjsPromise;
}

async function renderPage(page, displayName) {
  const unit = page.getViewport({ scale: 1 });
  const dpiScale = kPdfRenderDpi / POINTS_PER_INCH;
  const scale = Math.min(dpiScale, kMaxInputLongSide / Math.max(unit.width, unit.height));
  const viewport = page.getViewport({ scale });
  const width = Math.max(1, Math.floor(viewport.width));
  const height = Math.max(1, Math.floor(viewport.height));
  const { canvas } = createCanvas(width, height, { opaque: true });
  try {
    await page.render({ canvas, viewport, background: '#ffffff' }).promise;
    const jpeg = await canvasToBlob(canvas, 'image/jpeg', kPdfRenderQuality / 100);
    return await createPageItem(jpeg, canvas, displayName);
  } finally {
    releaseCanvas(canvas);
  }
}

/**
 * PDF를 페이지마다 항목 1개로 펼친다 (DESIGN §2.1.1). 한 페이지씩 렌더링하고 해제한다.
 * 암호가 걸렸거나 열 수 없으면 예외를 던지고, 만들던 항목을 모두 버린다.
 * @param {File} file
 * @param {{maxPages:number, onOpened?:(pages:number)=>void, onPage?:()=>void}} options
 * @returns {Promise<{items:object[], overLimit:number}>}
 */
export async function expandPdf(file, { maxPages, onOpened, onPage }) {
  const pdfjs = await loadPdfjs();
  const vendor = chrome.runtime.getURL('vendor/pdfjs/');
  const task = pdfjs.getDocument({
    data: new Uint8Array(await file.arrayBuffer()),
    isEvalSupported: false,
    cMapUrl: `${vendor}cmaps/`,
    cMapPacked: true,
    standardFontDataUrl: `${vendor}standard_fonts/`,
    wasmUrl: `${vendor}wasm/`,
    iccUrl: `${vendor}iccs/`,
  });
  const items = [];
  try {
    const pdf = await task.promise;
    const total = pdf.numPages;
    const count = Math.min(total, maxPages);
    onOpened?.(count);
    for (let number = 1; number <= count; number++) {
      const page = await pdf.getPage(number);
      try {
        items.push(await renderPage(page, `${file.name} (${number}/${total})`));
      } finally {
        page.cleanup();
      }
      onPage?.();
    }
    return { items, overLimit: total - count };
  } catch (error) {
    items.forEach(discardItem);
    throw error;
  } finally {
    await task.destroy();
  }
}
