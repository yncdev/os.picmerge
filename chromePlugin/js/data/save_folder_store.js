import { folderErrorCode, MergeError } from '../domain/errors.js';
import { uniqueFileName } from '../domain/file_naming.js';

// 사용자가 고른 저장 폴더 (DESIGN §2.1.4, §5.2). 권한 선언 없이 File System Access API만 쓴다.
// 브라우저 API는 부를 때 찾는다. 단위 테스트는 저장소와 폴더 핸들을 가짜로 넣어 Node에서 돈다.

const DB_NAME = 'picmerge';
const STORE_NAME = 'settings';
const FOLDER_KEY = 'saveFolder';
const READ_WRITE = Object.freeze({ mode: 'readwrite' });

/** 다운로드 폴더에서 시작한다. 그 폴더 자체는 Chrome이 고르지 못하게 막는다 (DESIGN §5.2). */
export const PICKER_OPTIONS = Object.freeze({ id: 'picmerge', mode: 'readwrite', startIn: 'downloads' });

export const FolderAccess = Object.freeze({
  granted: 'granted',
  denied: 'denied',
  gone: 'gone',
});

function opened() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, 1);
    request.onupgradeneeded = () => request.result.createObjectStore(STORE_NAME);
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

async function transact(mode, action) {
  const db = await opened();
  try {
    return await new Promise((resolve, reject) => {
      const transaction = db.transaction(STORE_NAME, mode);
      const request = action(transaction.objectStore(STORE_NAME));
      transaction.oncomplete = () => resolve(request.result);
      transaction.onerror = () => reject(transaction.error);
      transaction.onabort = () => reject(transaction.error);
    });
  } finally {
    db.close();
  }
}

/** 폴더 핸들은 구조화 복제가 되어 IndexedDB에 그대로 넣을 수 있다. localStorage에는 넣을 수 없다. */
const indexedDbStorage = Object.freeze({
  get: (key) => transact('readonly', (store) => store.get(key)),
  set: (key, value) => transact('readwrite', (store) => store.put(value, key)),
  delete: (key) => transact('readwrite', (store) => store.delete(key)),
});

/**
 * 고른 폴더를 기억한다. 기록과 마찬가지로 저장소 오류가 저장 자체를 막지 않게 삼키고 콘솔에만 남긴다.
 * 쓰기에 실패하면 그 폴더는 이번 실행 동안만 쓰인다.
 */
export function createFolderStore(storage = indexedDbStorage) {
  return {
    async load() {
      try {
        const handle = await storage.get(FOLDER_KEY);
        return handle?.kind === 'directory' ? handle : null;
      } catch (error) {
        console.warn('save folder read failed', error);
        return null;
      }
    },
    async save(handle) {
      try {
        await storage.set(FOLDER_KEY, handle);
      } catch (error) {
        console.warn('save folder write failed', error);
      }
    },
    async clear() {
      try {
        await storage.delete(FOLDER_KEY);
      } catch (error) {
        console.warn('save folder clear failed', error);
      }
    },
  };
}

export const folderStore = createFolderStore();

/** 이 브라우저가 폴더 선택기를 지원하는가. 없으면 '다른 폴더 고르기'를 숨긴다. */
export function canPickFolder() {
  return typeof globalThis.showDirectoryPicker === 'function';
}

/** 폴더 선택기를 연다. 사용자가 닫으면 null이다. Chrome이 막는 폴더는 선택기 안에서 Chrome이 안내한다. */
export async function pickFolder() {
  try {
    return await globalThis.showDirectoryPicker({ ...PICKER_OPTIONS });
  } catch (error) {
    if (error?.name === 'AbortError') return null;
    throw error;
  }
}

/**
 * 합성을 시작하기 전에 폴더를 쓸 수 있는지 본다 (DESIGN §2.1.4).
 * requestPermission은 사용자 제스처가 살아 있을 때만 되므로 저장 버튼을 누른 직후에 부른다.
 * @returns {Promise<'granted'|'denied'|'gone'>}
 */
export async function ensureFolderAccess(handle) {
  try {
    let permission = await handle.queryPermission(READ_WRITE);
    if (permission !== 'granted') permission = await handle.requestPermission(READ_WRITE);
    if (permission !== 'granted') return FolderAccess.denied;
  } catch (error) {
    console.warn('save folder permission failed', error);
    return FolderAccess.denied;
  }
  try {
    // 폴더가 지워졌으면 항목을 읽을 때 오류가 난다.
    await handle.keys().next();
    return FolderAccess.granted;
  } catch (error) {
    console.warn('save folder is gone', error);
    return FolderAccess.gone;
  }
}

/** 정리 중의 오류가 원래 오류를 가리지 않게 한다. */
async function quietly(action) {
  try {
    await action();
  } catch (error) {
    console.warn('save folder cleanup failed', error);
  }
}

/**
 * 폴더의 실제 항목을 보고 연번을 정해 쓴다 (DESIGN §2.1.4). 실패하면 쓰다 만 내용을 버리고 새로 만든 빈 항목을 지운다.
 * @param {Date} time 합성이 끝난 시각
 * @returns {Promise<string>} 실제로 쓴 파일 이름
 * @throws {MergeError} `out_of_space`, `folder_unavailable`, `unknown`
 */
export async function writeToFolder(handle, time, extension, blob) {
  let fileName = null;
  let created = false;
  let writable = null;
  try {
    const names = [];
    for await (const name of handle.keys()) names.push(name);
    fileName = uniqueFileName(time, extension, names);
    const entry = await handle.getFileHandle(fileName, { create: true });
    created = true;
    writable = await entry.createWritable();
    await writable.write(blob);
    await writable.close();
    return fileName;
  } catch (error) {
    if (writable) await quietly(() => writable.abort());
    if (created) await quietly(() => handle.removeEntry(fileName));
    throw new MergeError(folderErrorCode(error), { detail: `${error?.name}: ${error?.message}` });
  }
}
