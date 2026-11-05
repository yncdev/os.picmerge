// Chrome Web Store에 올릴 zip을 만든다. 의존성이 없다.
//
//   node tool/package_chrome.mjs
//
// build/chrome-web-store/pic-merge-<version>.zip. 맨 위에 manifest.json이 있고 경로는 슬래시다.
// tests/, README.md, 숨김 파일은 뺀다. NOTICE.md와 vendor/의 라이선스 파일은 남긴다.
// Windows의 Git Bash tar는 zip을 만들지 못해 System32의 tar.exe를 쓴다.
import { execFileSync } from 'node:child_process';
import { copyFileSync, mkdirSync, mkdtempSync, readdirSync, readFileSync, rmSync, statSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const repo = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const source = join(repo, 'chromePlugin');
const { version } = JSON.parse(readFileSync(join(source, 'manifest.json'), 'utf8'));
if (!/^\d+(\.\d+){0,3}$/.test(version)) throw new Error(`bad manifest version: ${version}`);
const outDir = join(repo, 'build', 'chrome-web-store');
const zipPath = join(outDir, `pic-merge-${version}.zip`);

/** @param {string} path 확장 폴더 기준 슬래시 경로 */
function isIncluded(path) {
  const parts = path.split('/');
  if (parts[0] === 'tests') return false;
  if (path === 'README.md') return false;
  return !parts.some((part) => part.startsWith('.'));
}

function walk(dir) {
  return readdirSync(dir).flatMap((name) => {
    const path = join(dir, name);
    return statSync(path).isDirectory() ? walk(path) : [relative(source, path).split(sep).join('/')];
  });
}

/** zip 끝의 중앙 디렉터리를 직접 읽는다. 만든 도구의 말을 믿지 않고 파일로 확인한다. */
function zipEntries(path) {
  const bytes = readFileSync(path);
  let end = bytes.length - 22;
  while (end >= 0 && bytes.readUInt32LE(end) !== 0x06054b50) end--;
  if (end < 0) throw new Error('zip end record not found');
  const count = bytes.readUInt16LE(end + 10);
  let at = bytes.readUInt32LE(end + 16);
  const names = [];
  for (let i = 0; i < count; i++) {
    if (bytes.readUInt32LE(at) !== 0x02014b50) throw new Error(`bad central directory entry ${i}`);
    const nameLength = bytes.readUInt16LE(at + 28);
    const extraLength = bytes.readUInt16LE(at + 30);
    const commentLength = bytes.readUInt16LE(at + 32);
    names.push(bytes.toString('utf8', at + 46, at + 46 + nameLength));
    at += 46 + nameLength + extraLength + commentLength;
  }
  return names;
}

const all = walk(source);
const included = all.filter(isIncluded).sort();
const required = ['manifest.json', 'NOTICE.md', 'app.html', 'background.js', '_locales/en/messages.json'];
for (const path of required) {
  if (!included.includes(path)) throw new Error(`missing required file: ${path}`);
}

mkdirSync(outDir, { recursive: true });
rmSync(zipPath, { force: true });
const staging = mkdtempSync(join(tmpdir(), 'picmerge-package-'));
try {
  for (const path of included) {
    const target = join(staging, path);
    mkdirSync(dirname(target), { recursive: true });
    copyFileSync(join(source, path), target);
  }
  const topLevel = readdirSync(staging).sort();
  if (process.platform === 'win32') {
    const tar = join(process.env.SystemRoot ?? 'C:/Windows', 'System32', 'tar.exe');
    execFileSync(tar, ['-a', '-c', '-f', zipPath, ...topLevel], { cwd: staging, stdio: ['ignore', 'ignore', 'inherit'] });
  } else {
    execFileSync('zip', ['-r', '-X', '-q', zipPath, ...topLevel], { cwd: staging, stdio: ['ignore', 'ignore', 'inherit'] });
  }
} finally {
  rmSync(staging, { recursive: true, force: true, maxRetries: 8, retryDelay: 200 });
}

// 만든 파일을 다시 읽어 확인한다.
const entries = zipEntries(zipPath);
const files = entries.filter((name) => !name.endsWith('/')).sort();
const problems = [];
if (!entries.includes('manifest.json')) problems.push('manifest.json is not at the zip root');
for (const name of entries) {
  if (name.includes('\\')) problems.push(`backslash in path: ${name}`);
  if (name.startsWith('/') || name.split('/').includes('..')) problems.push(`unsafe path: ${name}`);
  if (name.startsWith('tests/')) problems.push(`tests in zip: ${name}`);
  if (name === 'README.md') problems.push('README.md in zip');
  if (name.split('/').some((part) => part.startsWith('.'))) problems.push(`hidden file in zip: ${name}`);
}
const missing = included.filter((path) => !files.includes(path));
const extra = files.filter((path) => !included.includes(path));
if (missing.length) problems.push(`missing from zip: ${missing.slice(0, 5).join(', ')}`);
if (extra.length) problems.push(`unexpected in zip: ${extra.slice(0, 5).join(', ')}`);
const licenses = all.filter((path) => path.startsWith('vendor/') && /licen[sc]e/i.test(path));
if (licenses.length === 0) problems.push('no license files found under vendor/');
for (const path of licenses) {
  if (!files.includes(path)) problems.push(`license missing from zip: ${path}`);
}
if (problems.length) {
  rmSync(zipPath, { force: true });
  throw new Error(`package check failed:\n  ${problems.join('\n  ')}`);
}

const excluded = all.filter((path) => !isIncluded(path));
console.log(`Package: ${zipPath}`);
console.log(`Version: ${version}, ${statSync(zipPath).size} bytes`);
console.log(`Files: ${files.length} in zip, ${excluded.length} excluded`);
console.log(`Root: ${[...new Set(files.map((name) => name.split('/')[0]))].sort().join(' ')}`);
console.log(`Excluded: ${[...new Set(excluded.map((name) => name.split('/')[0]))].sort().join(' ')}`);
console.log(`License files kept under vendor/: ${licenses.length}`);
