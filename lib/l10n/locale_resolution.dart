import 'dart:ui';

const _englishLocale = Locale('en');
const _traditionalChineseLocale = Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
const _traditionalChineseCountries = {'TW', 'HK', 'MO'};

/// 기기 언어 목록에서 처음으로 지원되는 언어를 고른다. 없으면 English다 (DESIGN §2.2, §3.1).
/// 기본 규칙은 목록의 첫 언어(알파벳순 de)로 떨어지므로 직접 정한다.
///
/// Android의 옛 언어 코드 `in`은 [Locale]이 스스로 `id`로 바꾼다.
Locale resolveAppLocale(List<Locale>? preferred, Iterable<Locale> supported) {
  for (final locale in preferred ?? const <Locale>[]) {
    if (locale.languageCode == 'zh') {
      // 글자 체계를 직접 고른 경우가 나라보다 우선이다. 홍콩에서 간체를 고르면 간체다.
      final traditional = switch (locale.scriptCode) {
        'Hant' => true,
        'Hans' => false,
        _ => _traditionalChineseCountries.contains(locale.countryCode),
      };
      return traditional ? _traditionalChineseLocale : const Locale('zh');
    }
    if (supported.any((s) => s.languageCode == locale.languageCode)) {
      return Locale(locale.languageCode);
    }
  }
  return _englishLocale;
}
