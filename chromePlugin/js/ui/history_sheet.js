import { historyStore } from '../data/history_store.js';
import { formatBytes, formatDateTime } from '../domain/format.js';
import { kHistoryRateDays } from '../domain/limits.js';
import { SessionStatus, successRate } from '../domain/history_model.js';
import { byId, h } from './dom.js';
import { t } from './i18n.js';
import { destinationLabel, errorMessage, statusLabel } from './labels.js';

function renderSession(session) {
  const details = [
    formatDateTime(new Date(session.startedAt)),
    String(session.format).toUpperCase(),
    t('history_count', session.count),
    destinationLabel(session.destination, session.customFolder),
  ];
  if (session.status === SessionStatus.success && session.bytes != null) details.push(formatBytes(session.bytes));

  return h(
    'li',
    { class: 'history-item' },
    h('span', { class: `status status-${session.status}` }, statusLabel(session.status)),
    h(
      'div',
      { class: 'meta' },
      h('div', { class: 'name', title: session.fileName ?? '' }, session.fileName ?? statusLabel(session.status)),
      h('div', { class: 'sub' }, details.filter(Boolean).join(' · ')),
      session.errorCode ? h('div', { class: 'sub error' }, errorMessage(session.errorCode)) : null,
    ),
  );
}

/** 최근 기록 (DESIGN §2.2). 읽기 전용. */
export function openHistorySheet() {
  const sessions = historyStore.all();
  const rate = successRate(sessions, new Date());
  byId('history-rate').textContent =
    rate.ratio === null
      ? t('history_rate_none', kHistoryRateDays)
      : t('history_rate', kHistoryRateDays, Math.round(rate.ratio * 100), rate.success, rate.total);
  const list = byId('history-list');
  list.replaceChildren(...sessions.map(renderSession));
  byId('history-empty').hidden = sessions.length > 0;
  byId('history-dialog').showModal();
}
