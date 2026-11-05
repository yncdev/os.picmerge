// 확장의 규칙(DESIGN §5.2)을 파일 수준에서 확인한다.
import assert from 'node:assert/strict';
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { dirname, join, relative } from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const read = (path) => readFileSync(join(root, path), 'utf8');

function listFiles(dir) {
  return readdirSync(join(root, dir)).flatMap((name) => {
    const path = join(dir, name);
    return statSync(join(root, path)).isDirectory() ? listFiles(path) : [path];
  });
}

const ownCode = ['background.js', 'app.html', 'css/app.css', 'manifest.json', ...listFiles('js')];
const localeFiles = listFiles('_locales');

test('권한을 요청하지 않는다', () => {
  const manifest = JSON.parse(read('manifest.json'));
  assert.equal(manifest.manifest_version, 3);
  assert.deepEqual(manifest.permissions, []);
  assert.deepEqual(manifest.host_permissions, []);
  assert.equal(manifest.optional_permissions, undefined);
  assert.equal(manifest.content_scripts, undefined);
});

test('이름과 CSP', () => {
  const manifest = JSON.parse(read('manifest.json'));
  assert.equal(manifest.name, 'Pic Merge'); // 모든 언어에서 같다. __MSG_로 옮기지 않는다 (DESIGN §2.2)
  assert.equal(manifest.default_locale, 'en');
  assert.equal(manifest.description, '__MSG_ext_description__');
  assert.equal(manifest.action.default_title, '__MSG_ext_action_title__');
  // pdf.js의 JBIG2·JPEG2000 디코더가 wasm이다. 원격 출처나 unsafe-eval은 없다.
  assert.equal(manifest.content_security_policy.extension_pages, "script-src 'self' 'wasm-unsafe-eval'; object-src 'self'");
  assert.equal(manifest.action.default_popup, undefined); // 아이콘을 누르면 탭을 연다
});

test('자체 코드는 원격 자원을 불러오지 않는다', () => {
  // SVG 네임스페이스는 URL 모양이지만 네트워크 요청이 아니다.
  const allowed = 'http://www.w3.org/2000/svg';
  for (const path of [...ownCode, ...localeFiles]) {
    const urls = read(path).match(/https?:\/\/[^\s'"`)]+/g) ?? [];
    assert.deepEqual(urls.filter((url) => url !== allowed), [], path);
  }
});

test('HTML에 인라인 스크립트와 인라인 이벤트가 없다 (MV3 CSP)', () => {
  const html = read('app.html');
  const scripts = [...html.matchAll(/<script\b([^>]*)>([\s\S]*?)<\/script>/g)];
  assert.ok(scripts.length > 0);
  for (const [, attrs, body] of scripts) {
    assert.match(attrs, /\bsrc=/);
    assert.equal(body.trim(), '');
  }
  assert.doesNotMatch(html, /\son[a-z]+\s*=/i);
});

test('파일 이름 같은 외부 값이 HTML로 해석되지 않는다', () => {
  for (const path of listFiles('js')) {
    assert.doesNotMatch(read(path), /\.innerHTML|\.outerHTML|insertAdjacentHTML|document\.write|\beval\(|new Function/, path);
  }
});

test('카메라 UI가 없다', () => {
  assert.doesNotMatch(read('app.html'), /카메라|capture=|getUserMedia/);
  for (const path of listFiles('js')) assert.doesNotMatch(read(path), /getUserMedia|카메라/, path);
  assert.doesNotMatch(read('_locales/ko/messages.json'), /카메라/);
  assert.doesNotMatch(read('_locales/en/messages.json'), /camera/i);
});

test('자체 코드에 미완성 표시가 없다', () => {
  for (const path of ownCode) assert.doesNotMatch(read(path), /\b(TODO|FIXME|XXX)\b|placeholder/i, relative(root, path));
  // 번역에는 스페인어 todo('모두')가 있어 대문자 표시만 찾는다.
  for (const path of localeFiles) assert.doesNotMatch(read(path), /\b(TODO|FIXME|XXX)\b/, path);
});

test('필요한 pdf.js 파일을 모두 동봉했다', () => {
  const required = [
    'vendor/pdfjs/pdf.min.mjs',
    'vendor/pdfjs/pdf.worker.min.mjs',
    'vendor/pdfjs/LICENSE',
    'vendor/pdfjs/wasm/jbig2.wasm',
    'vendor/pdfjs/wasm/openjpeg.wasm',
    'vendor/pdfjs/wasm/qcms_bg.wasm',
    'vendor/pdfjs/iccs/CGATS001Compat-v2-micro.icc',
    'vendor/pdfjs/cmaps/UniKS-UTF16-H.bcmap',
    'vendor/pdfjs/cmaps/UniKS-UCS2-H.bcmap',
    'vendor/pdfjs/standard_fonts/LiberationSans-Regular.ttf',
  ];
  for (const path of required) assert.ok(statSync(join(root, path)).size > 0, path);
});

test('아이콘 파일이 매니페스트와 맞다', () => {
  const manifest = JSON.parse(read('manifest.json'));
  for (const path of Object.values(manifest.icons)) assert.ok(statSync(join(root, path)).size > 0, path);
});

test('NOTICE에 아이콘 출처와 pdf.js 표시가 있다', () => {
  const notice = read('NOTICE.md');
  // 아이콘을 이 프로젝트의 그림으로 바꿨다. Android 로봇 표시는 더 이상 맞지 않는다.
  assert.doesNotMatch(notice, /Android/);
  assert.match(notice, /이 프로젝트가 직접 그린 그림.*MIT 라이선스.*Tux.*Apple 로고가 아닙니다/);
  assert.match(notice, /Apache License/);
  assert.match(notice, /pdf\.js/i);
});

test('limits.js 숫자가 Flutter 앱(limits.dart)과 같다', () => {
  // 모바일 앱이 함께 있는 저장소에서만 확인할 수 있다.
  const dart = readFileSync(join(root, '..', 'lib', 'core', 'config', 'limits.dart'), 'utf8');
  const js = read('js/domain/limits.js');
  const pick = (source, name) => source.match(new RegExp(`\\b${name}\\s*=\\s*([0-9.]+)`))?.[1];
  const shared = [
    'kMinImages', 'kMaxImages', 'kMaxInputLongSide', 'kMaxCanvasPixels', 'kMaxOutputBytes', 'kPngMaxReencodes',
    'kPdfQualityHigh', 'kPdfQualityLow', 'kPdfBudgetRatio', 'kPdfShrinkFactor', 'kPdfMaxShrinks', 'kPdfPageLongSideMm',
    'kThumbnailLongSide', 'kThumbnailQuality', 'kHistoryLimit', 'kHistoryRateDays',
    'kCellGapPerMargin', 'kDividerRatio',
  ];
  for (const name of shared) {
    const value = pick(js, name);
    assert.ok(value, `${name} missing in limits.js`);
    assert.equal(Number(value), Number(pick(dart, name)), name);
  }
  // 이름이나 표기가 다른 값
  assert.equal(Number(pick(js, 'kDividerMinPx')), Number(pick(dart, 'kMinDividerPx')));
  assert.equal(js.match(/kDividerColor = '#([0-9A-F]{2})\1\1'/)?.[1], dart.match(/kDividerGray = 0x([0-9A-F]{2})/)?.[1]);
});
