/// `YYYYMMDDHHMI` (DESIGN §2.1.4). [time]은 기기 현지 시각이고 HHMI는 24시간제 시·분이다.
String baseFileName(DateTime time) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${time.year.toString().padLeft(4, '0')}${two(time.month)}${two(time.day)}'
      '${two(time.hour)}${two(time.minute)}';
}

/// `{base}_{n}.{extension}`에서 비어 있는 가장 작은 n을 고른다. n은 1부터이고 자릿수를 채우지 않는다.
/// 확장자가 다르면 연번을 따로 센다. 대소문자는 구분하지 않는다
/// (FAT 계열 저장소는 대소문자만 다른 이름을 같은 파일로 본다).
String resolveFileName(String base, String extension, Iterable<String> existingNames) {
  final taken = {for (final name in existingNames) name.toLowerCase()};
  for (var n = 1;; n++) {
    final candidate = '${base}_$n.$extension';
    if (!taken.contains(candidate.toLowerCase())) return candidate;
  }
}
