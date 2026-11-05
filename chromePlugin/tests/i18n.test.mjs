// 다국어 규칙 (DESIGN §2.2, §5.2). 메시지와 코드가 어긋나면 여기서 잡는다.
import assert from 'node:assert/strict';
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { after, beforeEach, describe, test } from 'node:test';

import { ErrorCode } from '../js/domain/errors.js';
import { LayoutDirection } from '../js/domain/layout_direction.js';
import { PAPERS } from '../js/domain/paper.js';
import { setTranslator, t } from '../js/ui/i18n.js';
import { APP_NAME, appTitle, destinationLabel, directionText, errorMessage, paperLabel, previewNote, saveLocationText, statusLabel } from '../js/ui/labels.js';
import { LOCALES, loadMessages, root, translatorFor } from './i18n_helper.mjs';

const read = (path) => readFileSync(join(root, path), 'utf8');
const messages = Object.fromEntries(LOCALES.map((locale) => [locale, loadMessages(locale)]));
const keys = Object.keys(messages.en);

function listFiles(dir) {
  return readdirSync(join(root, dir)).flatMap((name) => {
    const path = join(dir, name);
    return statSync(join(root, path)).isDirectory() ? listFiles(path) : [path];
  });
}

const codeFiles = ['background.js', ...listFiles('js')];

/** 주석을 뺀 코드. 문자열 안의 //는 프로토콜 표기뿐이라 URL 모양만 살린다. */
const withoutComments = (source) => source.replace(/\/\*[\s\S]*?\*\//g, '').replace(/(^|[^:'"`])\/\/.*$/gm, '$1');

const HANGUL = /[가-힣]/;
const placeholdersOf = (message) => [...new Set(message.match(/\$[1-9]/g) ?? [])].sort();

describe('로캘 파일', () => {
  test('언어 폴더는 정해진 14개다 (포르투갈어 2종 포함 13개 언어)', () => {
    assert.deepEqual(readdirSync(join(root, '_locales')).sort(), [...LOCALES].sort());
  });
  test('default_locale 폴더가 있다', () => {
    assert.equal(JSON.parse(read('manifest.json')).default_locale, 'en');
    assert.ok(statSync(join(root, '_locales', 'en', 'messages.json')).size > 0);
  });
  for (const locale of LOCALES) {
    test(`${locale}: 키가 English와 똑같다`, () => {
      assert.deepEqual(Object.keys(messages[locale]).sort(), [...keys].sort());
    });
    test(`${locale}: 자리표시 값이 English와 똑같다`, () => {
      for (const key of keys) {
        assert.deepEqual(placeholdersOf(messages[locale][key].message), placeholdersOf(messages.en[key].message), key);
      }
    });
    test(`${locale}: 메시지 형식이 chrome.i18n에 맞다`, () => {
      for (const [key, entry] of Object.entries(messages[locale])) {
        assert.match(key, /^[a-z0-9_]+$/, key);
        assert.equal(typeof entry.message, 'string', key);
        assert.equal(entry.placeholders, undefined, `${key}: 값은 $1 형식으로만 넘긴다`);
        // $ 뒤에는 1~9만 온다. 다른 $는 Chrome이 지워 버린다.
        assert.doesNotMatch(entry.message.replace(/\$[1-9]/g, ''), /\$/, key);
      }
    });
    test(`${locale}: 빈 번역이 없다`, () => {
      for (const key of keys) {
        if (key === 'app_subtitle' && locale === 'en') continue; // English는 부제가 없다 (DESIGN §2.2)
        assert.notEqual(messages[locale][key].message.trim(), '', key);
      }
    });
    test(`${locale}: 설명은 Chrome 상한 132자 이내다`, () => {
      assert.ok(messages[locale].ext_description.message.length <= 132);
    });
    test(`${locale}: html_lang이 폴더 이름과 맞다`, () => {
      assert.equal(messages[locale].html_lang.message, locale.replace('_', '-'));
    });
  }
  test('한국어 밖의 언어에 한글이 남아 있지 않다', () => {
    for (const locale of LOCALES.filter((l) => l !== 'ko')) {
      for (const key of keys) assert.doesNotMatch(messages[locale][key].message, HANGUL, `${locale}/${key}`);
    }
  });
  test('English가 그대로 남은 번역이 없다 (같아도 되는 말은 목록에 적는다)', () => {
    const everywhere = new Set([
      'paper_a4', 'paper_a3', 'paper_a5', 'paper_b4', 'paper_b5', 'paper_letter', 'paper_legal',
      'percent_value', 'mail_subject', 'ok',
    ]);
    const sameInLocale = {
      // 프랑스어와 포르투갈어·스페인어에서 English와 철자가 같은 말이다.
      fr: ['setting_orientation', 'orientation_portrait', 'preview_page_label', 'history_count'],
      es: ['setting_color', 'color_color'],
      id: ['crop_title', 'setting_padding'],
    };
    for (const locale of LOCALES.filter((l) => l !== 'en')) {
      const same = keys.filter(
        (key) =>
          !everywhere.has(key) &&
          !(sameInLocale[locale] ?? []).includes(key) &&
          messages[locale][key].message === messages.en[key].message,
      );
      assert.deepEqual(same, [], locale);
    }
  });
  test('브라질 포르투갈어와 유럽 포르투갈어의 낱말이 섞이지 않는다', () => {
    for (const key of keys) {
      const brazil = messages.pt_BR[key].message;
      const portugal = messages.pt_PT[key].message;
      assert.doesNotMatch(brazil, /ficheiro|\bpartilh|transferi|ecrã/i, `pt_BR/${key}`); // compartilhar에도 partilh가 들어 있다
      assert.doesNotMatch(portugal, /arquivo|compartilh|baixar|baixad|salv[ao]|\bvocê\b/i, `pt_PT/${key}`);
    }
  });
  test('간체와 번체가 섞이지 않는다', () => {
    for (const key of keys) {
      assert.doesNotMatch(messages.zh_CN[key].message, /檔|儲|圖|選|複|載|擇|關|輸|設定/, `zh_CN/${key}`);
      assert.doesNotMatch(messages.zh_TW[key].message, /档|储|图|选|复|载|择|关|输|设置/, `zh_TW/${key}`);
    }
  });
});

describe('한국어 문구는 기존 그대로다', () => {
  // 이전 코드(app.html, js/)에 있던 문장을 그대로 옮겨 적었다.
  const unchanged = {
    add: '추가',
    clear: '비우기',
    empty_title: '합칠 이미지를 2장 이상 골라 주세요',
    pick_files: '이미지·PDF 선택',
    drop_hint: 'JPEG, PNG, WebP, PDF 파일을 이 화면에 끌어다 놓아도 됩니다.',
    setting_paper: '용지',
    setting_orientation: '용지 방향',
    orientation_portrait: '세로',
    orientation_landscape: '가로',
    setting_color: '색상',
    color_color: '컬러',
    color_gray: '흑백',
    save_png: 'PNG 저장',
    save_pdf: 'PDF 저장',
    share: '공유',
    save_hint: '2장 이상 골라야 저장할 수 있습니다.',
    save_privacy_note: '파일은 이 PC 밖으로 나가지 않습니다.', // 앞 문장은 '변경' 때문에 save_location_*으로 나뉘었다
    drop_overlay: '여기에 놓으면 목록에 추가합니다',
    progress_hint: '이미지가 크면 수십 초 걸릴 수 있습니다.',
    progress_keep_tab: '끝날 때까지 이 탭을 닫지 마세요.',
    share_format_title: '어떤 형식으로 공유할까요?',
    share_title: '파일을 만들었습니다',
    share_unavailable: '이 PC의 Chrome은 파일 공유 창을 지원하지 않습니다. 다운로드하거나 복사한 뒤 보내 주세요.',
    crop_title: '영역 편집',
    crop_loading: '이미지를 여는 중…',
    crop_reset: '전체 선택',
    crop_apply: '적용',
    history_title: '최근 기록',
    history_empty: '아직 저장한 적이 없습니다.',
    snack_max_images: '최대 $1장까지 담을 수 있습니다.',
    snack_unsupported: '$1개 파일은 지원하지 않는 형식이라 제외했습니다.',
    snack_over_limit: '최대 $1장까지 담을 수 있어 $2장만 추가했습니다.',
    clear_confirm: '선택한 이미지를 모두 목록에서 뺄까요?\n원본 파일은 지워지지 않습니다.',
    snack_saved: '브라우저 다운로드로 저장했습니다: $1',
    crashed_message: '이전 저장이 중간에 종료되었습니다. 저장이 끝날 때까지 앱을 켜 두고, 계속되면 이미지 수를 줄여 주세요.',
    item_drag_label: '$1번째 항목 순서 바꾸기. 위아래 화살표 키로 옮깁니다',
    progress_images: '이미지 처리 중 $1/$2',
    history_rate: '최근 $1일 성공률 $2% ($3/$4)',
    mail_body: '방금 내려받은 파일($1)을 이 메일에 첨부해 주세요.',
    // DESIGN §2.2에 적힌 새 문구
    setting_per_sheet: '용지당 이미지 수',
    setting_image_size: '이미지 크기',
    setting_padding: '여백',
    preview_summary: '총 $1페이지 · 용지당 $2개',
    folder_use_default: '기본 폴더 쓰기',
    folder_pick: '다른 폴더 고르기',
    progress_saving: '저장하는 중',
    error_folder_unavailable: '저장 폴더에 접근할 수 없습니다. 폴더를 다시 골라 주세요.',
  };
  for (const [key, expected] of Object.entries(unchanged)) {
    test(key, () => assert.equal(messages.ko[key].message, expected));
  }
});

describe('제목 (DESIGN §2.2)', () => {
  // 설계서 표를 그대로 옮겨 적었다.
  const subtitles = {
    ko: '이미지 합치기',
    en: '',
    ja: '画像結合',
    zh_CN: '图片合并',
    zh_TW: '圖片合併',
    es: 'Unir imágenes',
    fr: "Fusion d'images",
    de: 'Bilder zusammenfügen',
    pt_BR: 'Juntar imagens',
    pt_PT: 'Juntar imagens',
    ru: 'Объединение изображений',
    vi: 'Ghép ảnh',
    id: 'Gabung Gambar',
    th: 'รวมรูปภาพ',
  };
  after(() => setTranslator(null));
  for (const locale of LOCALES) {
    test(`${locale}: 부제와 문서 제목`, () => {
      setTranslator(translatorFor(locale));
      assert.equal(messages[locale].app_subtitle.message, subtitles[locale]);
      assert.equal(appTitle(), subtitles[locale] ? `Pic Merge ${subtitles[locale]}` : 'Pic Merge');
    });
  }
  test('이름은 모든 언어에서 Pic Merge다', () => {
    assert.equal(APP_NAME, 'Pic Merge');
    assert.equal(JSON.parse(read('manifest.json')).name, 'Pic Merge');
  });
  test('화면 문구로 쓰는 예전 이름이 없다', () => {
    for (const locale of LOCALES) {
      for (const key of keys) assert.doesNotMatch(messages[locale][key].message, /이미지합치기|Image Merger/, `${locale}/${key}`);
    }
  });
});

describe('코드가 쓰는 키', () => {
  const usedInCode = new Set();
  const dynamic = [];
  for (const path of codeFiles) {
    const source = withoutComments(read(path));
    for (const [, key] of source.matchAll(/(?<![\w.])t\(\s*'([^']+)'/g)) usedInCode.add(key);
    if (path.replaceAll('\\', '/') === 'js/ui/i18n.js') continue; // t 자신의 정의
    for (const match of source.matchAll(/(?<![\w.])t\(\s*(?!')([^\s)]+)/g)) dynamic.push(`${path}: ${match[0]}`);
  }
  const html = read('app.html');
  const usedInHtml = new Set([...html.matchAll(/data-i18n(?:-[a-z-]+)?="([^"]+)"/g)].map((match) => match[1]));
  const usedInManifest = new Set([...read('manifest.json').matchAll(/__MSG_(\w+)__/g)].map((match) => match[1]));
  const used = new Set([...usedInCode, ...usedInHtml, ...usedInManifest]);

  test('스캔이 실제로 무언가를 찾는다', () => {
    assert.ok(usedInCode.size > 50, `code ${usedInCode.size}`);
    assert.ok(usedInHtml.size > 30, `html ${usedInHtml.size}`);
    assert.deepEqual([...usedInManifest].sort(), ['ext_action_title', 'ext_description']);
  });
  test('키를 변수로 만들지 않는다. 그래야 아래 두 검사가 믿을 만하다', () => {
    assert.deepEqual(dynamic, []);
  });
  test('쓰는 키는 모두 메시지에 있다', () => {
    assert.deepEqual([...used].filter((key) => !keys.includes(key)), []);
  });
  test('메시지에 있는 키는 모두 쓰인다', () => {
    assert.deepEqual(keys.filter((key) => !used.has(key)), []);
  });
});

describe('화면 문구의 자리', () => {
  test('app.html에 보이는 글자가 없다: 제목의 Pic Merge뿐이다', () => {
    const body = read('app.html').replace(/<svg[\s\S]*?<\/svg>/g, '');
    const text = body
      .replace(/<!--[\s\S]*?-->/g, '')
      .replace(/<[^>]+>/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();
    assert.equal(text, 'Pic Merge');
  });
  test('app.html의 title·aria-label·alt 속성은 메시지로만 채운다', () => {
    const html = read('app.html');
    assert.doesNotMatch(html, /\s(title|aria-label)="/);
    assert.doesNotMatch(html, /\salt="[^"]+"/);
  });
  test('Domain과 Data에 화면 문구가 없다', () => {
    for (const path of [...listFiles('js/domain'), ...listFiles('js/data')]) {
      const source = withoutComments(read(path));
      assert.doesNotMatch(source, HANGUL, path);
      assert.doesNotMatch(source, /(?<![\w.])t\(\s*'/, path);
      assert.doesNotMatch(source, /from '[^']*\/ui\//, path);
    }
  });
  test('UI 코드에 한글 문구가 없다. 예전 기록의 표식 둘만 예외다', () => {
    for (const path of ['js/app.js', ...listFiles('js/ui')]) {
      const source = withoutComments(read(path));
      const found = [...source.matchAll(/'[^'\n]*[가-힣][^'\n]*'|`[^`]*[가-힣][^`]*`/g)].map((m) => m[0]);
      const allowed = path.replaceAll('\\', '/') === 'js/ui/labels.js' ? ["'공유'", "'다운로드'"] : [];
      assert.deepEqual(found, allowed, path);
    }
  });
  test('시험하는 모듈은 불러올 때 chrome을 건드리지 않는다', () => {
    for (const path of ['js/ui/i18n.js', 'js/ui/labels.js']) {
      for (const line of withoutComments(read(path)).split('\n')) {
        if (/^\S/.test(line) && !line.startsWith('const chromeTranslator')) assert.doesNotMatch(line, /\bchrome\./, `${path}: ${line}`);
      }
    }
  });
});

describe('코드를 문구로 옮기기', () => {
  beforeEach(() => setTranslator(translatorFor('en')));
  after(() => setTranslator(null));

  test('값을 넘기면 자리표시에 들어간다', () => {
    assert.equal(t('list_count', 3, 30), 'Selected images 3/30');
    setTranslator(translatorFor('ko'));
    assert.equal(t('list_count', 3, 30), '선택한 이미지 3/30');
  });
  test('chrome.i18n으로 값은 문자열 배열로 넘어간다', () => {
    const calls = [];
    setTranslator((key, substitutions) => {
      calls.push([key, substitutions]);
      return '';
    });
    t('list_count', 3, 30);
    assert.deepEqual(calls, [['list_count', ['3', '30']]]);
  });
  test('번역기를 넣지 않으면 부를 때 chrome.i18n을 쓴다', () => {
    setTranslator(null);
    const calls = [];
    globalThis.chrome = {
      i18n: {
        getMessage: (key, substitutions) => {
          calls.push([key, substitutions]);
          return 'from chrome';
        },
      },
    };
    try {
      assert.equal(t('add'), 'from chrome');
      assert.deepEqual(calls, [['add', []]]);
    } finally {
      delete globalThis.chrome;
    }
  });
  test('English 오류 문구', () => {
    assert.equal(errorMessage('corrupt_file', 3), 'Image file 3 is corrupted.');
    assert.equal(errorMessage('corrupt_file'), 'An image file is corrupted.');
    assert.equal(errorMessage('no_such_code'), 'An unknown error occurred.');
  });
  test('모든 오류 코드가 문구를 갖는다', () => {
    for (const locale of LOCALES) {
      setTranslator(translatorFor(locale));
      const unknown = errorMessage(ErrorCode.unknown);
      assert.notEqual(unknown, '');
      for (const code of Object.values(ErrorCode)) {
        assert.notEqual(errorMessage(code), '', `${locale}/${code}`);
        assert.notEqual(errorMessage(code, 2), '', `${locale}/${code}`);
        if (code !== ErrorCode.unknown) assert.notEqual(errorMessage(code), unknown, `${locale}/${code}`);
      }
    }
  });
  test('용지 이름', () => {
    assert.deepEqual(PAPERS.map((p) => paperLabel(p.code)), ['A4', 'A3', 'A5', 'B4', 'B5', 'Letter', 'Legal', 'Original size']);
  });
  test('기록 상태', () => {
    assert.equal(statusLabel('success'), 'Success');
    assert.equal(statusLabel('crashed'), 'Crashed');
    assert.equal(statusLabel('new_status'), 'new_status'); // 모르는 값은 그대로 보여 준다
  });
  test('저장 위치 문구', () => {
    assert.equal(saveLocationText(null), "Save folder: browser's download folder");
    assert.equal(saveLocationText('Photos'), 'Save folder: Photos');
    setTranslator(translatorFor('ko'));
    assert.equal(saveLocationText(null), '저장 폴더: 브라우저 다운로드 폴더');
    assert.equal(saveLocationText('사진'), '저장 폴더: 사진');
  });
  test('폴더 오류 문구', () => {
    assert.equal(errorMessage('folder_unavailable'), "Can't access the save folder. Please choose a folder again.");
    setTranslator(translatorFor('ko'));
    assert.equal(errorMessage('folder_unavailable'), '저장 폴더에 접근할 수 없습니다. 폴더를 다시 골라 주세요.');
  });
  test('고른 폴더의 기록은 이름을 그대로 보여 준다. 이름이 표식과 같아도 번역하지 않는다', () => {
    assert.equal(destinationLabel('Photos', true), 'Photos');
    assert.equal(destinationLabel('download', true), 'download');
    assert.equal(destinationLabel('share', true), 'share');
  });
  test('기록 표식: 이전 버전이 한국어로 남긴 표식도 사용자 언어로 보여 준다', () => {
    assert.equal(destinationLabel('share'), 'Share');
    assert.equal(destinationLabel('download'), 'Download');
    assert.equal(destinationLabel('공유'), 'Share');
    assert.equal(destinationLabel('다운로드'), 'Download');
    setTranslator(translatorFor('ko'));
    assert.equal(destinationLabel('share'), '공유');
    assert.equal(destinationLabel('download'), '다운로드');
  });
  test('방향 문구', () => {
    assert.equal(directionText(LayoutDirection.horizontal), 'Auto: side by side (left → right)');
    assert.equal(directionText(LayoutDirection.vertical), 'Auto: stacked (top → bottom)');
  });
  test('미리보기 안내는 PNG 방향과 PDF에 선이 없다는 것을 알린다', () => {
    assert.match(previewNote(LayoutDirection.horizontal, true), /left to right.*gray line.*PDF.*each page.*without lines/);
    assert.match(previewNote(LayoutDirection.vertical, true), /top to bottom.*gray line.*PDF.*each page.*without lines/);
    assert.match(previewNote(LayoutDirection.vertical, false), /PNG preview.*gray line.*PDF.*one page per image.*without lines/);
    setTranslator(translatorFor('ko'));
    assert.match(previewNote(LayoutDirection.horizontal, true), /왼쪽에서 오른쪽.*회색 선.*PDF는 페이지별로 저장되고 선이 없습니다/);
    assert.match(previewNote(LayoutDirection.vertical, true), /위에서 아래.*회색 선.*PDF는 페이지별로 저장되고 선이 없습니다/);
  });
  test('모든 언어의 안내가 PDF에 선이 없다고 알리고, 여백이 없다고 하지 않는다', () => {
    // PDF에도 페이지 여백이 있다 (DESIGN §2.1.3). 언어마다 선과 여백을 뜻하는 낱말.
    const words = {
      ko: ['선', '여백'],
      en: ['lines', 'margin'],
      ja: ['線', '余白'],
      zh_CN: ['线条', '边距'],
      zh_TW: ['線條', '留白'],
      es: ['lineas', 'margen'],
      fr: ['ligne', 'marge'],
      de: ['linien', 'rand'],
      pt_BR: ['linhas', 'marge'],
      pt_PT: ['linhas', 'marge'],
      ru: ['линий', 'пол'],
      vi: ['đường kẻ', 'lề'],
      id: ['garis', 'margin'],
      th: ['เส้น', 'ขอบ'],
    };
    // 악센트는 무시한다: 스페인어 líneas도 lineas로 찾는다.
    const plain = (text) => text.normalize('NFD').replace(/\p{M}/gu, '').toLowerCase();
    for (const locale of LOCALES) {
      const [line, margin] = words[locale].map(plain);
      for (const key of ['preview_note_horizontal', 'preview_note_vertical', 'preview_note_original']) {
        const afterPdf = plain(messages[locale][key].message.split('PDF').at(-1));
        assert.ok(afterPdf.includes(line), `${locale}/${key}: ${line}`);
        assert.ok(!afterPdf.includes(margin), `${locale}/${key}: ${margin}`);
      }
    }
  });
});
