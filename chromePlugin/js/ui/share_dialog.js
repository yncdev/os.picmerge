import { downloadBlob } from '../data/download.js';
import { formatBytes } from '../domain/format.js';
import { showSnack } from './dialogs.js';
import { byId } from './dom.js';
import { t } from './i18n.js';

/** 공유할 형식을 고른다. 취소하면 null. */
export function chooseShareFormat() {
  const dialog = byId('share-format-dialog');
  dialog.returnValue = '';
  return new Promise((resolve) => {
    dialog.addEventListener('close', () => resolve(dialog.returnValue || null), { once: true });
    dialog.showModal();
  });
}

function canShareFile(file) {
  try {
    return Boolean(navigator.canShare?.({ files: [file] }));
  } catch {
    return false;
  }
}

/** 메일 앱을 연다. mailto:는 파일을 첨부할 수 없어 파일을 먼저 내려받는다 (DESIGN §5.2). */
function openMailDraft(fileName) {
  const subject = encodeURIComponent(t('mail_subject', fileName));
  const body = encodeURIComponent(t('mail_body', fileName));
  const link = document.createElement('a');
  link.href = `mailto:?subject=${subject}&body=${body}`;
  link.click();
}

/**
 * 만든 파일을 보내는 대화 상자. Web Share는 사용자 탭 직후에만 호출할 수 있어,
 * 파일을 다 만든 뒤 이 화면에서 한 번 더 누르게 한다 (DESIGN §5.2).
 */
export function openShareDialog({ blob, fileName, mimeType }) {
  const dialog = byId('share-dialog');
  const file = new File([blob], fileName, { type: mimeType });
  const isPng = mimeType === 'image/png';
  const canShare = canShareFile(file);

  byId('share-file').textContent = `${fileName} (${formatBytes(blob.size)})`;
  const shareButton = byId('share-system');
  const copyButton = byId('share-copy');
  const mailButton = byId('share-mail');
  const downloadButton = byId('share-download');
  const closeButton = byId('share-close');

  shareButton.disabled = !canShare;
  byId('share-unavailable').hidden = canShare;
  copyButton.disabled = !isPng;
  copyButton.title = isPng ? '' : t('copy_png_only');

  const onShare = async () => {
    try {
      await navigator.share({ files: [file], title: fileName });
    } catch (error) {
      if (error?.name !== 'AbortError') {
        console.warn('share failed', error);
        showSnack(t('snack_share_failed'));
      }
    }
  };
  const onCopy = async () => {
    try {
      await navigator.clipboard.write([new ClipboardItem({ 'image/png': blob })]);
      showSnack(t('snack_copied'));
    } catch (error) {
      console.warn('copy failed', error);
      showSnack(t('snack_copy_failed'));
    }
  };
  const onMail = () => {
    downloadBlob(blob, fileName);
    openMailDraft(fileName);
    showSnack(t('snack_mail', fileName));
  };
  const onDownload = () => {
    downloadBlob(blob, fileName);
    showSnack(t('snack_saved', fileName));
  };
  const onClose = () => dialog.close();

  shareButton.addEventListener('click', onShare);
  copyButton.addEventListener('click', onCopy);
  mailButton.addEventListener('click', onMail);
  downloadButton.addEventListener('click', onDownload);
  closeButton.addEventListener('click', onClose);

  return new Promise((resolve) => {
    dialog.addEventListener(
      'close',
      () => {
        shareButton.removeEventListener('click', onShare);
        copyButton.removeEventListener('click', onCopy);
        mailButton.removeEventListener('click', onMail);
        downloadButton.removeEventListener('click', onDownload);
        closeButton.removeEventListener('click', onClose);
        resolve();
      },
      { once: true },
    );
    dialog.showModal();
  });
}
