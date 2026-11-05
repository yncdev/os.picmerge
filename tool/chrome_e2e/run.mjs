// Pic Merge Chrome 확장 E2E. 실제 Chrome에 확장을 올려 화면을 조작하고 결과 파일을 픽셀 단위로 검사한다.
//
//   node tool/chrome_e2e/run.mjs            전체
//   node tool/chrome_e2e/run.mjs --quick    잡음 이미지 재인코딩과 언어 13개 반복을 뺀다
//   node tool/chrome_e2e/run.mjs --extension=<폴더>   chromePlugin 대신 그 폴더를 시험한다. 풀어 놓은 패키지에 쓴다
//   node tool/chrome_e2e/run.mjs --store-screenshots   스토어 스크린샷을 다시 만든다 (1280×800, 불투명 PNG)
//
// 확장 폴더 밖에 두어 배포물에 들어가지 않는다. 의존성이 없다 (Node 22.2 이상).
// 프로필과 시험 이미지는 OS 임시 폴더에 만들고 끝나면 지운다. 스크린샷과 결과 로그는 남긴다.
// 사용자의 Chrome 프로필과 파일은 건드리지 않고, 닫을 때는 여기서 띄운 프로세스만 닫는다.
//
// 확장 올리기: Chrome 137부터 정식 빌드는 --load-extension을 무시한다.
// 그래서 --remote-debugging-pipe --enable-unsafe-extension-debugging을 주고 CDP Extensions.loadUnpacked를 부른다.
//
// 기대 좌표는 확장 코드를 부르지 않고 손으로 계산했다. 계산은 각 검사의 주석에 있다.
import { randomBytes } from 'node:crypto';
import { copyFileSync, mkdirSync, mkdtempSync, readFileSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

import { launchChrome } from './cdp.mjs';
import { decodePng, encodePng, encodeRaw, encodeRgb, pixel, runsAlong } from './png.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const repo = resolve(here, '..', '..');
const extensionArgument = process.argv.find((arg) => arg.startsWith('--extension='))?.slice('--extension='.length);
const EXTENSION = extensionArgument ? resolve(extensionArgument) : join(repo, 'chromePlugin');
const QUICK = process.argv.includes('--quick');
const STORE_SCREENSHOTS = process.argv.includes('--store-screenshots');
const CHROME_PATH = process.env.CHROME_PATH || undefined;

const workDir = mkdtempSync(join(tmpdir(), 'picmerge-e2e-'));
const shotsDir = join(workDir, 'shots');
const imagesDir = join(workDir, 'images');
mkdirSync(shotsDir);
mkdirSync(imagesDir);

// ---- 결과 ----

let passed = 0;
let failed = 0;
const log = [];
function say(line) {
  log.push(line);
  console.log(line);
}
function ok(name, condition, detail = '') {
  if (condition) {
    passed++;
    say(`PASS ${name}`);
  } else {
    failed++;
    say(`FAIL ${name}${detail ? `: ${detail}` : ''}`);
  }
  return condition;
}
const equal = (name, actual, expected) => {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  return ok(name, a === e, `\n  actual   ${a}\n  expected ${e}`);
};

// ---- 시험 이미지 ----

const RED = [200, 30, 30];
const GREEN = [30, 160, 60];
const BLUE = [40, 60, 200];
const YELLOW = [230, 200, 40];
const MAGENTA = [170, 40, 170];
const hex = ([r, g, b]) => `#${[r, g, b].map((v) => v.toString(16).padStart(2, '0')).join('')}`;
const R = hex(RED);
const G = hex(GREEN);
const B = hex(BLUE);
const Y = hex(YELLOW);
const M = hex(MAGENTA);
const W = '#ffffff';
const D = '#d0d0d0'; // 구분선 (DESIGN §2.1.2)

function writeImage(name, bytes) {
  const path = join(imagesDir, name);
  writeFileSync(path, bytes);
  return path;
}

const solid = (name, color) => writeImage(`${name}.png`, encodePng(1200, 1600, () => color));
const files = {
  red: solid('red', RED),
  green: solid('green', GREEN),
  blue: solid('blue', BLUE),
  yellow: solid('yellow', YELLOW),
  magenta: solid('magenta', MAGENTA),
  // '원본 크기' 투명도 확인: 위 절반은 불투명, 아래 절반은 투명. 1000×800이라 가로형이다.
  halfClear: writeImage('half_clear.png', encodePng(1000, 800, (x, y) => (y < 400 ? [...MAGENTA, 255] : [0, 0, 0, 0]))),
  tall: writeImage('tall.png', encodePng(1000, 2000, () => BLUE)),
  broken: writeImage('broken.png', Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), randomBytes(2000)])),
};

/** 압축이 거의 안 되는 큰 이미지. 결과가 20MB를 넘어 다시 인코딩하게 만든다. */
function noiseImage(name, size) {
  const row = size * 4 + 1;
  const raw = Buffer.alloc(row * size);
  const noise = randomBytes(row * size);
  for (let y = 0; y < size; y++) {
    const start = y * row;
    raw[start] = 0;
    for (let i = 1; i < row; i++) raw[start + i] = (i & 3) === 0 ? 255 : noise[start + i];
  }
  return writeImage(name, encodeRaw(size, size, raw, 1));
}

/** 시험용 2페이지 PDF. 확장의 PDF 생성기로 만들고, 동봉한 pdf.js로 입력 경로를 탄다. */
async function samplePdf() {
  const { buildPdf } = await import(pathToFileURL(join(EXTENSION, 'js', 'domain', 'pdf_writer.js')).href);
  const jpeg = Uint8Array.from(
    Buffer.from(
      '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAUDBAQEAwUEBAQFBQUGBwwIBwcHBw8LCwkMEQ8SEhEPERETFhwXExQaFRERGCEYGh0dHx8fExciJCIeJBweHx7/2wBDAQUFBQcGBw4ICA4eFBEUHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh7/wAARCAACAAQDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwDzWiiivmT+hj//2Q==',
      'base64',
    ),
  );
  const page = { pageWidthPt: 200, pageHeightPt: 100, images: [{ jpeg, pixelWidth: 4, pixelHeight: 2, xPt: 0, yPt: 0, widthPt: 200, heightPt: 100 }] };
  return writeImage('two_pages.pdf', Buffer.from(buildPdf([page, page])));
}

// ---- 브라우저 세션 ----

class Session {
  /** @param {{lang:string, width?:number, height?:number}} options */
  static async open({ lang, width = 1280, height = 900 }) {
    const session = new Session();
    session.lang = lang;
    session.profile = mkdtempSync(join(workDir, 'profile-'));
    session.downloadDir = mkdtempSync(join(workDir, 'downloads-'));
    session.browser = launchChrome({ chromePath: CHROME_PATH, userDataDir: session.profile, lang, width, height });
    session.downloads = new Map();
    session.errors = [];
    session.dialogs = [];
    session.requests = [];
    const { browser } = session;
    browser.on('Network.requestWillBeSent', ({ request }) => session.requests.push(request.url));
    // 떠날지 묻는 창 같은 것이 뜨면 기록하고 머문다. 답하지 않으면 페이지가 멈춘다.
    browser.on('Page.javascriptDialogOpening', ({ type, message }) => {
      session.dialogs.push({ type, message });
      session.send('Page.handleJavaScriptDialog', { accept: false }).catch(() => {});
    });
    browser.on('Browser.downloadWillBegin', ({ guid, suggestedFilename }) => {
      session.downloads.set(guid, { guid, name: suggestedFilename, state: 'started' });
    });
    browser.on('Browser.downloadProgress', ({ guid, state }) => {
      const entry = session.downloads.get(guid);
      if (entry) entry.state = state;
    });
    browser.on('Runtime.exceptionThrown', ({ exceptionDetails }) => {
      session.errors.push(exceptionDetails.exception?.description ?? exceptionDetails.text);
    });
    browser.on('Log.entryAdded', ({ entry }) => {
      if (entry.level === 'error') session.errors.push(`${entry.source}: ${entry.text}`);
    });

    await browser.send('Browser.setDownloadBehavior', { behavior: 'allowAndName', downloadPath: session.downloadDir, eventsEnabled: true });
    const { id } = await browser.send('Extensions.loadUnpacked', { path: EXTENSION });
    session.extensionId = id;
    const { targetId } = await browser.send('Target.createTarget', { url: `chrome-extension://${id}/app.html` });
    const { sessionId } = await browser.send('Target.attachToTarget', { targetId, flatten: true });
    session.sessionId = sessionId;
    await session.send('Page.enable');
    await session.send('Runtime.enable');
    await session.send('Log.enable');
    await session.send('Network.enable');
    await session.send('DOM.enable');
    await session.send('CSS.enable');
    await session.resize(width, height);
    await session.waitFor('앱 시작', () => document.getElementById('paper-select')?.options.length > 0 && document.getElementById('save-location').textContent !== '');
    return session;
  }

  send(method, params = {}) {
    return this.browser.send(method, params, this.sessionId);
  }

  async call(fn, ...args) {
    const expression = `(${fn})(...${JSON.stringify(args)})`;
    const { result, exceptionDetails } = await this.send('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true });
    if (exceptionDetails) throw new Error(`page error: ${exceptionDetails.exception?.description ?? exceptionDetails.text}`);
    return result.value;
  }

  async waitFor(what, fn, { timeout = 60000, args = [] } = {}) {
    const end = Date.now() + timeout;
    for (;;) {
      if (await this.call(fn, ...args)) return;
      if (Date.now() > end) throw new Error(`timed out waiting for ${what}`);
      await new Promise((r) => setTimeout(r, 40));
    }
  }

  /** 창 크기를 바꾸고 ResizeObserver까지 끝나도록 두 프레임을 기다린다. 그 전에 재면 옛 크기가 나온다. */
  async resize(width, height) {
    await this.send('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile: false });
    await this.call(() => new Promise((done) => requestAnimationFrame(() => requestAnimationFrame(done))));
  }

  async screenshot(name) {
    const { data } = await this.send('Page.captureScreenshot', { format: 'png' });
    const path = join(shotsDir, `${name}.png`);
    writeFileSync(path, Buffer.from(data, 'base64'));
    return path;
  }

  /** 실제 마우스 입력으로 누른다. 사용자 제스처가 되어 연속 다운로드가 막히지 않는다. */
  async click(selector) {
    // 사람은 한 프레임 안에 두 번 누를 수 없다. 대화 상자의 close 이벤트도 다음 프레임에 온다.
    await this.call(() => new Promise((done) => requestAnimationFrame(() => requestAnimationFrame(done))));
    const box = await this.call((s) => {
      const el = document.querySelector(s);
      if (!el) return null;
      el.scrollIntoView({ block: 'center', inline: 'center' });
      const r = el.getBoundingClientRect();
      return { x: r.left + r.width / 2, y: r.top + r.height / 2, disabled: el.disabled === true };
    }, selector);
    if (!box) throw new Error(`no element: ${selector}`);
    if (box.disabled) throw new Error(`disabled: ${selector}`);
    await this.mouse('mousePressed', box.x, box.y);
    await this.mouse('mouseReleased', box.x, box.y);
  }

  mouse(type, x, y, buttons = type === 'mouseReleased' ? 0 : 1) {
    return this.send('Input.dispatchMouseEvent', { type, x, y, button: type === 'mouseMoved' && !buttons ? 'none' : 'left', buttons, clickCount: type === 'mouseMoved' ? 0 : 1 });
  }

  async addFiles(paths, expectedCount) {
    const { root } = await this.send('DOM.getDocument');
    const { nodeId } = await this.send('DOM.querySelector', { nodeId: root.nodeId, selector: '#file-input' });
    await this.send('DOM.setFileInputFiles', { nodeId, files: paths });
    await this.waitFor(
      `목록 ${expectedCount}개`,
      (count) => document.querySelectorAll('#item-list .item').length === count && document.getElementById('add-progress').hidden,
      { args: [expectedCount] },
    );
  }

  async clearList() {
    if ((await this.call(() => document.querySelectorAll('#item-list .item').length)) === 0) return;
    await this.click('#clear-button');
    await this.waitFor('확인 창', () => document.getElementById('message-dialog').open);
    await this.click('#message-actions .button.filled');
    await this.waitFor('목록 비움', () => document.querySelectorAll('#item-list .item').length === 0);
  }

  setSelect(id, value) {
    return this.call((i, v) => {
      const el = document.getElementById(i);
      el.value = String(v);
      el.dispatchEvent(new Event('change', { bubbles: true }));
      return el.value;
    }, id, value);
  }

  /** 출력 설정을 한 번에 맞춘다. 기본값으로 돌아간 뒤 필요한 것만 바꾼다. */
  async settings({ paper = 'a4', orientation = 'portrait', perSheet = 1, imageSize = 100, padding = 5, color = 'color' } = {}) {
    await this.setSelect('paper-select', 'a4');
    await this.click(`input[name="orientation"][value="${orientation}"] + span`);
    await this.click(`input[name="color"][value="${color}"] + span`);
    await this.click(`input[name="padding"][value="${padding}"] + span`);
    await this.setSelect('per-sheet-select', perSheet);
    await this.setSelect('image-size-select', imageSize);
    await this.setSelect('paper-select', paper);
  }

  /** 버튼을 눌러 저장하고 끝날 때까지 기다린다. 오류 창이 뜨면 바로 실패한다. */
  async save(buttonSelector, { timeout = 240000 } = {}) {
    const before = new Set(this.downloads.keys());
    await this.click(buttonSelector);
    const end = Date.now() + timeout;
    for (;;) {
      const fresh = [...this.downloads.values()].find((d) => !before.has(d.guid));
      if (fresh?.state === 'completed') {
        await this.waitFor('저장 끝', () => !document.getElementById('progress-dialog').open && !document.getElementById('save-png').disabled);
        const path = join(this.downloadDir, fresh.guid);
        return { name: fresh.name, path, bytes: readFileSync(path), size: statSync(path).size };
      }
      if (fresh?.state === 'canceled') throw new Error(`download canceled: ${fresh.name}`);
      const alert = await this.call(() => {
        const dialog = document.getElementById('message-dialog');
        return dialog.open ? `${document.getElementById('message-title').textContent}: ${document.getElementById('message-text').textContent}` : null;
      });
      if (alert) throw new Error(`error dialog: ${alert}`);
      if (Date.now() > end) throw new Error(`timed out saving via ${buttonSelector}`);
      await new Promise((r) => setTimeout(r, 100));
    }
  }

  /** 확장 밖으로 나간 요청. 없어야 한다. */
  externalRequests() {
    const local = `chrome-extension://${this.extensionId}/`;
    return this.requests.filter((url) => !url.startsWith(local) && !url.startsWith('blob:') && !url.startsWith('data:'));
  }

  /** 최근 기록. 최신이 앞이다. */
  history() {
    return this.call(() => JSON.parse(localStorage.getItem('picmerge.sessions') ?? '[]'));
  }

  /** 고른 폴더에 저장하고 끝날 때까지 기다린다. 다운로드가 없어 기록으로 끝을 안다. */
  async saveToFolder(buttonSelector, { timeout = 120000 } = {}) {
    const [latest] = await this.history();
    await this.click(buttonSelector);
    await this.waitFor(
      '폴더 저장 끝',
      (previous) => {
        const [record] = JSON.parse(localStorage.getItem('picmerge.sessions') ?? '[]');
        return record && record.id !== previous && record.status !== 'running' && !document.getElementById('progress-dialog').open && !document.getElementById('save-png').disabled;
      },
      { timeout, args: [latest?.id ?? null] },
    );
    const [record] = await this.history();
    return record;
  }

  /** 저장 폴더 변경 창을 '변경' 버튼으로 연다. */
  async openFolderDialog() {
    await this.click('#change-folder');
    await this.waitFor('저장 폴더 창', () => document.getElementById('folder-dialog').open);
  }

  async closeFolderDialog() {
    await this.click('#folder-cancel');
    await this.waitFor('저장 폴더 창 닫힘', () => !document.getElementById('folder-dialog').open);
  }

  /** 선택기를 OPFS 폴더로 바꿔 고른다. 헤드리스에는 진짜 선택 창이 없다. */
  async pickFolder(name) {
    await this.call(stubPicker, name);
    await this.openFolderDialog();
    await this.click('#folder-pick');
    await this.waitFor('폴더 고름', () => !document.getElementById('folder-dialog').open);
  }

  async useDefaultFolder() {
    await this.openFolderDialog();
    await this.click('#folder-use-default');
    await this.waitFor('기본 폴더', () => !document.getElementById('folder-dialog').open);
  }

  /** 다시 불러온다. 항목은 사라지고 저장 폴더만 남는다. */
  async reload({ timeout = 20000 } = {}) {
    let stop;
    let timer;
    const loaded = new Promise((resolve, reject) => {
      stop = this.browser.on('Page.loadEventFired', resolve);
      // 떠나기 확인 창에 머물기로 답하면 load가 오지 않는다. 멈추지 말고 실패한다.
      timer = setTimeout(() => reject(new Error(`reload did not finish; dialogs ${JSON.stringify(this.dialogs)}`)), timeout);
    });
    try {
      await this.send('Page.reload');
      await loaded;
    } finally {
      clearTimeout(timer);
      stop();
    }
    // 저장 위치는 기억한 폴더를 읽은 뒤에 나타난다.
    await this.waitFor('다시 시작', () => document.getElementById('paper-select')?.options.length > 0 && document.getElementById('save-location').textContent !== '');
  }

  async close() {
    await this.browser.close();
    for (const dir of [this.profile, this.downloadDir]) rmSync(dir, { recursive: true, force: true, maxRetries: 8, retryDelay: 300 });
  }
}

// ---- 페이지 안에서 실행하는 검사 ----

/**
 * 보이는 요소가 창 밖으로 나가거나 글자가 잘리는지 본다. 가로와 세로를 모두 본다.
 * 세로는 끝까지 스크롤해서 볼 수 있는지가 기준이다. 자르기만 하고 스크롤되지 않는 조상이 있으면 볼 방법이 없다.
 * 미리보기 페이지는 가로 스크롤이 설계라 가로는 보지 않는다.
 */
function auditOverflow() {
  const width = document.documentElement.clientWidth;
  const height = document.documentElement.clientHeight;
  const documentScrolls = document.documentElement.scrollHeight > height;
  const problems = [];
  if (document.documentElement.scrollWidth > width) problems.push(`page scrollWidth ${document.documentElement.scrollWidth} > ${width}`);

  const unreachableBelow = (el) => {
    let bottom = el.getBoundingClientRect().bottom;
    for (let parent = el.parentElement; parent && parent !== document.documentElement; parent = parent.parentElement) {
      const overflow = getComputedStyle(parent).overflowY;
      const parentBottom = parent.getBoundingClientRect().bottom;
      if (overflow === 'auto' || overflow === 'scroll') bottom = Math.min(bottom, parentBottom); // 여기서는 스크롤로 닿는다. 이 조상이 보이는지 본다.
      else if ((overflow === 'hidden' || overflow === 'clip') && bottom > parentBottom + 1) return Math.round(bottom - parentBottom);
    }
    return bottom > height + 1 && !documentScrolls ? Math.round(bottom - height) : 0;
  };

  const openDialogs = [...document.querySelectorAll('dialog[open]')];
  const scope = openDialogs.length ? openDialogs : [document.body];
  for (const root of scope) {
    for (const el of root.querySelectorAll('h1, h2, p, button, label, legend, select, small, span, li, figcaption, .setting, .button')) {
      if (el.closest('svg') || !el.getClientRects().length) continue;
      if (!openDialogs.length && el.closest('dialog')) continue;
      const box = el.getBoundingClientRect();
      const name = `${el.tagName.toLowerCase()}#${el.id || el.className || ''} "${(el.textContent || '').trim().slice(0, 24)}"`;
      if (el.textContent.trim()) {
        const below = unreachableBelow(el);
        if (below > 0) problems.push(`${name} ${below}px below reach`);
      }
      if (el.closest('.preview-pages')) continue;
      if (box.right > width + 0.5 || box.left < -0.5) problems.push(`${name} x ${Math.round(box.left)}..${Math.round(box.right)} outside ${width}`);
      // 파일 이름만 말줄임이 설계다.
      if (el.matches('.name, .crop-name')) continue;
      if (el.scrollWidth > el.clientWidth + 1 && el.clientWidth > 0 && getComputedStyle(el).display !== 'inline') {
        problems.push(`${name} text ${el.scrollWidth} > box ${el.clientWidth}`);
      }
    }
  }
  return problems;
}

/** 막대 안의 글자와 실제 배경의 명암비. 투명도까지 본다. */
function auditBarContrast() {
  const parse = (value) => {
    const m = value.match(/rgba?\(([^)]+)\)/);
    const [r, g, b, a = 1] = m[1].split(/[ ,/]+/).filter(Boolean).map(Number);
    return { r, g, b, a };
  };
  const linear = (c) => {
    const v = c / 255;
    return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4;
  };
  const luminance = ({ r, g, b }) => 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b);
  const backgroundOf = (el) => {
    for (let node = el; node; node = node.parentElement) {
      const color = parse(getComputedStyle(node).backgroundColor);
      if (color.a === 1) return color;
    }
    return { r: 255, g: 255, b: 255, a: 1 };
  };
  const opacityOf = (el) => {
    let value = 1;
    for (let node = el; node; node = node.parentElement) value *= Number(getComputedStyle(node).opacity);
    return value;
  };
  const results = [];
  for (const el of document.querySelectorAll('.topbar h1, .topbar small, .topbar .icon-button, .save-bar .note, .save-bar .button, .save-bar .bar-link')) {
    if (!el.getClientRects().length) continue;
    const foreground = parse(getComputedStyle(el).color);
    const background = backgroundOf(el);
    const [light, dark] = [luminance(foreground), luminance(background)].sort((a, b) => b - a);
    results.push({
      name: `${el.tagName.toLowerCase()}#${el.id || el.className}${el.disabled ? ':disabled' : ''}`,
      ratio: Math.round(((light + 0.05) / (dark + 0.05)) * 100) / 100,
      opacity: opacityOf(el),
    });
  }
  return results;
}

function readPreview() {
  const sheets = [...document.querySelectorAll('#preview-pages .preview-sheet')];
  const percent = (value) => Math.round(Number.parseFloat(value) * 100) / 100;
  const box = document.getElementById('preview-box');
  return {
    sheets: sheets.length,
    numbers: [...document.querySelectorAll('#preview-pages .preview-number')].map((n) => n.textContent),
    imagesPerSheet: sheets.map((s) => s.querySelectorAll('img').length),
    firstImages: sheets.map((s) =>
      [...s.querySelectorAll('img')].map((i) => [percent(i.style.left), percent(i.style.top), percent(i.style.width), percent(i.style.height)]),
    ),
    aspect: sheets.length ? sheets[0].getBoundingClientRect().width / sheets[0].getBoundingClientRect().height : null,
    summary: document.getElementById('preview-direction').hidden ? null : document.getElementById('preview-direction').textContent,
    note: document.getElementById('preview-note').hidden ? null : document.getElementById('preview-note').textContent,
    gray: [...document.querySelectorAll('#preview-pages *')].filter((el) => getComputedStyle(el).backgroundColor === 'rgb(208, 208, 208)').length,
    extraElements: [...document.querySelectorAll('#preview-pages .preview-sheet > *')].filter((el) => el.tagName !== 'IMG').length,
    grayscale: document.getElementById('preview-pages').classList.contains('grayscale'),
    scrollable: box.scrollWidth > box.clientWidth,
  };
}

/** 동봉한 pdf.js로 Chrome 안에서 페이지를 그려 픽셀을 읽는다. */
async function renderPdfPage(base64, pageNumber, scale) {
  const pdfjs = await import(chrome.runtime.getURL('vendor/pdfjs/pdf.min.mjs'));
  pdfjs.GlobalWorkerOptions.workerSrc = chrome.runtime.getURL('vendor/pdfjs/pdf.worker.min.mjs');
  const data = Uint8Array.from(atob(base64), (c) => c.charCodeAt(0));
  const task = pdfjs.getDocument({ data, isEvalSupported: false, verbosity: 0 });
  try {
    const doc = await task.promise;
    const page = await doc.getPage(pageNumber);
    const viewport = page.getViewport({ scale });
    const canvas = document.createElement('canvas');
    canvas.width = Math.floor(viewport.width);
    canvas.height = Math.floor(viewport.height);
    await page.render({ canvas, viewport, background: '#ffffff' }).promise;
    const ctx = canvas.getContext('2d', { willReadFrequently: true });
    const { data: rgba } = ctx.getImageData(0, 0, canvas.width, canvas.height);
    const list = await page.getOperatorList();
    const name = (fn) => Object.entries(pdfjs.OPS).find(([, value]) => value === fn)?.[0];
    // 알파를 뺀 RGB를 base64로 넘긴다. 큰 배열을 한 번에 펼치면 호출 스택을 넘으므로 나눠서 만든다.
    const rgb = new Uint8Array((rgba.length / 4) * 3);
    for (let i = 0, o = 0; i < rgba.length; i += 4) {
      rgb[o++] = rgba[i];
      rgb[o++] = rgba[i + 1];
      rgb[o++] = rgba[i + 2];
    }
    let binary = '';
    for (let i = 0; i < rgb.length; i += 8192) binary += String.fromCharCode(...rgb.subarray(i, i + 8192));
    return { numPages: doc.numPages, width: canvas.width, height: canvas.height, ops: list.fnArray.map(name), rgb: btoa(binary) };
  } finally {
    await task.destroy();
  }
}

/** 선택기 자리에 OPFS 폴더를 돌려주는 함수를 넣는다. */
function stubPicker(folder) {
  window.__pickerCalls = [];
  window.showDirectoryPicker = async (options) => {
    window.__pickerCalls.push(options);
    const root = await navigator.storage.getDirectory();
    return root.getDirectoryHandle(folder, { create: true });
  };
}

async function listFolder(folder) {
  const root = await navigator.storage.getDirectory();
  const handle = await root.getDirectoryHandle(folder);
  const names = [];
  for await (const name of handle.keys()) names.push(name);
  return names.sort();
}

async function seedFolder(folder, names) {
  const root = await navigator.storage.getDirectory();
  const handle = await root.getDirectoryHandle(folder, { create: true });
  for (const name of names) await handle.getFileHandle(name, { create: true });
}

async function removeFolder(folder) {
  const root = await navigator.storage.getDirectory();
  await root.removeEntry(folder, { recursive: true });
}

async function readFolderFile(folder, name) {
  const root = await navigator.storage.getDirectory();
  const handle = await root.getDirectoryHandle(folder);
  const file = await (await handle.getFileHandle(name)).getFile();
  const bytes = new Uint8Array(await file.arrayBuffer());
  let binary = '';
  for (let i = 0; i < bytes.length; i += 8192) binary += String.fromCharCode(...bytes.subarray(i, i + 8192));
  return btoa(binary);
}

/** 권한 답을 정해 두고, 불린 순서와 그때 사용자 제스처가 살아 있었는지를 남긴다. */
function stubPermission(query, request) {
  const proto = FileSystemHandle.prototype;
  window.__permission = { query: proto.queryPermission, request: proto.requestPermission, calls: [] };
  proto.queryPermission = async (options) => {
    window.__permission.calls.push(['query', options.mode, navigator.userActivation.isActive]);
    return query;
  };
  proto.requestPermission = async (options) => {
    window.__permission.calls.push(['request', options.mode, navigator.userActivation.isActive]);
    return request;
  };
}

function restorePermission() {
  const calls = window.__permission.calls;
  FileSystemHandle.prototype.queryPermission = window.__permission.query;
  FileSystemHandle.prototype.requestPermission = window.__permission.request;
  return calls;
}

/** 지금 탭을 떠나면 묻는가. */
function guardsUnload() {
  const event = new Event('beforeunload', { cancelable: true });
  window.dispatchEvent(event);
  return event.defaultPrevented;
}

/** 파일을 끌어다 놓는 것처럼 drop을 보낸다. 브라우저 기본 동작을 막았는지 돌려준다. */
async function dropFile(name) {
  const canvas = document.createElement('canvas');
  canvas.width = 20;
  canvas.height = 20;
  const blob = await new Promise((resolve) => canvas.toBlob(resolve, 'image/png'));
  const dataTransfer = new DataTransfer();
  dataTransfer.items.add(new File([blob], name, { type: 'image/png' }));
  document.dispatchEvent(new DragEvent('dragover', { dataTransfer, bubbles: true, cancelable: true }));
  const overlayShown = !document.getElementById('drop-overlay').hidden;
  const drop = new DragEvent('drop', { dataTransfer, bubbles: true, cancelable: true });
  document.dispatchEvent(drop);
  return { prevented: drop.defaultPrevented, overlayShown };
}

// ---- 도우미 ----

/** 파일 이름의 시각. 확장자 코드를 부르지 않고 따로 만든다. */
function stampOf(time = new Date()) {
  const two = (value) => String(value).padStart(2, '0');
  return `${time.getFullYear()}${two(time.getMonth() + 1)}${two(time.getDate())}${two(time.getHours())}${two(time.getMinutes())}`;
}

/**
 * 같은 분 안에 끝내야 하는 시나리오. 검사는 시나리오가 무사히 끝난 뒤에 돌려받은 값으로 한다.
 * 분이 바뀌었으면 결과를 버리고 다시 한다. 분 초반으로 기다려 두므로 거의 한 번에 끝난다.
 */
async function withinOneMinute(scenario) {
  for (let attempt = 0; attempt < 5; attempt++) {
    const seconds = new Date().getSeconds();
    if (seconds > 40) await new Promise((r) => setTimeout(r, (60 - seconds) * 1000 + 300));
    const stamp = stampOf();
    const result = await scenario(stamp);
    if (stampOf() === stamp) return { stamp, result };
    say('INFO 검사 중에 분이 바뀌어 다시 합니다');
  }
  throw new Error('minute kept rolling over');
}

const FILE_NAME = (ext) => new RegExp(`^\\d{12}_\\d+\\.${ext}$`);
const near = (a, b, tolerance = 4) => a.every((v, i) => Math.abs(v - b[i]) <= tolerance);
const isWhite = (color) => near(color, [255, 255, 255], 2);
const DRAWING_OPS = ['fill', 'stroke', 'constructPath', 'rectangle', 'eoFill', 'fillStroke'];

/** 콘텐츠 스트림에 적힌 이미지 자리. [폭, 높이, x, y] (포인트). */
const imagePlacements = (stream) =>
  stream.split('\n').map((line) => {
    const [, width, , , height, x, y] = line.match(/^q ([\d.]+) (0) (0) ([\d.]+) ([\d.]+) ([\d.]+) cm/) ?? [];
    return [width, height, x, y].map(Number);
  });

function closeTo(name, actual, expected, tolerance = 0.001) {
  const same = actual.length === expected.length && actual.every((row, i) => row.every((v, j) => Math.abs(v - expected[i][j]) <= tolerance));
  return ok(name, same, `\n  actual   ${JSON.stringify(actual)}\n  expected ${JSON.stringify(expected)}`);
}

function pdfStructure(bytes) {
  const text = bytes.toString('latin1');
  const streams = [...text.matchAll(/<< \/Length \d+ >>\nstream\n([\s\S]*?)\nendstream/g)].map((m) => m[1]);
  return {
    header: text.slice(0, 8),
    pages: Number(text.match(/\/Type \/Pages \/Count (\d+)/)?.[1]),
    images: (text.match(/\/Subtype \/Image/g) ?? []).length,
    mediaBoxes: [...text.matchAll(/\/MediaBox \[0 0 ([\d.]+) ([\d.]+)\]/g)].map((m) => [Number(m[1]), Number(m[2])]),
    streams,
  };
}

async function renderPdf(session, bytes, pageNumber, scale = 1) {
  const result = await session.call(renderPdfPage, bytes.toString('base64'), pageNumber, scale);
  const rgb = Buffer.from(result.rgb, 'base64');
  const at = (x, y) => {
    const i = (y * result.width + x) * 3;
    return [rgb[i], rgb[i + 1], rgb[i + 2]];
  };
  return { ...result, at };
}

// ---- 시나리오 ----

async function outputChecks(session) {
  say('\n# PNG 결과 파일 (ko)');

  await session.addFiles([files.red, files.green, files.blue], 3);

  // ---- 기본값 N=1, F=100%, A4 세로, 3장 ----
  equal('기본 설정: 용지당 1개, 100%', await session.call(() => [document.getElementById('per-sheet-select').value, document.getElementById('image-size-select').value]), ['1', '100']);
  equal('용지당 이미지 수 목록', await session.call(() => [...document.getElementById('per-sheet-select').options].map((o) => o.value)), ['1', '2', '3', '4', '6', '8', '9']);
  equal('이미지 크기 목록', await session.call(() => [...document.getElementById('image-size-select').options].map((o) => o.value)), ['100', '50', '30']);
  equal('여백 목록과 기본값', await session.call(() => [[...document.querySelectorAll('input[name="padding"]')].map((i) => i.value), document.querySelector('input[name="padding"]:checked').value, [...document.querySelectorAll('#padding-group label span')].map((s) => s.textContent)]), [['0', '3', '5', '10'], '5', ['0%', '3%', '5%', '10%']]);
  {
    const saved = await session.save('#save-png');
    ok('기본: 파일 이름 규칙', FILE_NAME('png').test(saved.name), saved.name);
    const png = decodePng(saved.bytes);
    // A4 3쪽: (2480×3 + 14) × 3508 > 2400만 → g = 0.958034 → 쪽 2375×3360, 두께 7. 폭 2375×3 + 14 = 7139
    equal('기본: 캔버스 크기', [png.width, png.height], [7139, 3360]);
    ok('기본: 2,400만 픽셀 이하', png.width * png.height <= 24000000);
    // 여백 2375 × 5% = 118.75, 안쪽 2137.5×3122.5. 1200×1600 → 2137.5×2850
    // x = 118.75 → 119, 끝 2256.25 → 2256. y = 118.75 + 136.25 = 255, 끝 3105. 둘째 쪽 시작 2382, 셋째 4764
    equal('기본: 가운데 줄이 여백·선·여백으로 이어진다', runsAlong(png, 'row', 1680), [
      [W, 0, 119], [R, 119, 2256], [W, 2256, 2375], [D, 2375, 2382],
      [W, 2382, 2501], [G, 2501, 4638], [W, 4638, 4757], [D, 4757, 4764],
      [W, 4764, 4883], [B, 4883, 7020], [W, 7020, 7139],
    ]);
    equal('기본: 첫 쪽 세로 줄은 위아래 흰색', runsAlong(png, 'column', 1187), [[W, 0, 255], [R, 255, 3105], [W, 3105, 3360]]);
    equal('기본: 구분선 픽셀은 #D0D0D0', pixel(png, 2378, 10).slice(0, 3), [208, 208, 208]);
  }

  // ---- N=2, 3장 ----
  {
    await session.settings({ perSheet: 2 });
    const preview = await session.call(readPreview);
    equal('N=2 미리보기: 2쪽, 번호, 칸별 이미지', [preview.sheets, preview.numbers, preview.imagesPerSheet], [2, ['1', '2'], [2, 1]]);
    // 여백 124, 칸 2232×1580.4, 이미지 1185.3×1580.4 → left 647.35/2480 = 26.1%, width 47.79%
    // top 124/3508 = 3.53%, 둘째 칸 top 1803.6/3508 = 51.41%, height 1580.4/3508 = 45.05%
    equal('N=2 미리보기: 썸네일 자리는 실제 출력과 같고 여백이 보인다', preview.firstImages, [
      [[26.1, 3.53, 47.79, 45.05], [26.1, 51.41, 47.79, 45.05]],
      [[26.1, 3.53, 47.79, 45.05]],
    ]);
    ok('N=2 미리보기: 용지 모양 (0.707)', Math.abs(preview.aspect - 2480 / 3508) < 0.01, String(preview.aspect));
    equal('N=2 미리보기: 안내 문구', preview.summary, '총 2페이지 · 용지당 2개');
    ok('N=2 미리보기: PNG 방향과 회색 선, PDF는 페이지별로 저장되고 선이 없다는 안내', /왼쪽에서 오른쪽.*회색 선.*PDF는 페이지별로 저장되고 선이 없습니다/.test(preview.note), preview.note);
    ok('N=2 미리보기: PDF에 여백이 없다고 하지 않는다', !preview.note.includes('여백'), preview.note);
    equal('N=2 미리보기: 구분선을 그리지 않는다', [preview.gray, preview.extraElements], [0, 0]);

    const png = decodePng((await session.save('#save-png')).bytes);
    // 2480×2 + 7 = 4967 × 3508
    equal('N=2: 캔버스 크기', [png.width, png.height], [4967, 3508]);
    // 여백 124, 간격 99.2, 두께 7: 가로줄 124 + 1580.4 + 46.1 = 1750.5 → 1751. 칸 124~1704, 1804~3384
    equal('N=2: 첫 쪽 세로 줄 (여백, 이미지, 가로줄, 이미지, 여백)', runsAlong(png, 'column', 1240), [
      [W, 0, 124], [R, 124, 1704], [W, 1704, 1751], [D, 1751, 1758], [W, 1758, 1804], [G, 1804, 3384], [W, 3384, 3508],
    ]);
    equal('N=2: 쪽 사이 구분선은 캔버스 전체 길이', runsAlong(png, 'column', 2483), [[D, 0, 3508]]);
    equal('N=2: 마지막 쪽의 빈 칸에는 선이 없다', runsAlong(png, 'column', 2487 + 1240), [[W, 0, 124], [B, 124, 1704], [W, 1704, 3508]]);
    // x = 124 + 523.35 = 647.35 → 647, 끝 1832.65 → 1833. 둘째 쪽 시작 2487 → 3134, 4320
    equal('N=2: 위 칸 가로 줄', runsAlong(png, 'row', 300), [
      [W, 0, 647], [R, 647, 1833], [W, 1833, 2480], [D, 2480, 2487], [W, 2487, 3134], [B, 3134, 4320], [W, 4320, 4967],
    ]);
    // 가로줄은 여백 안쪽 124~2356만이다. 그 뒤 여백 2356~2480, 쪽 사이 선 2480~2487, 둘째 쪽에는 없다.
    equal('N=2: 가로줄은 여백 안쪽 폭 전체, 둘째 쪽에는 없다', runsAlong(png, 'row', 1754), [[W, 0, 124], [D, 124, 2356], [W, 2356, 2480], [D, 2480, 2487], [W, 2487, 4967]]);
    equal('N=2: 페이지 여백은 흰색이고 선이 지나가지 않는다', runsAlong(png, 'column', 60), [[W, 0, 3508]]);
    equal('N=2: 흰 배경 위에 그렸다 (불투명)', pixel(png, 10, 10), [255, 255, 255, 255]);
  }

  // ---- A4 가로, N=4, 5장 ----
  await session.clearList();
  await session.addFiles([files.red, files.green, files.blue, files.yellow, files.magenta], 5);
  {
    await session.settings({ orientation: 'landscape', perSheet: 4 });
    const preview = await session.call(readPreview);
    equal('가로 N=4 미리보기: 2쪽 [4, 1]', [preview.sheets, preview.imagesPerSheet], [2, [4, 1]]);
    ok('가로 N=4 미리보기: 가로 용지 모양 (1.414)', Math.abs(preview.aspect - 3508 / 2480) < 0.01, String(preview.aspect));
    ok('가로 N=4 미리보기: 위아래로 잇는다고 안내', /위에서 아래.*회색 선/.test(preview.note), preview.note);

    const png = decodePng((await session.save('#save-png')).bytes);
    // A4 가로는 세로 배치: 3508 × (2480×2 + 7)
    equal('가로 N=4: 캔버스 크기 (위아래로 잇는다)', [png.width, png.height], [3508, 4967]);
    // 여백 124. 칸 1580.4×1066.4, 이미지 799.8×1066.4. x = 124 + 390.3 = 514.3 → 514, 끝 1314.1 → 1314
    // 위 줄 124~1190, 가로줄 1236.5 → 1237, 아래 줄 1289.6 → 1290 ~ 2356. 쪽 사이 2480, 둘째 쪽 2487 → 이미지 2611~3677
    equal('가로 N=4: 왼쪽 열', runsAlong(png, 'column', 864), [
      [W, 0, 124], [R, 124, 1190], [W, 1190, 1237], [D, 1237, 1244], [W, 1244, 1290], [B, 1290, 2356],
      [W, 2356, 2480], [D, 2480, 2487], [W, 2487, 2611], [M, 2611, 3677], [W, 3677, 4967],
    ]);
    // 세로줄 1750.5 → 1751. 오른쪽 칸 x = 1803.6 + 390.3 = 2193.9 → 2194, 끝 2993.7 → 2994
    equal('가로 N=4: 위 줄에 세로줄', runsAlong(png, 'row', 600), [
      [W, 0, 514], [R, 514, 1314], [W, 1314, 1751], [D, 1751, 1758], [W, 1758, 2194], [G, 2194, 2994], [W, 2994, 3508],
    ]);
    equal('가로 N=4: 아래 줄에도 세로줄', runsAlong(png, 'row', 1800), [
      [W, 0, 514], [B, 514, 1314], [W, 1314, 1751], [D, 1751, 1758], [W, 1758, 2194], [Y, 2194, 2994], [W, 2994, 3508],
    ]);
    equal('가로 N=4: 가로줄은 여백 안쪽만', runsAlong(png, 'row', 1240), [[W, 0, 124], [D, 124, 3384], [W, 3384, 3508]]);
    equal('가로 N=4: 마지막 쪽의 빈 칸 쪽으로 세로줄이 없다', runsAlong(png, 'row', 2487 + 600), [[W, 0, 514], [M, 514, 1314], [W, 1314, 3508]]);
    equal('가로 N=4: 마지막 쪽에 가로줄도 없다', runsAlong(png, 'column', 2600).slice(-1), [[W, 2487, 4967]]);
  }

  // ---- F=50%, F=30% ----
  await session.clearList();
  await session.addFiles([files.red, files.green], 2);
  {
    await session.settings({ imageSize: 50 });
    const preview = await session.call(readPreview);
    // 안쪽 2232×3260에 맞춰 1.86, × 0.5 → 1116×1488. left 682/2480 = 27.5%, width 45%, top 1010/3508 = 28.79%, height 42.42%
    equal('F=50% 미리보기', preview.firstImages[0], [[27.5, 28.79, 45, 42.42]]);

    const png = decodePng((await session.save('#save-png')).bytes);
    // x 682~1798, y 1010~2498. 둘째 쪽 2487 → 3169~4285
    equal('F=50%: 세로 줄에 위아래 흰색', runsAlong(png, 'column', 1240), [[W, 0, 1010], [R, 1010, 2498], [W, 2498, 3508]]);
    equal('F=50%: 가로 줄에 좌우 흰색, 쪽 사이 구분선', runsAlong(png, 'row', 1754), [
      [W, 0, 682], [R, 682, 1798], [W, 1798, 2480], [D, 2480, 2487], [W, 2487, 3169], [G, 3169, 4285], [W, 4285, 4967],
    ]);
    equal('F=50%: 모서리는 흰색', pixel(png, 5, 5).slice(0, 3), [255, 255, 255]);
    equal('F=50%: 가운데는 이미지', pixel(png, 1240, 1754).slice(0, 3), RED);
  }
  {
    await session.settings({ imageSize: 30 });
    const png = decodePng((await session.save('#save-png')).bytes);
    // 1.86 × 0.3 = 0.558 → 669.6×892.8. y = 124 + 1183.6 = 1307.6 → 1308, 끝 2200.4 → 2200
    equal('F=30%: 가운데에 30%', runsAlong(png, 'column', 1240), [[W, 0, 1308], [R, 1308, 2200], [W, 2200, 3508]]);
  }

  // ---- 흑백 ----
  {
    await session.settings({ perSheet: 2, color: 'gray' });
    equal('흑백 미리보기 표시', (await session.call(readPreview)).grayscale, true);
    const png = decodePng((await session.save('#save-png')).bytes);
    // 칸 하나에 이미지 1장씩 N=2 → 1쪽. 빨강 (200,30,30)의 회색조 ≈ 0.2126×200 + 0.7152×30 + 0.0722×30 = 66
    const [r, g, b] = pixel(png, 1240, 800);
    ok('흑백: 채널이 같고 약 66', r === g && g === b && Math.abs(r - 66) <= 2, `${r},${g},${b}`);
    equal('흑백: 구분선 색은 그대로', pixel(png, 1240, 1754).slice(0, 3), [208, 208, 208]);
    await session.settings({});
    equal('흑백을 끄면 미리보기도 컬러', (await session.call(readPreview)).grayscale, false);
  }

  // ---- '원본 크기' ----
  await session.clearList();
  await session.addFiles([files.halfClear, files.halfClear], 2);
  {
    await session.settings({ paper: 'original', perSheet: 4, imageSize: 30 });
    equal(
      "'원본 크기': 방향·용지당·크기 설정 비활성화",
      await session.call(() => [
        document.querySelector('input[name="orientation"]').disabled,
        document.getElementById('per-sheet-select').disabled,
        document.getElementById('image-size-select').disabled,
      ]),
      [true, true, true],
    );
    const preview = await session.call(readPreview);
    equal("'원본 크기' 미리보기: 묶음 하나, 번호 없음", [preview.sheets, preview.numbers, preview.imagesPerSheet], [1, [], [2]]);
    // 캔버스 1100×1803. left 50/1100 = 4.55%, top 50/1803 = 2.77%, 둘째 top 953/1803 = 52.86%, 크기 1000/1100, 800/1803
    equal("'원본 크기' 미리보기: 여백을 그린다", preview.firstImages[0], [[4.55, 2.77, 90.91, 44.37], [4.55, 52.86, 90.91, 44.37]]);
    ok("'원본 크기' 미리보기: PDF에 선이 없다는 안내", /회색 선.*PDF는 이미지마다 한 페이지로 저장되고 선이 없습니다/.test(preview.note), preview.note);
    equal("'원본 크기' 미리보기: 자동 방향 안내", preview.summary, '자동: 세로 배치 (위 → 아래)');
    equal("'원본 크기' 미리보기: 구분선을 그리지 않는다", preview.gray, 0);

    const png = decodePng((await session.save('#save-png')).bytes);
    // 가로형 2장 → 세로 배치. 공통 변 1000: 여백 50, 두께 round(3) = 3. 폭 1100, 높이 (50+800+50)×2 + 3 = 1803
    equal("'원본 크기': 캔버스 크기", [png.width, png.height], [1100, 1803]);
    equal("'원본 크기': 투명도를 유지하는 형식이다", png.colorType, 6);
    // [여백 0~50][이미지 50~850: 위 400 불투명, 아래 400 투명][여백 850~900][선 900~903][여백 903~953][이미지 953~1753][여백 1753~1803]
    equal("'원본 크기': 세로 줄", runsAlong(png, 'column', 500), [
      [W, 0, 50], [M, 50, 450], ['transparent', 450, 850], [W, 850, 900], [D, 900, 903],
      [W, 903, 953], [M, 953, 1353], ['transparent', 1353, 1753], [W, 1753, 1803],
    ]);
    equal("'원본 크기': 구분선은 폭 전체이고 불투명", [runsAlong(png, 'row', 901), pixel(png, 0, 901)[3]], [[[D, 0, 1100]], 255]);
    // 흰색을 칠한 뒤 이미지 자리를 지우지 않으면 투명 자리가 흰색이 된다. 네 변의 여백은 불투명한 흰색이다.
    equal("'원본 크기': 이미지 안의 투명 픽셀이 그대로다", [pixel(png, 500, 600)[3], pixel(png, 500, 1500)[3]], [0, 0]);
    equal("'원본 크기': 투명한 줄의 왼쪽·오른쪽 여백은 불투명한 흰색", runsAlong(png, 'row', 600), [[W, 0, 50], ['transparent', 50, 1050], [W, 1050, 1100]]);
    equal(
      "'원본 크기': 네 변의 여백 픽셀이 불투명한 흰색",
      [pixel(png, 500, 10), pixel(png, 10, 200), pixel(png, 1090, 200), pixel(png, 500, 1795), pixel(png, 500, 875)],
      Array(5).fill([255, 255, 255, 255]),
    );
  }
  {
    // 같은 설정으로 PDF: N과 F를 쓰지 않고 이미지당 한 페이지.
    // 1000×800: 짧은 변 800의 5% = 40, 합 1080×880, 긴 변 841.8898pt → 배율 0.7795276
    // 페이지 841.8898×685.9843, 이미지 779.5276×623.622, 자리 31.1811
    const pdf = await session.save('#save-pdf');
    const structure = pdfStructure(pdf.bytes);
    equal("'원본 크기' PDF: 이미지당 한 페이지", [structure.pages, structure.images], [2, 2]);
    equal("'원본 크기' PDF: 페이지 크기", structure.mediaBoxes[0], [841.8898, 685.9843]);
    closeTo("'원본 크기' PDF: 이미지 자리", imagePlacements(structure.streams[0]), [[779.5276, 623.622, 31.1811, 31.1811]]);
    const page = await renderPdf(session, pdf.bytes, 1);
    ok("'원본 크기' PDF: 위쪽 여백", isWhite(page.at(421, 25)) && near(page.at(421, 37), MAGENTA, 12), `${page.at(421, 25)} ${page.at(421, 37)}`);
    ok("'원본 크기' PDF: 왼쪽 여백", isWhite(page.at(25, 100)) && near(page.at(37, 100), MAGENTA, 12), `${page.at(25, 100)} ${page.at(37, 100)}`);
    ok("'원본 크기' PDF: 오른쪽 여백", near(page.at(805, 100), MAGENTA, 12) && isWhite(page.at(816, 100)), `${page.at(805, 100)} ${page.at(816, 100)}`);
    // 이미지 끝 31.18 + 623.62 = 654.8pt. 아래 절반은 투명이라 PDF에서는 흰색이다.
    ok("'원본 크기' PDF: 투명 영역은 흰색", isWhite(page.at(421, 500)), String(page.at(421, 500)));
    ok("'원본 크기' PDF: 구분선 없음", !page.ops.some((op) => DRAWING_OPS.includes(op)), page.ops.join(','));
  }
  await session.clearList();
  await session.addFiles([files.tall, files.tall], 2);
  {
    // 설계서 예: 1000×2000 → 여백 50, 합 1100×2100, 긴 변 841.8898pt → 페이지 440.9899×841.8898, 이미지 400.8999×801.7998, 자리 20.045
    const pdf = await session.save('#save-pdf');
    const structure = pdfStructure(pdf.bytes);
    equal("'원본 크기' PDF 세로형: 페이지 크기", structure.mediaBoxes, [[440.9899, 841.8898], [440.9899, 841.8898]]);
    closeTo("'원본 크기' PDF 세로형: 이미지 자리", imagePlacements(structure.streams[1]), [[400.8999, 801.7998, 20.045, 20.045]]);
    const page = await renderPdf(session, pdf.bytes, 2);
    equal("'원본 크기' PDF 세로형: 렌더 크기", [page.width, page.height], [440, 841]);
    ok(
      "'원본 크기' PDF 세로형: 네 변이 모두 흰 여백이다",
      isWhite(page.at(220, 15)) && isWhite(page.at(220, 826)) && isWhite(page.at(15, 420)) && isWhite(page.at(426, 420)),
      `${page.at(220, 15)} ${page.at(220, 826)} ${page.at(15, 420)} ${page.at(426, 420)}`,
    );
    ok(
      "'원본 크기' PDF 세로형: 여백 바로 안쪽은 이미지다",
      near(page.at(220, 25), BLUE, 12) && near(page.at(220, 816), BLUE, 12) && near(page.at(25, 420), BLUE, 12) && near(page.at(416, 420), BLUE, 12),
      `${page.at(220, 25)} ${page.at(220, 816)} ${page.at(25, 420)} ${page.at(416, 420)}`,
    );
  }
  await session.settings({});
  equal(
    '용지로 돌아오면 설정이 다시 켜진다',
    await session.call(() => [document.getElementById('per-sheet-select').disabled, document.getElementById('image-size-select').disabled]),
    [false, false],
  );

  // ---- PDF ----
  say('\n# PDF 결과 파일 (ko)');
  await session.clearList();
  await session.addFiles([files.red, files.green, files.blue], 3);
  {
    await session.settings({ perSheet: 2 });
    const saved = await session.save('#save-pdf');
    ok('PDF N=2: 파일 이름 규칙', FILE_NAME('pdf').test(saved.name), saved.name);
    const structure = pdfStructure(saved.bytes);
    equal('PDF N=2: 머리글', structure.header, '%PDF-1.4');
    equal('PDF N=2: 3장이 2페이지', [structure.pages, structure.images], [2, 3]);
    equal('PDF N=2: A4 세로', structure.mediaBoxes, [[595.2756, 841.8898], [595.2756, 841.8898]]);
    equal('PDF N=2: 첫 페이지에 2장, 둘째에 1장', structure.streams.map((s) => s.split('\n').length), [2, 1]);
    ok('PDF N=2: 이미지 말고 그리는 명령이 없다', structure.streams.every((s) => s.split('\n').every((line) => /^q [\d. ]+ cm \/Im\d Do Q$/.test(line))), structure.streams.join(' | '));
    // 여백 29.7638, 간격 23.811, 칸 높이 379.2756. 1200×1600 → 284.4567×379.2756, x = 155.4094
    // 위 칸 PDF y = 841.8898 − 29.7638 − 379.2756 = 432.8504, 아래 칸 PDF y = 29.7638
    closeTo('PDF N=2: 파일에 적힌 이미지 자리에 여백과 칸 간격이 있다', imagePlacements(structure.streams[0]), [
      [284.4567, 379.2756, 155.4094, 432.8504],
      [284.4567, 379.2756, 155.4094, 29.7638],
    ]);

    const first = await renderPdf(session, saved.bytes, 1);
    equal('PDF N=2: pdf.js가 읽은 페이지 수', first.numPages, 2);
    equal('PDF N=2: 렌더 크기', [first.width, first.height], [595, 841]);
    ok('PDF N=2: 위 칸은 빨강', near(first.at(297, 200), RED, 12), String(first.at(297, 200)));
    ok('PDF N=2: 아래 칸은 초록', near(first.at(297, 640), GREEN, 12), String(first.at(297, 640)));
    // 칸은 여백 안쪽 29.76~409.04, 432.85~812.13pt.
    ok('PDF N=2: 위쪽 여백은 흰색이고 그 안쪽은 이미지다', isWhite(first.at(297, 25)) && near(first.at(297, 34), RED, 12), `${first.at(297, 25)} ${first.at(297, 34)}`);
    ok('PDF N=2: 아래쪽 여백은 흰색이고 그 안쪽은 이미지다', near(first.at(297, 808), GREEN, 12) && isWhite(first.at(297, 817)), `${first.at(297, 808)} ${first.at(297, 817)}`);
    // 칸 사이 간격 409.04~432.85pt. 간격 전체가 흰색이어야 한다. PNG였다면 여기에 #D0D0D0 줄이 있다.
    const gap = [];
    for (let y = 411; y <= 431; y++) gap.push(first.at(297, y));
    ok('PDF N=2: 칸 사이에 구분선이 없다 (전부 흰색)', gap.every(isWhite), JSON.stringify(gap));
    ok('PDF N=2: 이미지 옆은 흰색', isWhite(first.at(20, 200)), String(first.at(20, 200)));
    ok('PDF N=2: 어떤 그리기 명령도 없다', !first.ops.some((op) => DRAWING_OPS.includes(op)), first.ops.join(','));

    const second = await renderPdf(session, saved.bytes, 2);
    ok('PDF N=2: 둘째 페이지 위 칸은 파랑', near(second.at(297, 200), BLUE, 12), String(second.at(297, 200)));
    ok('PDF N=2: 둘째 페이지 빈 칸은 흰색', isWhite(second.at(297, 640)), String(second.at(297, 640)));
  }
  {
    await session.settings({});
    const saved = await session.save('#save-pdf');
    const structure = pdfStructure(saved.bytes);
    equal('PDF N=1: 이미지당 한 페이지', structure.pages, 3);
    // 여백 안쪽 535.748pt에 꽉 차게: 535.748×714.3307, x = 29.7638, y = (841.8898 − 714.3307)/2 = 63.7795
    closeTo('PDF N=1: 파일에 적힌 이미지 자리', imagePlacements(structure.streams[0]), [[535.748, 714.3307, 29.7638, 63.7795]]);
    const page = await renderPdf(session, saved.bytes, 1);
    ok('PDF N=1: 왼쪽 여백은 흰색이고 그 안쪽은 이미지다', isWhite(page.at(25, 420)) && near(page.at(34, 420), RED, 12), `${page.at(25, 420)} ${page.at(34, 420)}`);
    ok('PDF N=1: 오른쪽 여백은 흰색이고 그 안쪽은 이미지다', near(page.at(561, 420), RED, 12) && isWhite(page.at(570, 420)), `${page.at(561, 420)} ${page.at(570, 420)}`);
    ok('PDF N=1: 구분선 없음', !page.ops.some((op) => DRAWING_OPS.includes(op)), page.ops.join(','));
  }
  {
    await session.settings({ imageSize: 50 });
    const saved = await session.save('#save-pdf');
    const structure = pdfStructure(saved.bytes);
    equal('PDF F=50%: N=1이라 3페이지', structure.pages, 3);
    const page = await renderPdf(session, saved.bytes, 1);
    ok('PDF F=50%: 가운데는 이미지', near(page.at(297, 420), RED, 12), String(page.at(297, 420)));
    ok('PDF F=50%: 모서리는 흰색', isWhite(page.at(20, 20)), String(page.at(20, 20)));
    // 여백 안쪽 폭 535.748 × 50% = 267.874 → x = 163.70 ~ 431.57pt
    ok('PDF F=50%: 이미지 왼쪽은 흰색', isWhite(page.at(158, 420)), String(page.at(158, 420)));
    ok('PDF F=50%: 이미지 안쪽은 빨강', near(page.at(168, 420), RED, 12), String(page.at(168, 420)));
    ok('PDF F=50%: 이미지 오른쪽은 흰색', isWhite(page.at(437, 420)), String(page.at(437, 420)));
  }
  {
    await session.settings({ orientation: 'landscape', perSheet: 2 });
    const saved = await session.save('#save-pdf');
    const structure = pdfStructure(saved.bytes);
    equal('PDF 가로 N=2: 2페이지, 가로 A4', [structure.pages, structure.mediaBoxes[0]], [2, [841.8898, 595.2756]]);
    const page = await renderPdf(session, saved.bytes, 1);
    // 좌우 2칸. 왼쪽 29.76~409.04pt, 간격 409.04~432.85pt, 오른쪽 432.85~812.13pt
    ok('PDF 가로 N=2: 왼쪽은 빨강, 오른쪽은 초록', near(page.at(204, 297), RED, 12) && near(page.at(637, 297), GREEN, 12), `${page.at(204, 297)} ${page.at(637, 297)}`);
    ok('PDF 가로 N=2: 좌우 여백은 흰색', isWhite(page.at(25, 297)) && isWhite(page.at(817, 297)), `${page.at(25, 297)} ${page.at(817, 297)}`);
    ok('PDF 가로 N=2: 여백 바로 안쪽은 이미지다', near(page.at(34, 297), RED, 12) && near(page.at(808, 297), GREEN, 12), `${page.at(34, 297)} ${page.at(808, 297)}`);
    const gap = [];
    for (let x = 411; x <= 431; x++) gap.push(page.at(x, 297));
    ok('PDF 가로 N=2: 칸 사이에 구분선이 없다', gap.every(isWhite), JSON.stringify(gap));
  }
  await session.settings({});
}

/** 여백 P를 바꾸면 결과 파일이 바뀐다 (DESIGN §2.1.2, §2.1.3, §2.1.5). */
async function paddingChecks(session) {
  say('\n# 여백 P (ko)');
  await session.clearList();
  await session.addFiles([files.red, files.green, files.blue], 3);

  // ---- P=10%, N=2: 여백 248, 간격 198.4 ----
  {
    await session.settings({ perSheet: 2, padding: 10 });
    // 칸 1984×1406.8, 이미지 1055.1×1406.8. left 712.45/2480 = 28.73%, top 248/3508 = 7.07%
    // width 42.54%, height 40.1%, 둘째 칸 top 1853.2/3508 = 52.83%
    equal('P=10% 미리보기', (await session.call(readPreview)).firstImages[0], [[28.73, 7.07, 42.54, 40.1], [28.73, 52.83, 42.54, 40.1]]);
    const png = decodePng((await session.save('#save-png')).bytes);
    equal('P=10% PNG: 캔버스 크기는 그대로', [png.width, png.height], [4967, 3508]);
    equal('P=10% PNG: 세로 줄', runsAlong(png, 'column', 1240), [
      [W, 0, 248], [R, 248, 1655], [W, 1655, 1751], [D, 1751, 1758], [W, 1758, 1853], [G, 1853, 3260], [W, 3260, 3508],
    ]);
    equal('P=10% PNG: 가로줄은 여백 안쪽만', runsAlong(png, 'row', 1754), [[W, 0, 248], [D, 248, 2232], [W, 2232, 2480], [D, 2480, 2487], [W, 2487, 4967]]);
    equal('P=10% PNG: 위 칸 가로 줄', runsAlong(png, 'row', 500), [
      [W, 0, 712], [R, 712, 1768], [W, 1768, 2480], [D, 2480, 2487], [W, 2487, 3199], [B, 3199, 4255], [W, 4255, 4967],
    ]);
    const pdf = await session.save('#save-pdf');
    // 여백 59.5276, 간격 47.622, 칸 높이 337.6063. 1200×1600 → 253.2047×337.6063, x = 171.0354
    closeTo('P=10% PDF: 이미지 자리', imagePlacements(pdfStructure(pdf.bytes).streams[0]), [
      [253.2047, 337.6063, 171.0354, 444.7559],
      [253.2047, 337.6063, 171.0354, 59.5276],
    ]);
    const page = await renderPdf(session, pdf.bytes, 1);
    ok('P=10% PDF: 위쪽 여백이 넓다', isWhite(page.at(297, 55)) && near(page.at(297, 64), RED, 12), `${page.at(297, 55)} ${page.at(297, 64)}`);
    ok('P=10% PDF: 구분선 없음', !page.ops.some((op) => DRAWING_OPS.includes(op)), page.ops.join(','));
  }

  // ---- P=3% ----
  {
    await session.settings({ perSheet: 2, padding: 3 });
    const png = decodePng((await session.save('#save-png')).bytes);
    // 여백 74.4, 간격 59.52. 위 칸 74 ~ 1724, 아래 칸 1784 ~ 3434
    equal('P=3% PNG: 세로 줄', runsAlong(png, 'column', 1240), [
      [W, 0, 74], [R, 74, 1724], [W, 1724, 1751], [D, 1751, 1758], [W, 1758, 1784], [G, 1784, 3434], [W, 3434, 3508],
    ]);
  }

  // ---- P=0%, N=2 ----
  {
    await session.settings({ perSheet: 2, padding: 0 });
    // 칸 2480×1750.5, 이미지 1312.875×1750.5. left 23.53%, width 52.94%, height 49.9%, 둘째 칸 top 1757.5/3508 = 50.1%
    equal('P=0% 미리보기', (await session.call(readPreview)).firstImages[0], [[23.53, 0, 52.94, 49.9], [23.53, 50.1, 52.94, 49.9]]);
    const png = decodePng((await session.save('#save-png')).bytes);
    equal('P=0% PNG: 이미지 사이가 선뿐이다', runsAlong(png, 'column', 1240), [[R, 0, 1751], [D, 1751, 1758], [G, 1758, 3508]]);
    equal('P=0% PNG: 가로줄이 페이지 폭 전체다', runsAlong(png, 'row', 1754), [[D, 0, 2487], [W, 2487, 4967]]);
    equal('P=0% PNG: 마지막 쪽의 빈 칸에는 선이 없다', runsAlong(png, 'column', 2487 + 1240), [[B, 0, 1751], [W, 1751, 3508]]);
    const pdf = await session.save('#save-pdf');
    // 여백·간격 0. 칸 높이 420.9449, 1200×1600 → 315.7087×420.9449, x = 139.7835
    closeTo('P=0% PDF: 칸이 맞닿는다', imagePlacements(pdfStructure(pdf.bytes).streams[0]), [
      [315.7087, 420.9449, 139.7835, 420.9449],
      [315.7087, 420.9449, 139.7835, 0],
    ]);
    const page = await renderPdf(session, pdf.bytes, 1);
    ok('P=0% PDF: 페이지 위쪽 끝까지 이미지다', near(page.at(297, 2), RED, 12), String(page.at(297, 2)));
    ok('P=0% PDF: 페이지 아래쪽 끝까지 이미지다', near(page.at(297, 838), GREEN, 12), String(page.at(297, 838)));
    ok('P=0% PDF: 맞닿는 곳에 흰 틈이 없다', near(page.at(297, 418), RED, 12) && near(page.at(297, 424), GREEN, 12), `${page.at(297, 418)} ${page.at(297, 424)}`);
    ok('P=0% PDF: 구분선 없음', !page.ops.some((op) => DRAWING_OPS.includes(op)), page.ops.join(','));
  }

  // ---- P=0%, N=1: 페이지 사이도 선뿐이다 ----
  await session.clearList();
  await session.addFiles([files.red, files.green], 2);
  {
    await session.settings({ padding: 0 });
    const png = decodePng((await session.save('#save-png')).bytes);
    equal('P=0% N=1 PNG: [이미지][선][이미지]', runsAlong(png, 'row', 1754), [[R, 0, 2480], [D, 2480, 2487], [G, 2487, 4967]]);
  }

  // ---- '원본 크기': P는 켜져 있고 PNG·PDF에 모두 쓴다 ----
  await session.clearList();
  await session.addFiles([files.halfClear, files.halfClear], 2);
  {
    await session.settings({ paper: 'original', padding: 10 });
    equal(
      "'원본 크기': 여백만 켜져 있다",
      await session.call(() => [document.querySelector('input[name="padding"]').disabled, document.getElementById('per-sheet-select').disabled, document.getElementById('image-size-select').disabled]),
      [false, true, true],
    );
    // 캔버스 1200×2003. left 100/1200 = 8.33%, top 100/2003 = 4.99%, 크기 1000/1200, 800/2003, 둘째 top 1103/2003 = 55.07%
    equal("'원본 크기' P=10% 미리보기", (await session.call(readPreview)).firstImages[0], [[8.33, 4.99, 83.33, 39.94], [8.33, 55.07, 83.33, 39.94]]);
    const png = decodePng((await session.save('#save-png')).bytes);
    // 공통 변 1000: 여백 100, 두께 3. 폭 1200, 높이 (200 + 800)×2 + 3 = 2003
    equal("'원본 크기' P=10% PNG: 캔버스 크기", [png.width, png.height], [1200, 2003]);
    equal("'원본 크기' P=10% PNG: 세로 줄", runsAlong(png, 'column', 600), [
      [W, 0, 100], [M, 100, 500], ['transparent', 500, 900], [W, 900, 1000], [D, 1000, 1003],
      [W, 1003, 1103], [M, 1103, 1503], ['transparent', 1503, 1903], [W, 1903, 2003],
    ]);
  }
  {
    await session.settings({ paper: 'original', padding: 0 });
    const png = decodePng((await session.save('#save-png')).bytes);
    equal("'원본 크기' P=0% PNG: 캔버스 크기", [png.width, png.height], [1000, 1603]);
    equal("'원본 크기' P=0% PNG: [이미지][선][이미지], 투명도 유지", runsAlong(png, 'column', 500), [
      [M, 0, 400], ['transparent', 400, 800], [D, 800, 803], [M, 803, 1203], ['transparent', 1203, 1603],
    ]);
  }
  await session.clearList();
  await session.addFiles([files.tall], 1);
  await session.addFiles([files.tall], 2);
  {
    await session.settings({ paper: 'original', padding: 0 });
    const pdf = pdfStructure((await session.save('#save-pdf')).bytes);
    // 페이지 비율이 이미지 비율과 같다: 841.8898 ÷ 2 = 420.9449
    equal("'원본 크기' P=0% PDF: 페이지 크기", pdf.mediaBoxes[0], [420.9449, 841.8898]);
    closeTo("'원본 크기' P=0% PDF: 여백 없음", imagePlacements(pdf.streams[0]), [[420.9449, 841.8898, 0, 0]]);
  }
  {
    await session.settings({ paper: 'original', padding: 10 });
    const pdf = pdfStructure((await session.save('#save-pdf')).bytes);
    // 여백 100, 합 1200×2200, 배율 841.8898/2200
    equal("'원본 크기' P=10% PDF: 페이지 크기", pdf.mediaBoxes[0], [459.2126, 841.8898]);
    closeTo("'원본 크기' P=10% PDF: 이미지 자리", imagePlacements(pdf.streams[0]), [[382.6772, 765.3543, 38.2677, 38.2677]]);
  }
  await session.settings({});
  await session.clearList();
}

async function reencodeCheck(session) {
  say('\n# 20MB를 넘는 PNG (ko)');
  await session.clearList();
  const a = noiseImage('noise_a.png', 3000);
  const b = noiseImage('noise_b.png', 3000);
  await session.addFiles([a, b], 2);
  await session.settings({});
  const saved = await session.save('#save-png');
  ok('다시 인코딩: 20MB 이하', saved.size <= 20000000, String(saved.size));
  const png = decodePng(saved.bytes);
  ok('다시 인코딩: 원래 4967폭보다 줄었다', png.width < 4967, String(png.width));
  ok('다시 인코딩: 흰 배경 위라 알파가 전부 불투명', pixel(png, 2, 2)[3] === 255);
  // 쪽 사이 구분선은 캔버스 가운데 근처다. 흐려지지 않은 #D0D0D0가 2px 이상 남아야 한다.
  const expectedAt = Math.round(((2480 + 3.5) / 4967) * png.width);
  const runs = runsAlong(png, 'row', Math.floor(png.height / 2)).filter(([color, from, to]) => color === D && to - from >= 2);
  ok('다시 인코딩: 구분선이 #D0D0D0로 2px 이상 남는다', runs.length >= 1 && Math.abs((runs[0][1] + runs[0][2]) / 2 - expectedAt) <= 2, `at ${expectedAt}, runs ${JSON.stringify(runs.slice(0, 3))}`);
  say(`INFO 다시 인코딩 결과 ${png.width}×${png.height}, ${saved.size} bytes, 구분선 ${JSON.stringify(runs[0])}`);
  await session.clearList();
}

/** 대화 상자가 열려 있으면 끌어다 놓은 파일을 뒤의 목록에 더하지 않는다. */
async function dropChecks(session) {
  say('\n# 끌어다 놓기 (ko)');
  await session.clearList();
  await session.addFiles([files.red, files.green], 2);
  const names = () => session.call(() => [...document.querySelectorAll('#item-list .name')].map((n) => n.textContent));

  await session.click('#history-button');
  await session.waitFor('기록 창', () => document.getElementById('history-dialog').open);
  const blocked = await session.call(dropFile, 'behind_modal.png');
  await new Promise((r) => setTimeout(r, 500));
  equal('대화 상자가 열려 있으면: 목록에 더하지 않는다', await names(), ['red.png', 'green.png']);
  equal('대화 상자가 열려 있으면: 브라우저가 파일로 넘어가지 않게 막고 안내를 띄우지 않는다', blocked, { prevented: true, overlayShown: false });
  equal('대화 상자가 열려 있으면: 창이 그대로다', await session.call(() => document.getElementById('history-dialog').open), true);
  await session.click('#history-close');
  await session.waitFor('기록 창 닫힘', () => !document.getElementById('history-dialog').open);

  const allowed = await session.call(dropFile, 'dropped.png');
  await session.waitFor('목록 3개', () => document.querySelectorAll('#item-list .item').length === 3);
  equal('대화 상자가 없으면: 목록에 더한다', await names(), ['red.png', 'green.png', 'dropped.png']);
  equal('대화 상자가 없으면: 안내를 띄운다', allowed, { prevented: true, overlayShown: true });
  await session.clearList();
}

/**
 * 저장 폴더 (DESIGN §2.1.4, §5.2). 헤드리스에는 진짜 선택 창과 권한 창이 없어 선택기를 OPFS 폴더로,
 * 권한 답을 가짜로 바꾼다. 진짜 창은 사람이 확인해야 한다.
 */
async function folderChecks() {
  say('\n# 저장 폴더 (ko)');
  const session = await Session.open({ lang: 'ko' });
  try {
    const messages = JSON.parse(readFileSync(join(EXTENSION, '_locales', 'ko', 'messages.json'), 'utf8'));
    const location = () => session.call(() => document.getElementById('save-location').textContent);
    const dialogState = () =>
      session.call(() => ({
        current: document.getElementById('folder-current').textContent,
        reason: document.getElementById('folder-reason').hidden ? null : document.getElementById('folder-reason').textContent,
        useDefault: !document.getElementById('folder-use-default').hidden,
        pick: !document.getElementById('folder-pick').hidden,
      }));
    const list = (folder) => session.call(listFolder, folder);
    const idle = () => session.waitFor('저장 가능', () => !document.getElementById('save-png').disabled && !document.querySelector('dialog[open]'));
    const DEFAULT_TEXT = '저장 폴더: 브라우저 다운로드 폴더';
    const UNAVAILABLE = '저장 폴더에 접근할 수 없습니다. 폴더를 다시 골라 주세요.';

    await session.addFiles([files.red, files.green], 2);

    // ---- 기본 폴더 ----
    equal('기본: 저장 위치 문구', await location(), DEFAULT_TEXT);
    await session.openFolderDialog();
    equal("기본: 창에 '기본 폴더 쓰기'가 없다", await dialogState(), { current: DEFAULT_TEXT, reason: null, useDefault: false, pick: true });
    await session.closeFolderDialog();

    // 기록의 이름으로 연번을 정한다. 공유도 같은 규칙이다.
    const defaults = await withinOneMinute(async () => {
      const first = await session.save('#save-png');
      const second = await session.save('#save-png');
      const pdf = await session.save('#save-pdf');
      await session.click('#share-button');
      await session.waitFor('공유 형식', () => document.getElementById('share-format-dialog').open);
      await session.click('#share-format-dialog button[value="png"]');
      await session.waitFor('공유 창', () => document.getElementById('share-dialog').open, { timeout: 120000 });
      const shared = await session.call(() => document.getElementById('share-file').textContent);
      await session.click('#share-close');
      await idle();
      return { first, second, pdf, shared };
    });
    equal('기본: 첫 저장은 _1', defaults.result.first.name, `${defaults.stamp}_1.png`);
    equal('기본: 같은 분의 둘째 저장은 _2', defaults.result.second.name, `${defaults.stamp}_2.png`);
    equal('기본: PDF는 연번을 따로 센다', defaults.result.pdf.name, `${defaults.stamp}_1.pdf`);
    ok('기본: 공유 파일도 이어서 _3', defaults.result.shared.startsWith(`${defaults.stamp}_3.png `), defaults.result.shared);
    ok('기본: 이름에 장수가 없다', !/images/.test(defaults.result.first.name), defaults.result.first.name);

    // ---- 선택기를 그냥 닫으면 아무 일도 없다 ----
    await session.call(() => {
      window.showDirectoryPicker = async () => {
        throw new DOMException('closed', 'AbortError');
      };
    });
    await session.openFolderDialog();
    await session.click('#folder-pick');
    await new Promise((r) => setTimeout(r, 300));
    equal('선택기를 닫으면: 창이 그대로이고 위치도 그대로다', await session.call(() => [document.getElementById('folder-dialog').open, document.getElementById('folder-pick').disabled, document.getElementById('save-location').textContent]), [true, false, DEFAULT_TEXT]);
    equal('선택기를 닫으면: 오류 안내가 없다', await session.call(() => [...document.querySelectorAll('.snack')].filter((s) => s.textContent.includes('폴더를 고를 수 없습니다')).length), 0);
    await session.closeFolderDialog();

    // ---- 닫자마자 다시 열어도 앞 창의 처리가 섞이지 않는다. close 이벤트는 다음 프레임에 온다 ----
    const reopened = await session.call(async () => {
      window.__raceCalls = 0;
      window.showDirectoryPicker = async () => {
        window.__raceCalls++;
        return (await navigator.storage.getDirectory()).getDirectoryHandle('race-folder', { create: true });
      };
      const byId = (id) => document.getElementById(id);
      byId('change-folder').click();
      byId('folder-cancel').click();
      byId('change-folder').click();
      byId('folder-pick').click();
      await new Promise((r) => setTimeout(r, 600));
      return [window.__raceCalls, byId('save-location').textContent, byId('folder-dialog').open];
    });
    equal('바로 다시 열어도: 선택기를 한 번만 열고 고른 폴더를 쓴다', reopened, [1, '저장 폴더: race-folder', false]);
    await session.useDefaultFolder();
    await session.call(removeFolder, 'race-folder');

    // ---- 폴더 고르기 ----
    await session.pickFolder('e2e-folder');
    equal('고르기: 선택기 옵션', await session.call(() => window.__pickerCalls), [{ id: 'picmerge', mode: 'readwrite', startIn: 'downloads' }]);
    equal('고르기: 저장 위치 문구', await location(), '저장 폴더: e2e-folder');
    await session.openFolderDialog();
    equal("고르기: 창에 '기본 폴더 쓰기'가 있다", await dialogState(), { current: '저장 폴더: e2e-folder', reason: null, useDefault: true, pick: true });
    await session.closeFolderDialog();

    // ---- 고른 폴더에 쓰기: 실제 항목을 보고 연번을 정한다 ----
    const downloadsBefore = session.downloads.size;
    const custom = await withinOneMinute(async (stamp) => {
      const next = stampOf(new Date(Date.now() + 60000));
      await session.call(seedFolder, 'e2e-folder', [`${stamp}_1.png`, `${next}_1.png`]);
      const first = await session.saveToFolder('#save-png');
      const second = await session.saveToFolder('#save-png');
      const pdf = await session.saveToFolder('#save-pdf');
      const snack = await session.call(() => [...document.querySelectorAll('.snack')].map((s) => s.textContent));
      return { first, second, pdf, snack, names: await list('e2e-folder') };
    });
    const { first: customFirst, second: customSecond, pdf: customPdf } = custom.result;
    equal('폴더: 있는 _1을 피해 _2', customFirst.fileName, `${custom.stamp}_2.png`);
    equal('폴더: 다음은 _3', customSecond.fileName, `${custom.stamp}_3.png`);
    equal('폴더: PDF는 _1', customPdf.fileName, `${custom.stamp}_1.pdf`);
    ok('폴더: 먼저 있던 파일과 새 파일만 있고 임시 파일이 없다', [`${custom.stamp}_1.png`, `${custom.stamp}_2.png`, `${custom.stamp}_3.png`, `${custom.stamp}_1.pdf`].every((n) => custom.result.names.includes(n)) && custom.result.names.every((n) => /^\d{12}_\d+\.(png|pdf)$/.test(n)), JSON.stringify(custom.result.names));
    equal('폴더: 내려받기가 없다', session.downloads.size, downloadsBefore);
    equal('폴더: 기록에 폴더 이름을 남긴다', [customFirst.destination, customFirst.customFolder, customFirst.status], ['e2e-folder', true, 'success']);
    ok('폴더: 저장 안내에 폴더와 파일 이름이 있다', custom.result.snack.includes(`e2e-folder 폴더에 저장했습니다: ${customFirst.fileName}`), JSON.stringify(custom.result.snack));
    // 실제로 쓰인 내용을 읽어 본다. 1200×1600 2장, A4 2쪽: 4967×3508, 안쪽 폭 2232 → 124~2356, 둘째 쪽 2611~4843
    const written = decodePng(Buffer.from(await session.call(readFolderFile, 'e2e-folder', customFirst.fileName), 'base64'));
    equal('폴더: 쓰인 PNG의 크기', [written.width, written.height], [4967, 3508]);
    equal('폴더: 쓰인 PNG의 내용', runsAlong(written, 'row', 1754), [
      [W, 0, 124], [R, 124, 2356], [W, 2356, 2480], [D, 2480, 2487], [W, 2487, 2611], [G, 2611, 4843], [W, 4843, 4967],
    ]);
    equal('폴더: 쓰인 PDF의 머리글', Buffer.from(await session.call(readFolderFile, 'e2e-folder', customPdf.fileName), 'base64').subarray(0, 8).toString('latin1'), '%PDF-1.4');

    // ---- 쓰는 동안: '저장하는 중'이고 취소할 수 없다 ----
    await session.call(() => {
      const proto = FileSystemWritableFileStream.prototype;
      window.__write = proto.write;
      proto.write = async function write(data) {
        await new Promise((r) => setTimeout(r, 1500));
        return window.__write.call(this, data);
      };
    });
    await session.click('#save-png');
    // 문구는 지난번 저장의 것이 남아 있을 수 있어 창이 열렸는지도 본다.
    await session.waitFor('저장하는 중', (message) => document.getElementById('progress-dialog').open && document.getElementById('progress-text').textContent === message, { args: [messages.progress_saving.message] });
    equal('쓰는 동안: 취소할 수 없다', await session.call(() => document.getElementById('progress-cancel').disabled), true);
    equal('쓰는 동안: 떠날 때 묻는다', await session.call(guardsUnload), true);
    await idle();
    await session.call(() => {
      FileSystemWritableFileStream.prototype.write = window.__write;
    });

    // ---- 다시 불러와도 기억한다 ----
    await session.reload();
    equal('다시 불러오기: 고른 폴더를 기억한다', await location(), '저장 폴더: e2e-folder');
    const countBefore = (await list('e2e-folder')).length;
    await session.addFiles([files.red, files.green], 2);
    await session.saveToFolder('#save-png');
    equal('다시 불러오기: 기억한 핸들로 쓴다', (await list('e2e-folder')).length, countBefore + 1);

    // ---- 기본 폴더로 되돌리기 ----
    await session.useDefaultFolder();
    equal('되돌리기: 저장 위치 문구', await location(), DEFAULT_TEXT);
    const backToDefault = await session.save('#save-png');
    ok('되돌리기: 다시 내려받는다', FILE_NAME('png').test(backToDefault.name), backToDefault.name);
    equal('되돌리기: 기록은 표식이다', (await session.history())[0].destination, 'download');
    await session.reload();
    equal('되돌리기: 다시 불러와도 기본 폴더다', await location(), DEFAULT_TEXT);
    await session.addFiles([files.red, files.green], 2);

    // ---- 폴더 이름이 표식과 같아도 섞이지 않는다 ----
    await session.call(() => localStorage.removeItem('picmerge.sessions'));
    const named = await withinOneMinute(async () => {
      await session.call(() => localStorage.removeItem('picmerge.sessions'));
      await session.pickFolder('download');
      const inFolder = await session.saveToFolder('#save-png');
      await session.useDefaultFolder();
      const inDefault = await session.save('#save-png');
      await session.call(removeFolder, 'download');
      return { inFolder, inDefault };
    });
    equal('이름이 download인 폴더: 고른 폴더로 기록한다', [named.result.inFolder.destination, named.result.inFolder.customFolder], ['download', true]);
    equal('이름이 download인 폴더: 그 안의 파일은 기본 폴더 연번에 세지 않는다', [named.result.inFolder.fileName, named.result.inDefault.name], [`${named.stamp}_1.png`, `${named.stamp}_1.png`]);
    await session.click('#history-button');
    await session.waitFor('기록 창', () => document.getElementById('history-dialog').open);
    const rows = await session.call(() => [...document.querySelectorAll('#history-list .sub')].map((row) => row.textContent));
    await session.click('#history-close');
    await session.waitFor('기록 창 닫힘', () => !document.getElementById('history-dialog').open);
    ok('이름이 download인 폴더: 기록에는 이름 그대로, 기본 폴더는 번역해서 보여 준다', rows.some((row) => / · download( ·|$)/.test(row)) && rows.some((row) => row.includes(' · 다운로드')), JSON.stringify(rows));

    // ---- 권한 거절: 합성 전에 묻고, 취소하면 저장하지 않는다 ----
    await session.pickFolder('e2e-folder');
    await session.call(stubPermission, 'prompt', 'denied');
    let sessionsBefore = (await session.history()).length;
    let namesBefore = await list('e2e-folder');
    let downloadsCount = session.downloads.size;
    await session.click('#save-png');
    await session.waitFor('저장 폴더 창', () => document.getElementById('folder-dialog').open);
    equal('거절: query 다음 request이고 사용자 제스처 안이다', await session.call(() => window.__permission.calls), [['query', 'readwrite', true], ['request', 'readwrite', true]]);
    equal('거절: 이유와 함께 창을 띄운다', await dialogState(), { current: '저장 폴더: e2e-folder', reason: UNAVAILABLE, useDefault: true, pick: true });
    equal('거절: 합성을 시작하지 않았다', [await session.call(() => document.getElementById('progress-dialog').open), (await session.history()).length], [false, sessionsBefore]);
    await session.closeFolderDialog();
    await idle();
    equal('거절 후 취소: 저장하지 않는다', [(await session.history()).length, await list('e2e-folder'), session.downloads.size], [sessionsBefore, namesBefore, downloadsCount]);
    equal('거절 후 취소: 폴더는 그대로다', await location(), '저장 폴더: e2e-folder');

    // 거절 후 다른 폴더를 고르면 그 폴더로 바로 저장한다.
    await session.call(stubPicker, 'second-folder');
    await session.click('#save-png');
    await session.waitFor('저장 폴더 창', () => document.getElementById('folder-dialog').open);
    await session.click('#folder-pick');
    await session.waitFor('저장 끝', () => {
      const [record] = JSON.parse(localStorage.getItem('picmerge.sessions') ?? '[]');
      return record?.status === 'success' && record.destination === 'second-folder' && !document.querySelector('dialog[open]');
    });
    equal('거절 후 다른 폴더: 그 폴더에 저장한다', (await list('second-folder')).length, 1);
    await session.call(removeFolder, 'second-folder');

    // 거절 후 '기본 폴더 쓰기'면 내려받는다.
    await session.pickFolder('e2e-folder');
    const downloadsBeforeDefault = session.downloads.size;
    await session.click('#save-png');
    await session.waitFor('저장 폴더 창', () => document.getElementById('folder-dialog').open);
    await session.click('#folder-use-default');
    for (let i = 0; i < 400 && session.downloads.size === downloadsBeforeDefault; i++) await new Promise((r) => setTimeout(r, 50));
    await idle();
    equal("거절 후 '기본 폴더 쓰기': 내려받고 기본 폴더가 된다", [session.downloads.size, await location()], [downloadsBeforeDefault + 1, DEFAULT_TEXT]);
    await session.call(restorePermission);

    // ---- 권한을 다시 받으면 그대로 저장한다 ----
    await session.pickFolder('e2e-folder');
    await session.call(stubPermission, 'prompt', 'granted');
    namesBefore = await list('e2e-folder');
    await session.saveToFolder('#save-png');
    equal('다시 허용: query 다음 request', (await session.call(restorePermission)).map(([name]) => name), ['query', 'request']);
    equal('다시 허용: 폴더에 저장한다', (await list('e2e-folder')).length, namesBefore.length + 1);

    // ---- 폴더가 지워졌으면 창을 띄운다 ----
    await session.pickFolder('gone-folder');
    await session.call(removeFolder, 'gone-folder');
    sessionsBefore = (await session.history()).length;
    await session.click('#save-png');
    await session.waitFor('저장 폴더 창', () => document.getElementById('folder-dialog').open);
    equal('지워진 폴더: 이유와 함께 창을 띄운다', (await dialogState()).reason, UNAVAILABLE);
    await session.closeFolderDialog();
    await idle();
    equal('지워진 폴더: 취소하면 저장하지 않는다', (await session.history()).length, sessionsBefore);

    // ---- 쓰다가 저장 공간이 부족하면 ----
    await session.pickFolder('quota-folder');
    await session.call(() => {
      const proto = FileSystemWritableFileStream.prototype;
      window.__write = proto.write;
      proto.write = async () => {
        throw new DOMException('full', 'QuotaExceededError');
      };
    });
    await session.click('#save-png');
    await session.waitFor('오류 창', () => document.getElementById('message-dialog').open, { timeout: 120000 });
    equal('공간 부족: 오류 문구', await session.call(() => [document.getElementById('message-title').textContent, document.getElementById('message-text').textContent]), [messages.alert_save_failed_title.message, messages.error_out_of_space.message]);
    equal('공간 부족: 쓰다 만 항목을 남기지 않는다', await list('quota-folder'), []);
    equal('공간 부족: 기록', (await session.history()).slice(0, 1).map((r) => [r.status, r.errorCode, r.destination, r.fileName ?? null]), [['failed', 'out_of_space', 'quota-folder', null]]);
    await session.click('#message-actions .button');
    await session.waitFor('오류 창 닫힘', () => !document.getElementById('message-dialog').open);
    await session.call(() => {
      FileSystemWritableFileStream.prototype.write = window.__write;
    });

    // ---- 쓰다가 폴더를 잃으면: 오류 문구와 함께 폴더 변경 창 ----
    await session.call(() => {
      const proto = FileSystemDirectoryHandle.prototype;
      window.__getFileHandle = proto.getFileHandle;
      proto.getFileHandle = async () => {
        throw new DOMException('gone', 'NotFoundError');
      };
    });
    await session.click('#save-png');
    await session.waitFor('저장 폴더 창', () => document.getElementById('folder-dialog').open, { timeout: 120000 });
    equal('쓰다가 폴더를 잃으면: 이유와 함께 창을 띄운다', (await dialogState()).reason, UNAVAILABLE);
    equal('쓰다가 폴더를 잃으면: 기록', (await session.history()).slice(0, 1).map((r) => [r.status, r.errorCode]), [['failed', 'folder_unavailable']]);
    await session.closeFolderDialog();
    await session.call(() => {
      FileSystemDirectoryHandle.prototype.getFileHandle = window.__getFileHandle;
    });
    await idle();
    equal('쓰다가 폴더를 잃으면: 항목을 남기지 않는다', await list('quota-folder'), []);

    // ---- 긴 폴더 이름도 넘치지 않는다 ----
    const longName = `long-folder-name-${'x'.repeat(100)}`;
    await session.pickFolder(longName);
    await checkOverflow(session, 'ko', '긴 폴더 이름');
    await session.openFolderDialog();
    await checkOverflow(session, 'ko', '긴 폴더 이름의 창');
    await session.closeFolderDialog();

    // ---- 선택기를 지원하지 않는 브라우저 ----
    await session.call(() => {
      window.showDirectoryPicker = undefined;
    });
    await session.openFolderDialog();
    equal("API 없음: '다른 폴더 고르기'를 숨기고 되돌리기는 남긴다", await dialogState(), { current: `저장 폴더: ${longName}`, reason: null, useDefault: true, pick: false });
    await session.click('#folder-use-default');
    await session.waitFor('기본 폴더', () => !document.getElementById('folder-dialog').open);
    equal("API 없음: 기본 폴더면 '변경'도 숨긴다", await session.call(() => document.getElementById('change-folder').hidden), true);

    equal('저장 폴더 시나리오: 페이지 오류 없음', session.errors, []);
    equal('저장 폴더 시나리오: 확장 밖으로 나간 요청이 없다', session.externalRequests(), []);
    equal('저장 폴더 시나리오: 떠나기 창 없음', session.dialogs, []);
    const permissions = await session.call(() => [chrome.runtime.getManifest().permissions ?? [], chrome.runtime.getManifest().host_permissions ?? []]);
    equal('저장 폴더 시나리오: 권한 선언이 여전히 없다', permissions, [[], []]);
  } finally {
    await session.close();
  }
}

/** 언어별 기대값은 _locales 파일이 아니라 설계서와 손으로 적은 표다. */
const LANGUAGE_FACTS = {
  ko: { folder: 'ko', subtitle: '이미지 합치기', padding: '여백', perSheet: '용지당 이미지 수', save: 'PNG 저장', font: 'Malgun Gothic' },
  en: { folder: 'en', subtitle: '', padding: 'Margin', perSheet: 'Images per sheet', save: 'Save PNG', font: 'Segoe UI' },
  ja: { folder: 'ja', subtitle: '画像結合', padding: '余白', perSheet: '用紙あたりの画像数', save: 'PNG を保存', font: 'Yu Gothic UI' },
  'zh-CN': { folder: 'zh_CN', subtitle: '图片合并', padding: '边距', perSheet: '每张纸的图片数', save: '保存 PNG', font: 'Microsoft YaHei UI' },
  'zh-TW': { folder: 'zh_TW', subtitle: '圖片合併', padding: '留白', perSheet: '每張紙的圖片數', save: '儲存 PNG', font: 'Microsoft JhengHei UI' },
  es: { folder: 'es', subtitle: 'Unir imágenes', padding: 'Margen', perSheet: 'Imágenes por hoja', save: 'Guardar PNG', font: 'Segoe UI' },
  fr: { folder: 'fr', subtitle: "Fusion d'images", padding: 'Marge', perSheet: 'Images par feuille', save: 'Enregistrer en PNG', font: 'Segoe UI' },
  de: { folder: 'de', subtitle: 'Bilder zusammenfügen', padding: 'Rand', perSheet: 'Bilder pro Blatt', save: 'PNG speichern', font: 'Segoe UI' },
  'pt-BR': { folder: 'pt_BR', subtitle: 'Juntar imagens', padding: 'Margem', perSheet: 'Imagens por folha', save: 'Salvar PNG', font: 'Segoe UI' },
  'pt-PT': { folder: 'pt_PT', subtitle: 'Juntar imagens', padding: 'Margem', perSheet: 'Imagens por folha', save: 'Guardar PNG', font: 'Segoe UI' },
  ru: { folder: 'ru', subtitle: 'Объединение изображений', padding: 'Поля', perSheet: 'Изображений на листе', save: 'Сохранить PNG', font: 'Segoe UI' },
  vi: { folder: 'vi', subtitle: 'Ghép ảnh', padding: 'Lề', perSheet: 'Số ảnh mỗi tờ', save: 'Lưu PNG', font: 'Segoe UI' },
  id: { folder: 'id', subtitle: 'Gabung Gambar', padding: 'Margin', perSheet: 'Gambar per lembar', save: 'Simpan PNG', font: 'Segoe UI' },
  th: { folder: 'th', subtitle: 'รวมรูปภาพ', padding: 'ระยะขอบ', perSheet: 'จำนวนรูปต่อแผ่น', save: 'บันทึก PNG', font: 'Leelawadee UI' },
  // 지원하지 않는 언어는 English다 (DESIGN §2.2).
  it: { folder: 'en', subtitle: '', padding: 'Margin', perSheet: 'Images per sheet', save: 'Save PNG', font: 'Segoe UI', fallback: true },
};

// 좁은 창과 짧은 창. 짧은 창은 문서가 스크롤되지 않아 패널 안에서 끝까지 볼 수 있어야 한다.
const WINDOWS = [[360, 800], [500, 800], [821, 800], [830, 560], [900, 600], [960, 650], [1280, 600]];

async function checkOverflow(session, lang, stage) {
  for (const [width, height] of WINDOWS) {
    await session.resize(width, height);
    const problems = await session.call(auditOverflow);
    ok(`${lang} ${stage} ${width}×${height}: 넘치거나 잘리지 않는다`, problems.length === 0, problems.slice(0, 6).join(' | '));
  }
  await session.resize(1280, 900);
}

async function languageChecks(lang, { deep = false } = {}) {
  const facts = LANGUAGE_FACTS[lang];
  const session = await Session.open({ lang });
  try {
    say(`\n# 언어 ${lang}`);
    const messages = JSON.parse(readFileSync(join(EXTENSION, '_locales', facts.folder, 'messages.json'), 'utf8'));
    const title = facts.subtitle ? `Pic Merge ${facts.subtitle}` : 'Pic Merge';
    const state = await session.call(() => ({
      ui: chrome.i18n.getUILanguage(),
      lang: document.documentElement.lang,
      h1: document.getElementById('app-title').innerText,
      text: document.getElementById('app-title').textContent,
      small: document.querySelector('#app-title small')?.textContent ?? null,
      title: document.title,
      name: chrome.runtime.getManifest().name,
      description: chrome.runtime.getManifest().description,
      permissions: chrome.runtime.getManifest().permissions ?? [],
      hosts: chrome.runtime.getManifest().host_permissions ?? [],
      perSheet: document.querySelector('#per-sheet-setting .setting-label').textContent,
      padding: document.querySelector('#padding-group .setting-label').textContent,
      paddingOptions: document.querySelectorAll('input[name="padding"]').length,
      save: document.getElementById('save-png').textContent.trim(),
      body: document.body.innerText,
      fontFamily: getComputedStyle(document.body).fontFamily,
      subtitleSmaller: (() => {
        const small = document.querySelector('#app-title small');
        return !small || Number.parseFloat(getComputedStyle(small).fontSize) < Number.parseFloat(getComputedStyle(document.getElementById('app-title')).fontSize);
      })(),
    }));
    equal(`${lang}: 제목 글자`, state.h1, title);
    equal(`${lang}: 제목 textContent`, state.text, title);
    equal(`${lang}: 부제`, state.small, facts.subtitle || null);
    ok(`${lang}: 부제가 제목보다 작다`, state.subtitleSmaller);
    equal(`${lang}: 문서 제목`, state.title, title);
    equal(`${lang}: <html lang>은 보이는 문구의 언어다`, state.lang, facts.folder.replace('_', '-'));
    equal(`${lang}: 확장 이름`, state.name, 'Pic Merge');
    equal(`${lang}: 확장 설명`, state.description, messages.ext_description.message);
    equal(`${lang}: 권한 없음`, [state.permissions, state.hosts], [[], []]);
    equal(`${lang}: 도구 모음 제목`, await session.call(() => chrome.action.getTitle({})), messages.ext_action_title.message);
    equal(`${lang}: 설정 이름`, state.perSheet, facts.perSheet);
    equal(`${lang}: 여백 설정 이름과 선택지 수`, [state.padding, state.paddingOptions], [facts.padding, 4]);
    equal(`${lang}: 저장 버튼`, state.save, facts.save);
    equal(`${lang}: 저장 위치와 변경`, await session.call(() => [document.getElementById('save-location').textContent, document.getElementById('change-folder').textContent, document.getElementById('change-folder').hidden]), [messages.save_location_default.message, messages.change_folder.message, false]);
    if (facts.folder !== 'ko') ok(`${lang}: 화면에 한글이 없다`, !/[가-힣]/.test(state.body), state.body.match(/.{0,20}[가-힣].{0,20}/)?.[0]);
    ok(`${lang}: 글꼴 목록의 맨 앞`, state.fontFamily.replaceAll('"', '').startsWith(facts.font), state.fontFamily);

    // 실제로 어떤 글꼴로 그렸는지. 없는 글꼴은 빈 네모가 된다.
    const { root } = await session.send('DOM.getDocument');
    const { nodeId } = await session.send('DOM.querySelector', { nodeId: root.nodeId, selector: '.save-bar .note:not(.hint)' });
    const { fonts } = await session.send('CSS.getPlatformFontsForNode', { nodeId });
    ok(`${lang}: 글자가 시스템 글꼴로 그려진다`, fonts.length > 0 && fonts.reduce((sum, f) => sum + f.glyphCount, 0) > 0, JSON.stringify(fonts));
    say(`INFO ${lang} 글꼴: ${fonts.map((f) => `${f.familyName}(${f.glyphCount})`).join(', ')}`);

    // 빈 화면: 버튼이 모두 비활성이다.
    const emptyContrast = await session.call(auditBarContrast);
    const lowEmpty = emptyContrast.filter((c) => c.ratio < 4.5 || c.opacity < 1);
    ok(`${lang}: 막대 글자 명암비 4.5:1 이상 (비활성 포함, ${emptyContrast.length}개)`, emptyContrast.length >= 5 && lowEmpty.length === 0, JSON.stringify(lowEmpty));
    await checkOverflow(session, lang, '빈 화면');

    await session.addFiles([files.red, files.green, files.blue], 3);
    await session.settings({ perSheet: 2 });
    const filled = await session.call(() => ({
      body: document.body.innerText,
      count: document.getElementById('list-count').textContent,
      summary: document.getElementById('preview-direction').textContent,
    }));
    equal(`${lang}: 목록 머리 문구`, filled.count, messages.list_count.message.replace('$1', '3').replace('$2', '30'));
    equal(`${lang}: 미리보기 요약`, filled.summary, messages.preview_summary.message.replace('$1', '2').replace('$2', '2'));
    if (facts.folder !== 'ko') ok(`${lang}: 항목이 있어도 화면에 한글이 없다`, !/[가-힣]/.test(filled.body), filled.body.match(/.{0,20}[가-힣].{0,20}/)?.[0]);
    const filledContrast = await session.call(auditBarContrast);
    const lowFilled = filledContrast.filter((c) => c.ratio < 4.5 || c.opacity < 1);
    ok(`${lang}: 활성 버튼 명암비 4.5:1 이상`, lowFilled.length === 0, JSON.stringify(lowFilled));
    await checkOverflow(session, lang, '항목 있음');

    // 대화 상자마다 긴 문구가 넘치는지 본다.
    const dialogs = [
      ['기록', '#history-button', 'history-dialog', '#history-close'],
      ['저장 폴더', '#change-folder', 'folder-dialog', '#folder-cancel'],
      ['공유 형식', '#share-button', 'share-format-dialog', '#share-format-dialog button[value=""]'],
      ['비우기 확인', '#clear-button', 'message-dialog', '#message-actions .button.text'],
    ];
    for (const [name, opener, dialog, closer] of dialogs) {
      await session.click(opener);
      await session.waitFor(name, (id) => document.getElementById(id).open, { args: [dialog] });
      await checkOverflow(session, lang, name);
      await session.click(closer);
      await session.waitFor(`${name} 닫힘`, (id) => !document.getElementById(id).open, { args: [dialog] });
    }

    await session.resize(360, 800);
    await session.screenshot(`${lang}-360`);
    await session.resize(1280, 900);
    await session.screenshot(`${lang}-1280`);

    if (deep) await deepLanguageChecks(session, lang, messages);
    equal(`${lang}: 페이지 오류 없음`, session.errors, []);
    equal(`${lang}: 확장 밖으로 나간 요청이 없다`, session.externalRequests(), []);
  } finally {
    await session.close();
  }
}

/** ko·en은 흐름 전체를 눌러 본다: 공유, 기록, 영역 편집, 오류, PDF 입력, 비정상 종료 안내. */
async function deepLanguageChecks(session, lang, messages) {
  const text = (key, ...values) => values.reduce((m, value, i) => m.replace(`$${i + 1}`, String(value)), messages[key].message);

  // 깨진 파일: 목록에 넣지 않고 안내한다.
  await session.addFiles([files.broken], 3);
  await session.waitFor('제외 안내', (message) => [...document.querySelectorAll('.snack')].some((s) => s.textContent === message), { args: [text('snack_unsupported', 1)] });
  ok(`${lang}: 지원하지 않는 파일 안내`, true);

  // PDF 입력: 표시 이름은 언어와 무관하다.
  const pdf = await samplePdf();
  await session.addFiles([pdf], 5);
  equal(
    `${lang}: PDF가 페이지마다 항목으로 펼쳐진다`,
    await session.call(() => [...document.querySelectorAll('#item-list .name')].slice(-2).map((n) => n.textContent)),
    ['two_pages.pdf (1/2)', 'two_pages.pdf (2/2)'],
  );

  // 영역 편집: 오른쪽 손잡이를 끌어 폭을 줄인다.
  await session.click('#item-list .item:first-child .icon-button');
  await session.waitFor('영역 편집 열림', () => document.getElementById('crop-dialog').open && !document.getElementById('crop-apply').disabled);
  equal(`${lang}: 영역 편집 문구`, await session.call(() => [document.getElementById('crop-title').textContent, document.getElementById('crop-apply').textContent, document.getElementById('crop-reset').textContent, document.getElementById('crop-cancel').textContent]), [text('crop_title'), text('crop_apply'), text('crop_reset'), text('cancel')]);
  await checkOverflow(session, lang, '영역 편집');
  const handle = await session.call(() => {
    const box = document.querySelector('.crop-handle.e').getBoundingClientRect();
    const whole = document.getElementById('crop-box').getBoundingClientRect();
    return { x: box.left + box.width / 2, y: box.top + box.height / 2, width: whole.width };
  });
  say(`INFO ${lang} 영역 상자 폭 ${handle.width}px`);
  await session.mouse('mousePressed', handle.x, handle.y);
  await session.mouse('mouseMoved', handle.x - handle.width / 2, handle.y);
  await session.mouse('mouseReleased', handle.x - handle.width / 2, handle.y);
  await session.click('#crop-apply');
  await session.waitFor('영역 적용', (label) => document.querySelector('#item-list .item:first-child .sub').textContent.includes(label), { args: [text('item_cropped')] });
  // 원본 1200×1600의 오른쪽 절반을 잘라 약 600×1600. 칸(N=2, 2232×1580.4)에 맞으면 약 592.65폭, 2480의 23.9%다.
  const cropped = await session.call(() => {
    const img = document.querySelector('.preview-sheet img');
    return Number.parseFloat(img.style.width);
  });
  ok(`${lang}: 영역 편집이 미리보기에 반영된다 (폭 약 23.9%)`, Math.abs(cropped - (592.65 / 2480) * 100) < 1, String(cropped));

  // 공유: 형식 고르기 → 만들기 → 공유 창.
  await session.click('#share-button');
  await session.waitFor('공유 형식', () => document.getElementById('share-format-dialog').open);
  equal(`${lang}: 공유 형식 문구`, await session.call(() => document.getElementById('share-format-title').textContent), text('share_format_title'));
  await session.click('#share-format-dialog button[value="png"]');
  await session.waitFor('공유 창', () => document.getElementById('share-dialog').open, { timeout: 120000 });
  equal(`${lang}: 공유 창 문구`, await session.call(() => [document.getElementById('share-title').textContent, document.getElementById('share-system').textContent, document.getElementById('share-copy').textContent, document.getElementById('share-mail').textContent, document.getElementById('share-download').textContent]), [text('share_title'), text('share_system'), text('share_copy'), text('share_mail'), text('share_download')]);
  await checkOverflow(session, lang, '공유 창');
  const before = session.downloads.size;
  await session.click('#share-download');
  await session.waitFor('스낵', (prefix) => [...document.querySelectorAll('.snack')].some((s) => s.textContent.startsWith(prefix)), { args: [text('snack_saved', '').trim()] });
  for (let i = 0; i < 100 && session.downloads.size === before; i++) await new Promise((r) => setTimeout(r, 50));
  ok(`${lang}: 공유 창에서 내려받기`, session.downloads.size === before + 1);
  await session.click('#share-close');
  await session.waitFor('공유 창 닫힘', () => !document.getElementById('share-dialog').open && !document.getElementById('save-png').disabled);

  // PDF 공유 때 복사 불가 안내.
  await session.click('#share-button');
  await session.waitFor('공유 형식', () => document.getElementById('share-format-dialog').open);
  await session.click('#share-format-dialog button[value="pdf"]');
  await session.waitFor('공유 창', () => document.getElementById('share-dialog').open, { timeout: 120000 });
  equal(`${lang}: PDF는 이미지 복사 불가 안내`, await session.call(() => [document.getElementById('share-copy').disabled, document.getElementById('share-copy').title]), [true, text('copy_png_only')]);
  await session.click('#share-close');
  await session.waitFor('공유 창 닫힘', () => !document.getElementById('share-dialog').open && !document.getElementById('save-png').disabled);

  // 저장 한 번 뒤 기록: 예전 한국어 표식과 실패 기록도 사용자 언어로 보여 준다.
  await session.save('#save-png');
  await session.call(() => {
    const sessions = JSON.parse(localStorage.getItem('picmerge.sessions'));
    const at = new Date().toISOString();
    sessions.push(
      { id: 1, startedAt: at, status: 'success', format: 'png', direction: 'vertical', count: 2, destination: '공유', fileName: 'old_share.png', bytes: 1000 },
      { id: 2, startedAt: at, status: 'failed', format: 'pdf', direction: null, count: 2, destination: '다운로드', errorCode: 'output_too_large' },
    );
    localStorage.setItem('picmerge.sessions', JSON.stringify(sessions));
  });
  await session.click('#history-button');
  await session.waitFor('기록 창', () => document.getElementById('history-dialog').open);
  const history = await session.call(() => ({
    title: document.getElementById('history-title').textContent,
    rate: document.getElementById('history-rate').textContent,
    items: [...document.querySelectorAll('#history-list .history-item')].map((i) => i.innerText),
  }));
  equal(`${lang}: 기록 제목`, history.title, text('history_title'));
  // 저장 1 + PNG 공유 1 + PDF 공유 1 + 예전 성공 1 = 성공 4, 실패 1 → 80%
  equal(`${lang}: 기록 성공률`, history.rate, text('history_rate', 30, 80, 4, 5));
  ok(`${lang}: 기록의 PNG 공유 표식`, history.items.some((i) => i.includes('PNG') && i.includes(text('share'))), JSON.stringify(history.items));
  ok(`${lang}: 기록의 저장 표식`, history.items.some((i) => i.includes(text('share_download'))), JSON.stringify(history.items));
  ok(`${lang}: 예전 표식 '공유'를 옮겨 보여 준다`, history.items.find((i) => i.includes('old_share.png'))?.includes(text('share')), JSON.stringify(history.items));
  const failedRow = history.items.find((i) => i.includes(text('status_failed')));
  ok(`${lang}: 실패 기록의 상태와 오류 문구`, failedRow?.includes(text('error_output_too_large')) && failedRow?.includes(text('share_download')), failedRow);
  if (lang !== 'ko') ok(`${lang}: 기록에 한글이 없다`, !/[가-힣]/.test(history.items.join(' ')), history.items.join(' '));
  await session.screenshot(`${lang}-history`);
  await session.click('#history-close');

  // 진행 중 표시와 취소.
  await session.click('#save-png');
  await session.waitFor('진행 창', () => document.getElementById('progress-dialog').open);
  equal(`${lang}: 합성 중에는 떠날 때 묻는다`, await session.call(guardsUnload), true);
  const progress = await session.call(() => [document.getElementById('progress-title').textContent, document.getElementById('progress-cancel').textContent]);
  equal(`${lang}: 진행 창 문구`, progress, [text('save_png'), text('cancel')]);
  await session.call(() => document.getElementById('progress-cancel').click());
  await session.waitFor('취소 끝', () => !document.getElementById('progress-dialog').open && !document.getElementById('save-png').disabled, { timeout: 120000 });
  const cancelled = await session.call(() => [...document.querySelectorAll('.snack')].map((s) => s.textContent));
  ok(`${lang}: 취소 안내 또는 이미 끝난 저장`, cancelled.includes(text('snack_save_cancelled')) || cancelled.some((c) => c.startsWith(text('snack_saved', '').trim())), JSON.stringify(cancelled));

  // 합성이 끝났으니 공유 창이 열려 있어도 떠날 때 묻지 않는다. 합성 중에는 위에서 묻는 것을 확인했다.
  // 메일 앱을 건드리지 않으려고 창 안의 버튼은 누르지 않고, 다시 불러와서 빠져나온다.
  await session.click('#share-button');
  await session.waitFor('공유 형식', () => document.getElementById('share-format-dialog').open);
  await session.click('#share-format-dialog button[value="png"]');
  await session.waitFor('공유 창', () => document.getElementById('share-dialog').open, { timeout: 120000 });
  equal(`${lang}: 공유 창이 열려 있으면 떠날 때 묻지 않는다`, await session.call(guardsUnload), false);
  const dialogsBeforeReload = session.dialogs.length;
  await session.reload();
  equal(`${lang}: 공유 창이 열린 채 다시 불러와도 묻지 않는다`, session.dialogs.slice(dialogsBeforeReload), []);

  // 비정상 종료 안내: 진행 중으로 남은 기록이 있으면 다음 시작 때 알린다.
  await session.call(() => {
    const sessions = JSON.parse(localStorage.getItem('picmerge.sessions'));
    sessions.unshift({ id: 3, startedAt: new Date().toISOString(), status: 'running', format: 'png', direction: 'vertical', count: 2, destination: 'download' });
    localStorage.setItem('picmerge.sessions', JSON.stringify(sessions));
  });
  await session.reload();
  await session.waitFor('비정상 종료 안내', () => document.getElementById('message-dialog').open);
  equal(`${lang}: 비정상 종료 안내`, await session.call(() => [document.getElementById('message-title').textContent, document.getElementById('message-text').textContent, document.querySelector('#message-actions .button').textContent]), [text('crashed_title'), text('crashed_message'), text('ok')]);
  await session.click('#message-actions .button');
}

// ---- 스토어 스크린샷 ----

const mix = (a, b, t) => a.map((v, i) => Math.round(v + (b[i] - v) * Math.min(1, Math.max(0, t))));

/** 모두 수식으로 그린다. 사진이나 사람 이름이 들어갈 일이 없다. */
function writeStoreSamples() {
  const sunset = (x, y, w, h) => {
    const horizon = h * 0.62;
    const sun = Math.hypot(x - w * 0.5, y - horizon * 0.86);
    if (y < horizon) {
      const sky = mix([58, 42, 110], [250, 150, 90], y / horizon);
      return sun < h * 0.13 ? [255, 226, 150] : mix([255, 200, 120], sky, Math.min(1, (sun - h * 0.13) / (h * 0.28)));
    }
    const depth = (y - horizon) / (h - horizon);
    const glitter = Math.abs(x - w * 0.5) < w * (0.05 + depth * 0.16) && Math.sin(y * 0.16 + Math.sin(x * 0.02) * 3) > 0.2;
    return glitter ? mix([255, 214, 140], [230, 130, 90], depth) : mix([120, 74, 110], [28, 34, 78], depth);
  };
  const mountains = (x, y, w, h) => {
    const u = x / w;
    const far = h * (0.46 + 0.1 * Math.sin(u * 7.3) + 0.04 * Math.sin(u * 23 + 1));
    const near = h * (0.66 + 0.09 * Math.sin(u * 4.1 + 2) + 0.03 * Math.sin(u * 17));
    if (y > near) return mix([38, 92, 78], [18, 56, 52], (y - near) / (h - near));
    if (y > far) return y < far + h * 0.035 ? [236, 243, 248] : mix([96, 124, 156], [62, 96, 118], (y - far) / (near - far + 1));
    return mix([120, 178, 232], [224, 240, 248], y / far);
  };
  const flowers = (x, y, w, h) => {
    const cell = w / 3;
    const cx = (Math.floor(x / cell) + 0.5) * cell;
    const cy = (Math.floor(y / cell) + 0.5) * cell;
    const dx = x - cx;
    const dy = y - cy;
    const radius = Math.hypot(dx, dy) / cell;
    const petals = 0.3 + 0.1 * Math.cos(Math.atan2(dy, dx) * 6);
    if (radius < 0.09) return [250, 196, 72];
    if (radius < petals) return mix([250, 128, 158], [236, 72, 120], radius / petals);
    return mix([252, 238, 226], [214, 234, 214], y / h);
  };
  const waves = (x, y, w, h) => {
    const band = Math.floor((y + 34 * Math.sin((x / w) * 6.28 + y * 0.004)) / (h / 9));
    return mix([18, 90, 124], [132, 222, 208], band / 8);
  };
  return [
    ['sunset.png', 1600, 1200, sunset],
    ['mountains.png', 1600, 1200, mountains],
    ['flowers.png', 1200, 1600, flowers],
    ['waves.png', 1200, 1600, waves],
  ].map(([name, width, height, paint]) => writeImage(name, encodePng(width, height, (x, y) => paint(x, y, width, height))));
}

async function imagesLoaded(session) {
  await session.waitFor('이미지 표시', () => [...document.querySelectorAll('img')].filter((img) => img.getClientRects().length).every((img) => img.complete && img.naturalWidth > 0));
}

/** 불투명 PNG 1280×800으로 저장하고 다시 읽어 확인한다. */
async function storeShot(session, path) {
  const { data } = await session.send('Page.captureScreenshot', { format: 'png', captureBeyondViewport: false });
  const shot = decodePng(Buffer.from(data, 'base64'));
  if (shot.width !== 1280 || shot.height !== 800) throw new Error(`${path}: captured ${shot.width}x${shot.height}`);
  writeFileSync(path, encodeRgb(shot));
  const written = decodePng(readFileSync(path));
  equal(`스토어 ${path.split(/[\\/]/).at(-1)}: 1280×800, 알파 없음`, [written.width, written.height, written.colorType, written.channels], [1280, 800, 2, 3]);
}

async function storeScreenshots() {
  const outDir = join(repo, 'docs', 'chrome-web-store');
  const readmeDir = join(repo, 'docs', 'screenshots');
  mkdirSync(outDir, { recursive: true });
  mkdirSync(readmeDir, { recursive: true });
  const session = await Session.open({ lang: 'en', width: 1280, height: 800 });
  try {
    equal('스토어: 영어 화면', await session.call(() => [document.documentElement.lang, document.getElementById('app-title').textContent]), ['en', 'Pic Merge']);
    await session.addFiles(writeStoreSamples(), 4);
    await session.settings({ perSheet: 2 });
    await imagesLoaded(session);
    const main = join(outDir, 'screenshot-1-main.png');
    await storeShot(session, main);
    copyFileSync(main, join(readmeDir, 'chrome-extension.png'));

    // 영역 편집: 오른쪽과 아래를 조금 줄여 영역이 보이게 한다.
    await session.click('#item-list .item:nth-child(2) .icon-button');
    await session.waitFor('영역 편집 열림', () => document.getElementById('crop-dialog').open && !document.getElementById('crop-apply').disabled);
    await imagesLoaded(session);
    for (const handle of ['.crop-handle.se', '.crop-handle.nw']) {
      const at = await session.call((selector) => {
        const box = document.querySelector(selector).getBoundingClientRect();
        const whole = document.getElementById('crop-box').getBoundingClientRect();
        return { x: box.left + box.width / 2, y: box.top + box.height / 2, width: whole.width, height: whole.height };
      }, handle);
      const sign = handle.endsWith('se') ? -1 : 1;
      await session.mouse('mousePressed', at.x, at.y);
      await session.mouse('mouseMoved', at.x + sign * at.width * 0.14, at.y + sign * at.height * 0.14);
      await session.mouse('mouseReleased', at.x + sign * at.width * 0.14, at.y + sign * at.height * 0.14);
    }
    await session.call(() => new Promise((done) => requestAnimationFrame(() => requestAnimationFrame(done))));
    await storeShot(session, join(outDir, 'screenshot-2-crop.png'));
    await session.click('#crop-cancel');
    await session.waitFor('영역 편집 닫힘', () => !document.getElementById('crop-dialog').open);

    // 최근 기록: 실제로 저장해 쌓는다. 파일은 임시 폴더로 내려받는다.
    await session.settings({ perSheet: 2 });
    await session.save('#save-pdf');
    await session.settings({ perSheet: 4, orientation: 'landscape' });
    await session.save('#save-png');
    await session.settings({ perSheet: 1 });
    await session.save('#save-pdf');
    await session.settings({ perSheet: 2 });
    await session.save('#save-png');
    await session.waitFor('안내가 사라짐', () => document.querySelectorAll('.snack').length === 0, { timeout: 15000 });
    await session.click('#history-button');
    await session.waitFor('기록 창', () => document.getElementById('history-dialog').open);
    await session.call(() => new Promise((done) => requestAnimationFrame(() => requestAnimationFrame(done))));
    await storeShot(session, join(outDir, 'screenshot-3-history.png'));
    await session.click('#history-close');
    equal('스토어: 페이지 오류 없음', session.errors, []);
    equal('스토어: 확장 밖으로 나간 요청이 없다', session.externalRequests(), []);
    say(`스토어 스크린샷: ${outDir}`);
    say(`README 스크린샷: ${join(readmeDir, 'chrome-extension.png')}`);
  } finally {
    await session.close();
  }
}

// ---- 시작 ----

async function main() {
  const started = Date.now();
  say(`작업 폴더: ${workDir}`);
  say(`확장: ${EXTENSION}`);
  if (STORE_SCREENSHOTS) {
    await storeScreenshots();
    say(`E2E: ${passed} passed, ${failed} failed`);
    return;
  }

  const main = await Session.open({ lang: 'ko' });
  try {
    const { product } = await main.browser.send('Browser.getVersion');
    say(`Chrome: ${product}, 확장 ID: ${main.extensionId}, PID ${main.browser.child.pid}`);
    say('확장 올리기: --remote-debugging-pipe --enable-unsafe-extension-debugging + CDP Extensions.loadUnpacked (new headless)');
    await outputChecks(main);
    await paddingChecks(main);
    await dropChecks(main);
    if (!QUICK) await reencodeCheck(main);
    equal('ko 출력 시나리오: 페이지 오류 없음', main.errors, []);
    equal('ko 출력 시나리오: 확장 밖으로 나간 요청이 없다', main.externalRequests(), []);
  } finally {
    await main.close();
  }

  await folderChecks();
  await languageChecks('ko', { deep: true });
  await languageChecks('en', { deep: true });
  if (!QUICK) {
    for (const lang of Object.keys(LANGUAGE_FACTS)) {
      if (lang !== 'ko' && lang !== 'en') await languageChecks(lang);
    }
  }

  say(`\n스크린샷 폴더: ${shotsDir}`);
  say(`걸린 시간: ${Math.round((Date.now() - started) / 1000)}초`);
  say(`E2E: ${passed} passed, ${failed} failed`);
}

let crashed = false;
try {
  await main();
} catch (error) {
  crashed = true;
  say(`CRASH ${error.stack ?? error}`);
  say(`E2E: ${passed} passed, ${failed} failed (중단됨)`);
} finally {
  writeFileSync(join(workDir, 'result.log'), `${log.join('\n')}\n`);
  rmSync(imagesDir, { recursive: true, force: true, maxRetries: 8, retryDelay: 300 });
  console.log(`결과 로그: ${join(workDir, 'result.log')}`);
}
process.exitCode = crashed || failed > 0 ? 1 : 0;
