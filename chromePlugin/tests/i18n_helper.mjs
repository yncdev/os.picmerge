// Node에서 chrome.i18n.getMessage와 같게 동작하는 번역기. 메시지는 실제 _locales 파일을 읽는다.
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

export const root = join(dirname(fileURLToPath(import.meta.url)), '..');

export const LOCALES = Object.freeze([
  'ko', 'en', 'ja', 'zh_CN', 'zh_TW', 'es', 'fr', 'de', 'pt_BR', 'pt_PT', 'ru', 'vi', 'id', 'th',
]);

export function loadMessages(locale) {
  return JSON.parse(readFileSync(join(root, '_locales', locale, 'messages.json'), 'utf8'));
}

/** 없는 키는 빈 문자열이다. $1~$9는 값으로, $$는 $로 바꾼다. */
export function translatorFor(locale) {
  const messages = loadMessages(locale);
  return (key, substitutions = []) =>
    (messages[key]?.message ?? '').replace(/\$(\$|[1-9])/g, (_, token) =>
      token === '$' ? '$' : (substitutions[Number(token) - 1] ?? ''),
    );
}
