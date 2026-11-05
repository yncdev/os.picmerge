// Chrome을 throwaway 프로필로 띄우고 --remote-debugging-pipe로 CDP를 직접 말한다. 의존성이 없다.
import { spawn } from 'node:child_process';
import { once } from 'node:events';

export const DEFAULT_CHROME = 'C:/Program Files/Google/Chrome/Application/chrome.exe';

/**
 * 파이프 연결. fd 3은 Chrome이 읽고 fd 4는 Chrome이 쓴다. 메시지는 NUL로 구분한 JSON이다.
 * 탭 세션은 flatten 모드라 메시지의 sessionId로 구분한다.
 */
export class Browser {
  #nextId = 1;
  #pending = new Map();
  #listeners = new Map();
  #buffer = [];

  constructor(child) {
    this.child = child;
    this.exited = once(child, 'exit');
    child.stdio[4].on('data', (chunk) => this.#receive(chunk));
    child.on('exit', () => {
      for (const { reject, method } of this.#pending.values()) reject(new Error(`Chrome exited during ${method}`));
      this.#pending.clear();
    });
  }

  #receive(chunk) {
    let start = 0;
    let end;
    while ((end = chunk.indexOf(0, start)) !== -1) {
      this.#buffer.push(chunk.subarray(start, end));
      this.#dispatch(JSON.parse(Buffer.concat(this.#buffer).toString('utf8')));
      this.#buffer = [];
      start = end + 1;
    }
    if (start < chunk.length) this.#buffer.push(chunk.subarray(start));
  }

  #dispatch(message) {
    if (message.id !== undefined) {
      const call = this.#pending.get(message.id);
      this.#pending.delete(message.id);
      if (!call) return;
      if (message.error) call.reject(new Error(`${call.method}: ${message.error.message}`));
      else call.resolve(message.result);
      return;
    }
    for (const listener of this.#listeners.get(message.method) ?? []) listener(message.params, message.sessionId);
  }

  send(method, params = {}, sessionId = undefined) {
    const id = this.#nextId++;
    const payload = JSON.stringify({ id, method, params, ...(sessionId ? { sessionId } : {}) });
    return new Promise((resolve, reject) => {
      this.#pending.set(id, { resolve, reject, method });
      this.child.stdio[3].write(`${payload}\0`);
    });
  }

  on(method, listener) {
    if (!this.#listeners.has(method)) this.#listeners.set(method, new Set());
    this.#listeners.get(method).add(listener);
    return () => this.#listeners.get(method).delete(listener);
  }

  /** 우리가 띄운 프로세스만 닫는다. 응답이 없으면 이 PID만 강제 종료한다. */
  async close() {
    if (this.child.exitCode !== null || this.child.signalCode !== null) return;
    let timer;
    const timeout = new Promise((resolve) => {
      timer = setTimeout(() => resolve('timeout'), 10000);
    });
    const closing = this.send('Browser.close').catch(() => {});
    const outcome = await Promise.race([this.exited.then(() => 'exited'), closing.then(() => this.exited).then(() => 'exited'), timeout]);
    clearTimeout(timer); // 남겨 두면 프로세스가 끝나지 않고 기다린다.
    if (outcome === 'timeout') {
      this.child.kill();
      await this.exited;
    }
  }
}

export function launchChrome({ chromePath = DEFAULT_CHROME, userDataDir, lang, width = 1280, height = 900, extraArgs = [] }) {
  if (!userDataDir) throw new Error('userDataDir is required: never run against a real profile');
  const args = [
    '--remote-debugging-pipe',
    '--enable-unsafe-extension-debugging',
    `--user-data-dir=${userDataDir}`,
    `--lang=${lang}`,
    '--headless=new',
    `--window-size=${width},${height}`,
    '--no-first-run',
    '--no-default-browser-check',
    '--disable-sync',
    '--disable-background-networking',
    '--disable-component-update',
    '--disable-features=Translate,OptimizationHints,MediaRouter',
    ...extraArgs,
    'about:blank',
  ];
  const child = spawn(chromePath, args, { stdio: ['ignore', 'ignore', 'ignore', 'pipe', 'pipe'], windowsHide: true });
  return new Browser(child);
}
