import { ErrorCode } from '../domain/errors.js';
import { Destination, SessionStatus } from '../domain/history_model.js';
import { LayoutDirection } from '../domain/layout_direction.js';
import { t } from './i18n.js';

// Domain이 돌려주는 코드를 화면 문구로 옮긴다. Domain에는 문구를 두지 않는다.

/** 모든 언어에서 같다 (DESIGN §2.2). */
export const APP_NAME = 'Pic Merge';

/** 문서 제목. 부제가 있는 언어는 이름 뒤에 붙인다. */
export function appTitle() {
  const subtitle = t('app_subtitle');
  return subtitle ? `${APP_NAME} ${subtitle}` : APP_NAME;
}

/** 사용자에게 보여줄 오류 문구 (DESIGN §3.4). [imageNumber]는 1부터 센다. */
export function errorMessage(code, imageNumber = null) {
  const n = imageNumber;
  switch (code) {
    case ErrorCode.unsupportedFormat:
      return n == null ? t('error_unsupported_format') : t('error_unsupported_format_n', n);
    case ErrorCode.corruptFile:
      return n == null ? t('error_corrupt_file') : t('error_corrupt_file_n', n);
    case ErrorCode.sourceUnavailable:
      return n == null ? t('error_source_unavailable') : t('error_source_unavailable_n', n);
    case ErrorCode.outOfSpace:
      return t('error_out_of_space');
    case ErrorCode.folderUnavailable:
      return t('error_folder_unavailable');
    case ErrorCode.outputTooLarge:
      return t('error_output_too_large');
    case ErrorCode.outOfMemory:
      return t('error_out_of_memory');
    default:
      return t('error_unknown');
  }
}

/** 안내 문구. 예: "자동: 가로 배치 (왼쪽 → 오른쪽)" */
export function directionText(direction) {
  return direction === LayoutDirection.vertical ? t('direction_vertical') : t('direction_horizontal');
}

const PAPER_LABELS = Object.freeze({
  a4: () => t('paper_a4'),
  a3: () => t('paper_a3'),
  a5: () => t('paper_a5'),
  b4: () => t('paper_b4'),
  b5: () => t('paper_b5'),
  letter: () => t('paper_letter'),
  legal: () => t('paper_legal'),
  original: () => t('paper_original'),
});

export function paperLabel(code) {
  return PAPER_LABELS[code]();
}

const STATUS_LABELS = Object.freeze({
  [SessionStatus.running]: () => t('status_running'),
  [SessionStatus.success]: () => t('status_success'),
  [SessionStatus.failed]: () => t('status_failed'),
  [SessionStatus.cancelled]: () => t('status_cancelled'),
  [SessionStatus.crashed]: () => t('status_crashed'),
});

export function statusLabel(status) {
  return STATUS_LABELS[status]?.() ?? status;
}

// 이전 버전은 표식을 한국어로 남겼다. 이미 쌓인 기록도 사용자 언어로 보여준다.
const LEGACY_SHARE = '공유';
const LEGACY_DOWNLOAD = '다운로드';

/** 고른 폴더의 기록은 폴더 이름을 그대로 보여준다. 이름이 download여도 번역하지 않는다. */
export function destinationLabel(destination, customFolder = false) {
  if (customFolder) return destination;
  if (destination === Destination.share || destination === LEGACY_SHARE) return t('share');
  if (destination === Destination.download || destination === LEGACY_DOWNLOAD) return t('share_download');
  return destination;
}

/** 하단 막대의 저장 위치. [folderName]이 null이면 기본 폴더다. */
export function saveLocationText(folderName) {
  return folderName === null ? t('save_location_default') : t('save_location_custom', folderName);
}

/** 미리보기 안내. PNG가 페이지를 잇는 방향과 구분선, PDF는 페이지별로 저장되고 선이 없다는 것을 알린다 (DESIGN §2.2). */
export function previewNote(direction, onPaper) {
  if (!onPaper) return t('preview_note_original');
  return direction === LayoutDirection.vertical ? t('preview_note_vertical') : t('preview_note_horizontal');
}
