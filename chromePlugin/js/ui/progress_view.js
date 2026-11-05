import { byId } from './dom.js';
import { t } from './i18n.js';

/** 저장 중 진행 표시와 취소 버튼 (DESIGN §2.2). Esc로 닫히지 않는다. */
export function createProgressView({ onCancel }) {
  const dialog = byId('progress-dialog');
  const title = byId('progress-title');
  const bar = byId('progress-bar');
  const spinner = byId('progress-spinner');
  const text = byId('progress-text');
  const hint = byId('progress-hint');
  const cancel = byId('progress-cancel');

  let active = false;

  // Chrome은 Esc를 두 번 누르면 cancel을 막아도 닫는다. 진행 중이면 곧바로 다시 연다.
  dialog.addEventListener('cancel', (event) => event.preventDefault());
  dialog.addEventListener('close', () => {
    if (active) dialog.showModal();
  });
  cancel.addEventListener('click', () => {
    cancel.disabled = true;
    text.textContent = t('progress_cancelling');
    onCancel();
  });

  return {
    open(heading) {
      active = true;
      title.textContent = heading;
      cancel.disabled = false;
      bar.hidden = false;
      bar.value = 0;
      spinner.hidden = true;
      hint.hidden = true;
      text.textContent = '';
      dialog.showModal();
    },

    update(progress) {
      if (progress.phase === 'saving') {
        // 쓰는 도중 취소하면 파일은 저장됐는데 기록은 취소로 남을 수 있다 (DESIGN §2.2).
        cancel.disabled = true;
        bar.hidden = true;
        spinner.hidden = false;
        hint.hidden = true;
        text.textContent = t('progress_saving');
        return;
      }
      if (cancel.disabled) return; // 취소하는 중에는 문구를 바꾸지 않는다.
      if (progress.phase === 'images') {
        bar.hidden = false;
        spinner.hidden = true;
        hint.hidden = true;
        bar.value = progress.total === 0 ? 0 : progress.completed / progress.total;
        text.textContent = t('progress_images', Math.min(progress.completed + 1, progress.total), progress.total);
      } else {
        bar.hidden = true;
        spinner.hidden = false;
        hint.hidden = false;
        text.textContent = t('progress_building');
      }
    },

    close() {
      active = false;
      if (dialog.open) dialog.close();
    },
  };
}
