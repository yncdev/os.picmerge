/** 화면 표시용 형식. lib/shared/format.dart와 같다. */
export function formatBytes(bytes) {
  if (bytes >= 1000 * 1000) return `${(bytes / (1000 * 1000)).toFixed(1)}MB`;
  if (bytes >= 1000) return `${Math.round(bytes / 1000)}KB`;
  return `${bytes}B`;
}

export function formatDateTime(time) {
  const two = (value) => String(value).padStart(2, '0');
  return (
    `${time.getFullYear()}-${two(time.getMonth() + 1)}-${two(time.getDate())} ` +
    `${two(time.getHours())}:${two(time.getMinutes())}`
  );
}
