import { CancelToken, mergePdf, mergePng } from './data/merge.js';
import { downloadBlob } from './data/download.js';
import { historyStore } from './data/history_store.js';
import { canPickFolder, ensureFolderAccess, FolderAccess, folderStore, writeToFolder } from './data/save_folder_store.js';
import { createImageItem, discardItem, itemSize, refreshThumbnail, sniffFile } from './data/items.js';
import { expandPdf } from './data/pdf_source.js';
import { ErrorCode, MergeCancelled, MergeError } from './domain/errors.js';
import { OUTPUT_FORMATS, uniqueFileName } from './domain/file_naming.js';
import { defaultFolderNames, Destination } from './domain/history_model.js';
import { JobPhase, losesWorkOnLeave } from './domain/job_phase.js';
import { kMaxImages, kMinImages } from './domain/limits.js';
import { IMAGE_SIZE_OPTIONS, PADDING_OPTIONS, PER_SHEET_OPTIONS } from './domain/page_layout.js';
import { DEFAULT_SETTINGS, PAPERS } from './domain/paper.js';
import { pngDirection } from './domain/png_plan.js';
import { openCropEditor } from './ui/crop_editor.js';
import { showAlert, showConfirm, showSnack } from './ui/dialogs.js';
import { byId, h } from './ui/dom.js';
import { openFolderDialog } from './ui/folder_dialog.js';
import { openHistorySheet } from './ui/history_sheet.js';
import { applyTranslations, t } from './ui/i18n.js';
import { APP_NAME, appTitle, errorMessage, paperLabel, saveLocationText } from './ui/labels.js';
import { renderList } from './ui/list_view.js';
import { fitPreviewFrame, renderPreview } from './ui/preview_view.js';
import { createProgressView } from './ui/progress_view.js';
import { chooseShareFormat, openShareDialog } from './ui/share_dialog.js';

const state = {
  /** 저장·공유 성공 뒤에도 그대로 둔다 (DESIGN §2.1.1). */
  items: [],
  /** 기억하지 않는다. 앱을 시작하면 항상 기본값이다 (DESIGN §2.1.5). */
  settings: { ...DEFAULT_SETTINGS },
  /** 사용자가 고른 저장 폴더의 핸들. null이면 기본 폴더(브라우저 다운로드)다. */
  folder: null,
  /** 기억한 폴더를 읽었는가. 읽기 전에는 저장 위치를 비워 두어 잠깐이라도 틀린 위치를 보여주지 않는다. */
  folderKnown: false,
  /** 저장·공유 한 번의 단계. 공유 창이 열려 있는 동안은 `finished`다. */
  phase: JobPhase.idle,
  /** 파일을 불러오는 중이면 { done, total }. */
  adding: null,
};

let cancelToken = null;
const progressView = createProgressView({ onCancel: () => cancelToken?.cancel() });

const isBusy = () => state.phase !== JobPhase.idle || state.adding !== null;

/** 앱을 시작할 때 읽어 온다. 저장 버튼을 누르면 이것부터 기다린다. */
let folderLoaded = Promise.resolve();

// ---- 화면 ----

function renderProgressBar() {
  const bar = byId('add-progress');
  bar.hidden = state.adding === null;
  if (state.adding) {
    const { done, total } = state.adding;
    bar.value = total === 0 ? 0 : Math.min(1, done / total);
  }
}

function render() {
  const { items, settings } = state;
  const busy = isBusy();
  const canSave = !busy && items.length >= kMinImages;

  byId('empty-state').hidden = items.length > 0;
  byId('item-list').hidden = items.length === 0;
  byId('list-header').hidden = items.length === 0;
  byId('list-count').textContent = t('list_count', items.length, kMaxImages);
  byId('add-button').disabled = busy || items.length >= kMaxImages;
  byId('pick-button').disabled = busy;
  byId('clear-button').disabled = busy;
  byId('history-button').disabled = busy;

  renderList(byId('item-list'), items, { enabled: !busy, onRemove: removeItem, onCrop: editCrop, onReorder: reorder });
  renderPreview(items, settings);

  byId('save-hint').hidden = items.length !== 1;
  byId('save-png').disabled = !canSave;
  byId('save-pdf').disabled = !canSave;
  byId('share-button').disabled = !canSave;
  byId('save-location').textContent = state.folderKnown ? saveLocationText(state.folder?.name ?? null) : '';
  const changeFolderButton = byId('change-folder');
  changeFolderButton.hidden = !state.folder && !canPickFolder(); // 고를 수 없고 되돌릴 것도 없으면 할 일이 없다.
  changeFolderButton.disabled = busy;

  const isOriginal = settings.paper === 'original';
  byId('paper-select').disabled = busy;
  for (const input of document.querySelectorAll('input[name="orientation"]')) {
    input.disabled = busy || isOriginal;
    input.checked = input.value === settings.orientation;
  }
  for (const input of document.querySelectorAll('input[name="color"]')) {
    input.disabled = busy;
    input.checked = input.value === (settings.grayscale ? 'gray' : 'color');
  }
  byId('orientation-group').classList.toggle('disabled', isOriginal);
  // 맞출 용지가 없으면 칸도 없다 (DESIGN §2.1.5).
  const perSheet = byId('per-sheet-select');
  perSheet.disabled = busy || isOriginal;
  perSheet.value = String(settings.perSheet);
  byId('per-sheet-setting').classList.toggle('disabled', isOriginal);
  const imageSize = byId('image-size-select');
  imageSize.disabled = busy || isOriginal;
  imageSize.value = String(settings.imageSize);
  byId('image-size-setting').classList.toggle('disabled', isOriginal);
  // 여백은 '원본 크기'에도 쓴다 (DESIGN §2.1.5).
  for (const input of document.querySelectorAll('input[name="padding"]')) {
    input.disabled = busy;
    input.checked = Number(input.value) === settings.padding;
  }
  renderProgressBar();
}

// ---- 목록 ----

async function addFiles(fileList) {
  if (isBusy()) return;
  const files = [...fileList];
  if (files.length === 0) return;
  let remaining = kMaxImages - state.items.length;
  if (remaining <= 0) {
    showSnack(t('snack_max_images', kMaxImages));
    return;
  }

  let added = 0;
  let unsupported = 0;
  let overLimit = 0;
  const progress = { done: 0, total: files.length };
  state.adding = progress;
  render();
  try {
    for (const file of files) {
      if (remaining <= 0) {
        overLimit++;
        continue;
      }
      try {
        const kind = await sniffFile(file);
        if (kind === null) {
          unsupported++;
        } else if (kind === 'pdf') {
          const { items, overLimit: pagesOver } = await expandPdf(file, {
            maxPages: remaining,
            onOpened: (pages) => {
              // 파일 하나를 페이지 수만큼으로 바꿔 센다.
              progress.total += pages - 1;
              renderProgressBar();
            },
            onPage: () => {
              progress.done++;
              renderProgressBar();
            },
          });
          state.items.push(...items);
          added += items.length;
          remaining -= items.length;
          overLimit += pagesOver;
          render();
          continue; // 진행률은 페이지마다 이미 올렸다.
        } else {
          state.items.push(await createImageItem(file));
          added++;
          remaining--;
          render();
        }
      } catch (error) {
        // 고를 때 읽지 못한 파일은 목록에 넣지 않고, 세션 기록도 남기지 않는다 (DESIGN §2.1.1).
        console.warn(`excluded ${file.name}`, error);
        unsupported++;
      }
      progress.done++;
      renderProgressBar();
    }
  } finally {
    state.adding = null;
    render();
  }
  if (unsupported > 0) showSnack(t('snack_unsupported', unsupported));
  if (overLimit > 0) showSnack(t('snack_over_limit', kMaxImages, added));
}

function removeItem(item) {
  state.items = state.items.filter((other) => other !== item);
  discardItem(item);
  render();
}

function reorder(from, to) {
  const list = [...state.items];
  const [moved] = list.splice(from, 1);
  list.splice(to, 0, moved);
  state.items = list;
  render();
}

async function clearItems() {
  const ok = await showConfirm({
    message: t('clear_confirm'),
    confirmLabel: t('clear'),
  });
  if (!ok) return;
  state.items.forEach(discardItem);
  state.items = [];
  render();
}

async function editCrop(item) {
  try {
    const result = await openCropEditor(item);
    if (!result) return;
    item.crop = result.crop;
    await refreshThumbnail(item);
    render();
  } catch (error) {
    console.warn('crop editor failed', error);
    await showAlert({
      title: t('crop_open_failed_title'),
      message: error instanceof MergeError ? errorMessage(error.code, error.imageNumber) : t('crop_open_failed_message'),
    });
  }
}

// ---- 저장과 공유 ----

function progressTitle(formatCode, sharing) {
  if (formatCode === 'png') return sharing ? t('share_png') : t('save_png');
  return sharing ? t('share_pdf') : t('save_pdf');
}

/**
 * 저장 폴더 변경 창을 띄우고 고른 대로 바꾼다 (DESIGN §2.1.4).
 * @param {string|null} reason 창을 띄운 이유. 사용자가 '변경'을 눌렀으면 null이다.
 * @returns {Promise<'default'|'picked'|'cancel'>}
 */
async function changeFolder(reason = null) {
  const outcome = await openFolderDialog({ currentName: state.folder?.name ?? null, reason });
  // 화면부터 바꾼다. 저장소에 쓰는 동안 옛 폴더 이름이 보이지 않게 한다.
  if (outcome.kind === 'default') {
    state.folder = null;
    render();
    await folderStore.clear();
  } else if (outcome.kind === 'picked') {
    state.folder = outcome.handle;
    render();
    await folderStore.save(outcome.handle);
  }
  return outcome.kind;
}

/**
 * 합성을 시작하기 전에 저장 폴더를 쓸 수 있게 한다. 합성을 다 마친 뒤에 실패하지 않으려는 것이다 (DESIGN §2.1.4).
 * requestPermission 때문에 저장 버튼을 누른 제스처 안에서 부른다.
 * @returns {Promise<boolean>} 거짓이면 저장하지 않는다.
 */
async function prepareSaveFolder() {
  state.phase = JobPhase.preparing;
  render();
  try {
    await folderLoaded;
    if (!state.folder) return true;
    if ((await ensureFolderAccess(state.folder)) === FolderAccess.granted) return true;
    return (await changeFolder(errorMessage(ErrorCode.folderUnavailable))) !== 'cancel';
  } finally {
    state.phase = JobPhase.idle;
    render();
  }
}

/**
 * 저장·공유 1회 = 세션 1개 (DESIGN §3.2).
 * @param {'png'|'pdf'} formatCode
 * @param {'download'|'share'} destination
 */
async function produce(formatCode, destination) {
  if (isBusy()) return;
  const sharing = destination === 'share';
  if (!sharing && !(await prepareSaveFolder())) return;
  if (isBusy()) return;
  const format = OUTPUT_FORMATS[formatCode];
  const items = [...state.items];
  const settings = { ...state.settings };
  const folder = sharing ? null : state.folder;
  const token = new CancelToken();
  cancelToken = token;
  state.phase = JobPhase.merging;
  render();
  progressView.open(progressTitle(format.code, sharing));

  const session = historyStore.start({
    format: format.code,
    direction: format.code === 'png' ? pngDirection(items.map(itemSize), settings).code : null,
    count: items.length,
    destination: sharing ? Destination.share : (folder?.name ?? Destination.download),
    customFolder: Boolean(folder),
  });

  let result = null;
  try {
    const onProgress = (progress) => progressView.update(progress);
    result =
      format.code === 'png'
        ? await mergePng(items, settings, { token, onProgress })
        : await mergePdf(items, settings, { token, onProgress });
    token.throwIfCancelled();

    let fileName;
    if (folder) {
      onProgress({ phase: 'saving' });
      fileName = await writeToFolder(folder, new Date(), format.extension, result.blob);
    } else {
      // 공유도 같은 규칙이다. 공유 창의 내려받기는 기본 폴더로 간다.
      fileName = uniqueFileName(new Date(), format.extension, defaultFolderNames(historyStore.all()));
    }
    historyStore.finishSuccess(session, {
      fileName,
      bytes: result.blob.size,
      width: result.width ?? null,
      height: result.height ?? null,
    });
    state.phase = JobPhase.finished; // 여기부터는 탭을 닫아도 잃는 것이 없다.
    progressView.close();
    if (sharing) {
      await openShareDialog({ blob: result.blob, fileName, mimeType: format.mimeType });
    } else if (folder) {
      showSnack(t('snack_saved_folder', folder.name, fileName));
    } else {
      downloadBlob(result.blob, fileName);
      showSnack(t('snack_saved', fileName));
    }
  } catch (error) {
    state.phase = JobPhase.finished;
    progressView.close();
    if (error instanceof MergeCancelled) {
      historyStore.finishCancelled(session);
      showSnack(sharing ? t('snack_share_cancelled') : t('snack_save_cancelled'));
    } else {
      console.error('merge failed', error);
      const failure = error instanceof MergeError ? error : new MergeError(ErrorCode.unknown, { detail: String(error) });
      historyStore.finishFailure(session, failure.code);
      if (folder && failure.code === ErrorCode.folderUnavailable) {
        await changeFolder(errorMessage(failure.code));
      } else {
        await showAlert({
          title: sharing ? t('alert_share_failed_title') : t('alert_save_failed_title'),
          message: errorMessage(failure.code, failure.imageNumber),
        });
      }
    }
  } finally {
    cancelToken = null;
    state.phase = JobPhase.idle;
    render();
  }
}

async function share() {
  if (isBusy()) return;
  const format = await chooseShareFormat();
  if (format === 'png' || format === 'pdf') await produce(format, 'share');
}

// ---- 시작 ----

function bindEvents() {
  const fileInput = byId('file-input');
  const openPicker = () => fileInput.click();
  byId('pick-button').addEventListener('click', openPicker);
  byId('add-button').addEventListener('click', openPicker);
  fileInput.addEventListener('change', async () => {
    const files = [...fileInput.files];
    fileInput.value = ''; // 같은 파일을 다시 고를 수 있게 한다.
    await addFiles(files);
  });
  byId('clear-button').addEventListener('click', clearItems);
  byId('save-png').addEventListener('click', () => produce('png', 'download'));
  byId('save-pdf').addEventListener('click', () => produce('pdf', 'download'));
  byId('share-button').addEventListener('click', share);
  byId('change-folder').addEventListener('click', () => {
    if (!isBusy()) changeFolder();
  });
  byId('history-button').addEventListener('click', openHistorySheet);
  byId('history-close').addEventListener('click', () => byId('history-dialog').close());

  const paper = byId('paper-select');
  paper.replaceChildren(...PAPERS.map((p) => h('option', { value: p.code }, paperLabel(p.code))));
  paper.value = state.settings.paper;
  paper.addEventListener('change', () => {
    state.settings.paper = paper.value;
    render();
  });
  const perSheet = byId('per-sheet-select');
  perSheet.replaceChildren(...PER_SHEET_OPTIONS.map((n) => h('option', { value: n }, String(n))));
  perSheet.addEventListener('change', () => {
    state.settings.perSheet = Number(perSheet.value);
    render();
  });
  const imageSize = byId('image-size-select');
  imageSize.replaceChildren(...IMAGE_SIZE_OPTIONS.map((f) => h('option', { value: f }, t('percent_value', f))));
  imageSize.addEventListener('change', () => {
    state.settings.imageSize = Number(imageSize.value);
    render();
  });
  byId('padding-group').append(
    ...PADDING_OPTIONS.map((padding) =>
      h(
        'label',
        {},
        h('input', {
          type: 'radio',
          name: 'padding',
          value: padding,
          onchange: () => {
            state.settings.padding = padding;
            render();
          },
        }),
        h('span', {}, t('percent_value', padding)),
      ),
    ),
  );
  for (const input of document.querySelectorAll('input[name="orientation"]')) {
    input.addEventListener('change', () => {
      state.settings.orientation = input.value;
      render();
    });
  }
  for (const input of document.querySelectorAll('input[name="color"]')) {
    input.addEventListener('change', () => {
      state.settings.grayscale = input.value === 'gray';
      render();
    });
  }

  bindFileDrop();
  new ResizeObserver(fitPreviewFrame).observe(byId('preview-box'));

  // 저장 중에 탭을 닫으면 비정상 종료로 남는다 (DESIGN §3.4). 실수로 닫지 않도록 한 번 묻는다.
  window.addEventListener('beforeunload', (event) => {
    if (losesWorkOnLeave(state.phase)) event.preventDefault();
  });
}

function bindFileDrop() {
  const overlay = byId('drop-overlay');
  const hasFiles = (event) => event.dataTransfer?.types.includes('Files');
  // 대화 상자가 열려 있으면 뒤의 목록에 말없이 더하지 않는다.
  const isModalOpen = () => document.querySelector('dialog[open]') !== null;
  document.addEventListener('dragover', (event) => {
    if (!hasFiles(event)) return;
    event.preventDefault();
    if (!isBusy() && !isModalOpen()) overlay.hidden = false;
  });
  document.addEventListener('dragleave', (event) => {
    if (event.relatedTarget === null) overlay.hidden = true;
  });
  document.addEventListener('drop', (event) => {
    overlay.hidden = true;
    if (!hasFiles(event)) return;
    event.preventDefault(); // 무시할 때도 막아야 브라우저가 탭을 그 파일로 바꾸지 않는다.
    if (!isModalOpen()) addFiles(event.dataTransfer.files);
  });
}

/** 언어를 화면에 입힌다. 제목은 이름과 작은 부제로 나눈다 (DESIGN §2.2). */
function applyLanguage() {
  document.documentElement.lang = t('html_lang');
  document.title = appTitle();
  const subtitle = t('app_subtitle');
  byId('app-title').replaceChildren(APP_NAME, ...(subtitle ? [' ', h('small', { class: 'subtitle' }, subtitle)] : []));
  applyTranslations();
}

function start() {
  applyLanguage();
  bindEvents();
  render();
  folderLoaded = folderStore.load().then((handle) => {
    state.folder = handle;
    state.folderKnown = true;
    render();
  });
  if (historyStore.markRunningAsCrashed() > 0) {
    showAlert({
      title: t('crashed_title'),
      message: t('crashed_message'),
    });
  }
}

start();
