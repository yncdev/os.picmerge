import { canPickFolder, pickFolder } from '../data/save_folder_store.js';
import { showSnack } from './dialogs.js';
import { byId } from './dom.js';
import { t } from './i18n.js';
import { saveLocationText } from './labels.js';

/**
 * 저장 폴더 변경 창 (DESIGN §2.1.4). 폴더 선택기는 버튼을 누른 제스처 안에서 바로 연다.
 * 선택기를 그냥 닫으면 아무 일도 없고 이 창이 그대로 남는다.
 * @param {{currentName?:string|null, reason?:string|null}} options 지금 폴더 이름(기본 폴더면 null)과 이 창을 띄운 이유
 * @returns {Promise<{kind:'default'}|{kind:'picked',handle:FileSystemDirectoryHandle}|{kind:'cancel'}>}
 */
export function openFolderDialog({ currentName = null, reason = null } = {}) {
  const dialog = byId('folder-dialog');
  const useDefaultButton = byId('folder-use-default');
  const pickButton = byId('folder-pick');
  const cancelButton = byId('folder-cancel');
  const reasonText = byId('folder-reason');

  byId('folder-current').textContent = saveLocationText(currentName);
  reasonText.hidden = !reason;
  reasonText.textContent = reason ?? '';
  useDefaultButton.hidden = currentName === null;
  pickButton.hidden = !canPickFolder();
  pickButton.disabled = false;

  return new Promise((resolve) => {
    const finish = (outcome) => {
      useDefaultButton.removeEventListener('click', onUseDefault);
      pickButton.removeEventListener('click', onPick);
      cancelButton.removeEventListener('click', onCancel);
      dialog.removeEventListener('close', onClose);
      if (dialog.open) dialog.close();
      resolve(outcome);
    };
    function onUseDefault() {
      finish({ kind: 'default' });
    }
    async function onPick() {
      pickButton.disabled = true;
      try {
        const handle = await pickFolder();
        if (handle) finish({ kind: 'picked', handle });
      } catch (error) {
        console.warn('folder picker failed', error);
        showSnack(t('folder_pick_failed'));
      } finally {
        pickButton.disabled = false;
      }
    }
    function onCancel() {
      finish({ kind: 'cancel' });
    }
    // Esc로 닫은 경우다. close 이벤트는 다음 프레임에야 오므로, 그사이 다시 열렸으면 앞 창의 이벤트다.
    function onClose() {
      if (!dialog.open) finish({ kind: 'cancel' });
    }

    useDefaultButton.addEventListener('click', onUseDefault);
    pickButton.addEventListener('click', onPick);
    cancelButton.addEventListener('click', onCancel);
    dialog.addEventListener('close', onClose);
    dialog.showModal();
  });
}
