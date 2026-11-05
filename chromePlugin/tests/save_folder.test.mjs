// 저장 폴더 (DESIGN §2.1.4, §5.2). 폴더 핸들과 저장소는 가짜다. 실제 선택기와 권한 창은 사람이 확인해야 한다.
import assert from 'node:assert/strict';
import { afterEach, describe, test } from 'node:test';

import {
  canPickFolder,
  createFolderStore,
  ensureFolderAccess,
  FolderAccess,
  PICKER_OPTIONS,
  pickFolder,
  writeToFolder,
} from '../js/data/save_folder_store.js';
import { ErrorCode, folderErrorCode, MergeError } from '../js/domain/errors.js';
import { defaultFolderNames } from '../js/domain/history_model.js';

const NOW = new Date(2026, 9, 30, 15, 36);
const STAMP = '202610301536';

const domError = (name) => Object.assign(new Error(name), { name });

/** 호출 순서를 남기는 가짜 폴더. [failures]에 적은 단계에서 그 오류를 던진다. */
function fakeFolder(names = [], { failures = {}, permission = 'granted', requestResult = 'granted' } = {}) {
  const entries = new Map(names.map((name) => [name, 'existing']));
  const log = [];
  const fail = (step) => {
    log.push(step);
    if (failures[step]) throw failures[step];
  };
  const handle = {
    kind: 'directory',
    name: 'folder',
    keys: () =>
      (async function* keys() {
        fail('keys');
        yield* [...entries.keys()];
      })(),
    async queryPermission(options) {
      fail(`query:${options.mode}`);
      return permission;
    },
    async requestPermission(options) {
      fail(`request:${options.mode}`);
      return requestResult;
    },
    async getFileHandle(name, options) {
      fail(`open:${name}:${options.create}`);
      if (!entries.has(name)) entries.set(name, 'empty');
      return {
        async createWritable() {
          fail('createWritable');
          let pending = null;
          return {
            async write(data) {
              fail('write');
              pending = data;
            },
            async close() {
              fail('close');
              entries.set(name, pending);
            },
            async abort() {
              fail('abort');
            },
          };
        },
      };
    },
    async removeEntry(name) {
      fail(`remove:${name}`);
      entries.delete(name);
    },
  };
  return { handle, entries, log };
}

describe('폴더 권한 확인', () => {
  test('이미 있으면 다시 묻지 않는다', async () => {
    const { handle, log } = fakeFolder();
    assert.equal(await ensureFolderAccess(handle), FolderAccess.granted);
    assert.deepEqual(log, ['query:readwrite', 'keys']);
  });
  test('없으면 query 다음에 request를 부르고, 받으면 쓴다', async () => {
    const { handle, log } = fakeFolder([], { permission: 'prompt', requestResult: 'granted' });
    assert.equal(await ensureFolderAccess(handle), FolderAccess.granted);
    assert.deepEqual(log, ['query:readwrite', 'request:readwrite', 'keys']);
  });
  test('거절하면 denied이고 폴더를 읽지 않는다', async () => {
    const { handle, log } = fakeFolder([], { permission: 'prompt', requestResult: 'denied' });
    assert.equal(await ensureFolderAccess(handle), FolderAccess.denied);
    assert.deepEqual(log, ['query:readwrite', 'request:readwrite']);
  });
  test('제스처가 없어 request가 실패해도 denied다', async () => {
    const { handle } = fakeFolder([], { permission: 'prompt', failures: { 'request:readwrite': domError('SecurityError') } });
    assert.equal(await ensureFolderAccess(handle), FolderAccess.denied);
  });
  test('폴더가 지워졌으면 gone이다', async () => {
    const { handle } = fakeFolder([], { failures: { keys: domError('NotFoundError') } });
    assert.equal(await ensureFolderAccess(handle), FolderAccess.gone);
  });
});

describe('폴더에 쓰기', () => {
  test('비어 있으면 _1이고 내용을 쓴 뒤 닫는다', async () => {
    const { handle, entries, log } = fakeFolder();
    assert.equal(await writeToFolder(handle, NOW, 'png', 'bytes'), `${STAMP}_1.png`);
    assert.equal(entries.get(`${STAMP}_1.png`), 'bytes');
    assert.deepEqual(log, ['keys', `open:${STAMP}_1.png:true`, 'createWritable', 'write', 'close']);
  });
  test('실제 항목을 보고 비어 있는 가장 작은 연번을 쓴다', async () => {
    const { handle } = fakeFolder([`${STAMP}_1.png`, `${STAMP}_3.png`, 'other.png']);
    assert.equal(await writeToFolder(handle, NOW, 'png', 'bytes'), `${STAMP}_2.png`);
  });
  test('확장자가 다르면 같은 연번을 쓴다', async () => {
    const { handle } = fakeFolder([`${STAMP}_1.png`]);
    assert.equal(await writeToFolder(handle, NOW, 'pdf', 'bytes'), `${STAMP}_1.pdf`);
  });
  test('있는 파일을 건드리지 않는다', async () => {
    const { handle, entries } = fakeFolder([`${STAMP}_1.png`]);
    await writeToFolder(handle, NOW, 'png', 'bytes');
    assert.equal(entries.get(`${STAMP}_1.png`), 'existing');
  });

  const failingAt = async (step, error, names = []) => {
    const folder = fakeFolder(names, { failures: { [step]: error } });
    const caught = await writeToFolder(folder.handle, NOW, 'png', 'bytes').catch((e) => e);
    return { ...folder, caught };
  };

  test('쓰다가 실패하면 스트림을 버리고 새 항목을 지운다', async () => {
    const { entries, log, caught } = await failingAt('write', domError('QuotaExceededError'));
    assert.ok(caught instanceof MergeError);
    assert.equal(caught.code, ErrorCode.outOfSpace);
    assert.ok(log.includes('abort'));
    assert.ok(log.includes(`remove:${STAMP}_1.png`));
    assert.equal(entries.size, 0);
  });
  test('닫다가 실패해도 같다', async () => {
    const { entries, log, caught } = await failingAt('close', domError('QuotaExceededError'));
    assert.equal(caught.code, ErrorCode.outOfSpace);
    assert.ok(log.includes('abort'));
    assert.equal(entries.size, 0);
  });
  test('스트림을 못 열면 abort 없이 새 항목만 지운다', async () => {
    const { entries, log, caught } = await failingAt('createWritable', domError('NoModificationAllowedError'));
    assert.equal(caught.code, ErrorCode.folderUnavailable);
    assert.ok(!log.includes('abort'));
    assert.ok(log.includes(`remove:${STAMP}_1.png`));
    assert.equal(entries.size, 0);
  });
  test('항목을 만들지 못했으면 지우지 않는다', async () => {
    const { log, caught } = await failingAt(`open:${STAMP}_1.png:true`, domError('NotAllowedError'));
    assert.equal(caught.code, ErrorCode.folderUnavailable);
    assert.ok(!log.some((step) => step.startsWith('remove:')));
  });
  test('폴더를 읽지 못하면 아무것도 만들지 않는다', async () => {
    const { log, caught } = await failingAt('keys', domError('NotFoundError'));
    assert.equal(caught.code, ErrorCode.folderUnavailable);
    assert.deepEqual(log, ['keys']);
  });
  test('실패해도 먼저 있던 파일은 남는다', async () => {
    const { entries } = await failingAt('write', domError('QuotaExceededError'), [`${STAMP}_1.png`]);
    assert.deepEqual([...entries.keys()], [`${STAMP}_1.png`]);
  });
  test('정리가 실패해도 원래 오류를 알린다', async () => {
    const folder = fakeFolder([], {
      failures: { write: domError('QuotaExceededError'), abort: domError('TypeError'), [`remove:${STAMP}_1.png`]: domError('NotFoundError') },
    });
    const caught = await writeToFolder(folder.handle, NOW, 'png', 'bytes').catch((e) => e);
    assert.equal(caught.code, ErrorCode.outOfSpace);
  });
});

describe('폴더 오류 코드', () => {
  const cases = [
    ['QuotaExceededError', 'out_of_space'],
    ['NotAllowedError', 'folder_unavailable'],
    ['SecurityError', 'folder_unavailable'],
    ['NotFoundError', 'folder_unavailable'],
    ['NoModificationAllowedError', 'folder_unavailable'],
    ['InvalidStateError', 'folder_unavailable'],
    ['TypeError', 'unknown'],
  ];
  for (const [name, code] of cases) {
    test(`${name} → ${code}`, () => assert.equal(folderErrorCode(domError(name)), code));
  }
  test('이름이 없는 값은 unknown', () => {
    assert.equal(folderErrorCode(null), 'unknown');
    assert.equal(folderErrorCode('text'), 'unknown');
  });
});

describe('폴더 기억', () => {
  const memory = () => {
    const values = new Map();
    return {
      values,
      get: async (key) => values.get(key),
      set: async (key, value) => void values.set(key, value),
      delete: async (key) => void values.delete(key),
    };
  };
  const folder = { kind: 'directory', name: 'x' };

  test('처음에는 없다', async () => {
    assert.equal(await createFolderStore(memory()).load(), null);
  });
  test('저장한 핸들을 그대로 돌려준다', async () => {
    const store = createFolderStore(memory());
    await store.save(folder);
    assert.equal(await store.load(), folder);
  });
  test('지우면 다시 없다', async () => {
    const store = createFolderStore(memory());
    await store.save(folder);
    await store.clear();
    assert.equal(await store.load(), null);
  });
  test('폴더가 아닌 값은 버린다', async () => {
    const storage = memory();
    await storage.set('saveFolder', { kind: 'file', name: 'x' });
    assert.equal(await createFolderStore(storage).load(), null);
  });
  test('저장소 오류는 저장을 막지 않는다', async () => {
    const broken = {
      get: async () => {
        throw new Error('broken');
      },
      set: async () => {
        throw new Error('broken');
      },
      delete: async () => {
        throw new Error('broken');
      },
    };
    const store = createFolderStore(broken);
    assert.equal(await store.load(), null);
    await store.save(folder);
    await store.clear();
  });
});

describe('폴더 선택기', () => {
  afterEach(() => {
    delete globalThis.showDirectoryPicker;
  });

  test('지원하지 않으면 canPickFolder가 false다', () => {
    assert.equal(canPickFolder(), false);
  });
  test('옵션을 그대로 넘긴다', async () => {
    const calls = [];
    globalThis.showDirectoryPicker = async (options) => {
      calls.push(options);
      return 'handle';
    };
    assert.equal(canPickFolder(), true);
    assert.equal(await pickFolder(), 'handle');
    assert.deepEqual(calls, [{ id: 'picmerge', mode: 'readwrite', startIn: 'downloads' }]);
    assert.deepEqual({ ...PICKER_OPTIONS }, calls[0]);
  });
  test('사용자가 닫으면 오류 없이 null이다', async () => {
    globalThis.showDirectoryPicker = async () => {
      throw domError('AbortError');
    };
    assert.equal(await pickFolder(), null);
  });
  test('다른 오류는 알린다', async () => {
    globalThis.showDirectoryPicker = async () => {
      throw domError('SecurityError');
    };
    await assert.rejects(pickFolder(), { name: 'SecurityError' });
  });
});

describe('기본 폴더 연번에 쓰는 이름', () => {
  test('기본 폴더와 공유 기록만 센다. 고른 폴더의 기록은 그 폴더에 있다', () => {
    const names = defaultFolderNames([
      { destination: 'download', fileName: 'a.png' },
      { destination: 'share', fileName: 'b.png' },
      { destination: '다운로드', fileName: 'old_download.png' },
      { destination: '공유', fileName: 'old_share.png' },
      { destination: 'photos', customFolder: true, fileName: 'c.png' },
      { destination: 'download', status: 'running' },
    ]);
    assert.deepEqual(names, ['a.png', 'b.png', 'old_download.png', 'old_share.png']);
  });
  test('이름이 download인 폴더도 고른 폴더로 센다', () => {
    assert.deepEqual(defaultFolderNames([{ destination: 'download', customFolder: true, fileName: 'c.png' }]), []);
  });
});
