import { byId, h } from './dom.js';
import { t } from './i18n.js';

const SNACK_MS = 4500;

/**
 * 저장 완료 같은 짧은 안내. 여러 개면 함께 쌓인다.
 * 모달 대화 상자 위에도 보이도록 popover로 띄운다. 다시 열어야 맨 위로 올라간다.
 */
export function showSnack(message) {
  const bar = byId('snackbar');
  const snack = h('div', { class: 'snack' }, message);
  bar.append(snack);
  if (bar.matches(':popover-open')) bar.hidePopover();
  bar.showPopover();
  setTimeout(() => {
    snack.remove();
    if (bar.childElementCount === 0 && bar.matches(':popover-open')) bar.hidePopover();
  }, SNACK_MS);
}

/**
 * 메시지 대화 상자. 누른 버튼의 value로 끝난다. Esc는 빈 문자열이다.
 * @param {{title?:string, message:string, actions:{label:string,value:string,primary?:boolean}[]}} options
 */
function showMessage({ title, message, actions }) {
  const dialog = byId('message-dialog');
  byId('message-title').textContent = title ?? '';
  byId('message-title').hidden = !title;
  byId('message-text').textContent = message;
  byId('message-actions').replaceChildren(
    ...actions.map(({ label, value, primary }) =>
      h('button', { type: 'button', class: primary ? 'button filled' : 'button text', onclick: () => dialog.close(value) }, label),
    ),
  );
  return new Promise((resolve) => {
    dialog.returnValue = '';
    dialog.addEventListener('close', () => resolve(dialog.returnValue), { once: true });
    dialog.showModal();
  });
}

export async function showAlert({ title, message }) {
  await showMessage({ title, message, actions: [{ label: t('ok'), value: 'ok', primary: true }] });
}

export async function showConfirm({ message, confirmLabel }) {
  const result = await showMessage({
    message,
    actions: [
      { label: t('cancel'), value: 'cancel' },
      { label: confirmLabel, value: 'confirm', primary: true },
    ],
  });
  return result === 'confirm';
}
