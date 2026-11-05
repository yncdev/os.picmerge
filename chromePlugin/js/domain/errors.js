/** DESIGN §3.4 오류 코드. `folder_unavailable`은 사용자가 고른 저장 폴더에만 생긴다 (DESIGN §2.1.4). */
export const ErrorCode = Object.freeze({
  unsupportedFormat: 'unsupported_format',
  corruptFile: 'corrupt_file',
  sourceUnavailable: 'source_unavailable',
  outOfSpace: 'out_of_space',
  folderUnavailable: 'folder_unavailable',
  outputTooLarge: 'output_too_large',
  outOfMemory: 'out_of_memory',
  unknown: 'unknown',
});

/** File System Access API 오류를 §3.4 코드로 바꾼다. */
export function folderErrorCode(error) {
  switch (error?.name) {
    case 'QuotaExceededError':
      return ErrorCode.outOfSpace;
    case 'NotAllowedError':
    case 'SecurityError':
    case 'NotFoundError':
    case 'NoModificationAllowedError':
    case 'InvalidStateError':
      return ErrorCode.folderUnavailable;
    default:
      return ErrorCode.unknown;
  }
}

export class MergeError extends Error {
  constructor(code, { imageNumber = null, detail = null } = {}) {
    super(`${code}${imageNumber == null ? '' : ` (image ${imageNumber})`}${detail ? `: ${detail}` : ''}`);
    this.name = 'MergeError';
    this.code = code;
    this.imageNumber = imageNumber;
  }
}

/** 사용자가 취소함. 오류가 아니다 (DESIGN §3.4). */
export class MergeCancelled extends Error {
  constructor() {
    super('cancelled');
    this.name = 'MergeCancelled';
  }
}
