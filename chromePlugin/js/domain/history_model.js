import { kHistoryLimit, kHistoryRateDays } from './limits.js';

// 세션 = 저장·공유 시도 1회 (DESIGN §3.2). 메타데이터만 다룬다. 저장은 data/history_store.js가 한다.

export const SessionStatus = Object.freeze({
  running: 'running',
  success: 'success',
  failed: 'failed',
  cancelled: 'cancelled',
  crashed: 'crashed',
});

/** 저장·공유 표식. 언어와 무관하다. 화면 문구는 ui/labels.js가 옮긴다 (DESIGN §2.1.7). */
export const Destination = Object.freeze({
  download: 'download',
  share: 'share',
});

/**
 * 기본 폴더에 있을 이름들. 기본 경로는 폴더 안을 볼 수 없어 기록으로 대신한다 (DESIGN §5.2).
 * 고른 폴더에 저장한 기록은 그 폴더에 있으니 세지 않는다. 그래도 겹치면 브라우저가 번호를 붙인다.
 */
export function defaultFolderNames(sessions) {
  return sessions.filter((s) => s.fileName && !s.customFolder).map((s) => s.fileName);
}

/** 최신이 앞. 상한을 넘으면 오래된 것부터 버린다. */
export function addSession(sessions, session, limit = kHistoryLimit) {
  return [session, ...sessions].slice(0, limit);
}

export function updateSession(sessions, id, patch) {
  return sessions.map((s) => (s.id === id ? { ...s, ...patch } : s));
}

/** 앱 시작 때: 강제 종료로 `running`에 남은 세션을 `crashed`로 바꾼다 (DESIGN §3.4). */
export function markRunningAsCrashed(sessions) {
  let crashed = 0;
  const next = sessions.map((s) => {
    if (s.status !== SessionStatus.running) return s;
    crashed++;
    return { ...s, status: SessionStatus.crashed };
  });
  return { sessions: next, crashed };
}

/** 최근 [days]일 성공률. 진행 중인 세션은 세지 않는다. 기록이 없으면 ratio는 null이다. */
export function successRate(sessions, now, days = kHistoryRateDays) {
  const since = now.getTime() - days * 24 * 60 * 60 * 1000;
  const counted = sessions.filter(
    (s) => s.status !== SessionStatus.running && new Date(s.startedAt).getTime() >= since,
  );
  const success = counted.filter((s) => s.status === SessionStatus.success).length;
  const total = counted.length;
  return { success, total, ratio: total === 0 ? null : success / total };
}
