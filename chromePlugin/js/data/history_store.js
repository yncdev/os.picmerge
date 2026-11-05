import {
  addSession,
  markRunningAsCrashed,
  SessionStatus,
  updateSession,
} from '../domain/history_model.js';

const KEY = 'picmerge.sessions';

// 기록 실패가 저장 결과를 가리지 않게 한다. 쓰기·읽기 오류는 삼키고 콘솔에만 남긴다.
function read() {
  try {
    const parsed = JSON.parse(localStorage.getItem(KEY) ?? '[]');
    return Array.isArray(parsed) ? parsed : [];
  } catch (error) {
    console.warn('history read failed', error);
    return [];
  }
}

function write(sessions) {
  try {
    localStorage.setItem(KEY, JSON.stringify(sessions));
  } catch (error) {
    console.warn('history write failed', error);
  }
}

let lastId = 0;

/** localStorage에 메타데이터만 둔다 (DESIGN §5.2). 원본 파일이나 경로는 저장하지 않는다. */
export const historyStore = {
  all: read,

  /** 앱을 시작할 때 부른다. `crashed`로 바꾼 세션 수를 돌려준다. */
  markRunningAsCrashed() {
    const { sessions, crashed } = markRunningAsCrashed(read());
    if (crashed > 0) write(sessions);
    return crashed;
  },

  /** @returns {number} 세션 id */
  start({ format, direction, count, destination, customFolder = false }) {
    lastId = Math.max(lastId + 1, Date.now());
    write(
      addSession(read(), {
        id: lastId,
        startedAt: new Date().toISOString(),
        status: SessionStatus.running,
        format,
        direction,
        count,
        destination,
        // 폴더 이름이 표식과 같아도 구분되도록 따로 둔다. 표식은 번역하고 폴더 이름은 그대로 보여준다.
        ...(customFolder ? { customFolder: true } : {}),
      }),
    );
    return lastId;
  },

  finishSuccess(id, { fileName, bytes, width = null, height = null }) {
    write(
      updateSession(read(), id, {
        status: SessionStatus.success,
        finishedAt: new Date().toISOString(),
        fileName,
        bytes,
        width,
        height,
      }),
    );
  },

  finishFailure(id, errorCode) {
    write(updateSession(read(), id, { status: SessionStatus.failed, finishedAt: new Date().toISOString(), errorCode }));
  },

  finishCancelled(id) {
    write(updateSession(read(), id, { status: SessionStatus.cancelled, finishedAt: new Date().toISOString() }));
  },
};
