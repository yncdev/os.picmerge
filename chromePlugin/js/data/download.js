// 다운로드가 시작되기 전에 해제하면 실패하므로 충분히 뒤에 해제한다.
const REVOKE_DELAY_MS = 60000;

/** 브라우저 다운로드로 저장한다 (DESIGN §5.2). 권한이 필요 없다. */
export function downloadBlob(blob, fileName) {
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = fileName;
  document.body.append(link);
  link.click();
  link.remove();
  setTimeout(() => URL.revokeObjectURL(url), REVOKE_DELAY_MS);
}
