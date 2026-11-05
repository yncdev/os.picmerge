// 화면 문구는 모두 _locales/의 메시지다 (DESIGN §5.2).
// chrome은 부를 때 찾는다. 단위 테스트는 setTranslator로 번역기를 넣어 Node에서 돈다.

let translator = null;

const chromeTranslator = (key, substitutions) => globalThis.chrome.i18n.getMessage(key, substitutions);

/** 테스트용. null을 주면 chrome.i18n으로 돌아간다. */
export function setTranslator(next) {
  translator = next;
}

/** 키는 항상 문자열 그대로 쓴다. 쓰지 않는 메시지를 테스트가 찾아내야 하기 때문이다. */
export function t(key, ...values) {
  return (translator ?? chromeTranslator)(key, values.map(String));
}

const ATTRIBUTES = Object.freeze([
  ['data-i18n-title', 'title'],
  ['data-i18n-aria-label', 'aria-label'],
  ['data-i18n-alt', 'alt'],
]);

/** app.html의 data-i18n 표시를 메시지로 채운다. */
export function applyTranslations(root = document) {
  for (const element of root.querySelectorAll('[data-i18n]')) {
    element.textContent = t(element.dataset.i18n);
  }
  for (const [marker, attribute] of ATTRIBUTES) {
    for (const element of root.querySelectorAll(`[${marker}]`)) {
      element.setAttribute(attribute, t(element.getAttribute(marker)));
    }
  }
}
