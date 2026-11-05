/// 화면 표시용 형식. 숫자와 단위뿐이라 언어와 무관하게 같은 모양으로 둔다.
String formatBytes(int bytes) {
  if (bytes >= 1000 * 1000) return '${(bytes / (1000 * 1000)).toStringAsFixed(1)}MB';
  if (bytes >= 1000) return '${(bytes / 1000).round()}KB';
  return '${bytes}B';
}

String formatDateTime(DateTime t) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
}
