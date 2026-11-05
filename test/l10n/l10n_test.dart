import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_merger/core/errors/merge_exception.dart';
import 'package:image_merger/features/image_merger/domain/layout_direction.dart';
import 'package:image_merger/features/image_merger/domain/output_settings.dart';
import 'package:image_merger/features/session_history/domain/session_record.dart';
import 'package:image_merger/l10n/app_localizations.dart';
import 'package:image_merger/l10n/l10n_messages.dart';
import 'package:image_merger/l10n/locale_resolution.dart';

const hant = Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');

const arbNames = [
  'ko',
  'en',
  'ja',
  'zh',
  'zh_Hant',
  'es',
  'fr',
  'de',
  'pt',
  'ru',
  'vi',
  'id',
  'th',
];

Map<String, Object?> readArb(String name) =>
    (jsonDecode(File('lib/l10n/app_$name.arb').readAsStringSync()) as Map).cast<String, Object?>();

/// 메타데이터(`@`로 시작)를 뺀 문구 키.
Set<String> messageKeys(Map<String, Object?> arb) => {
      for (final key in arb.keys)
        if (!key.startsWith('@')) key,
    };

/// 문구에 쓰인 자리표시자. `{count, plural, ...}`와 `{count}`를 모두 잡고,
/// 복수형 선택지 `one{was}`처럼 단어 바로 뒤의 괄호는 뺀다.
Set<String> placeholdersIn(String message) => {
      for (final m in RegExp(r'(?<!\w)\{(\w+)[,}]').allMatches(message)) m.group(1)!,
    };

const _englishTerms = '''
Last updated: November 5, 2026

1. Acceptance
By installing or using Pic Merge (the "App"), you agree to these Terms. If you do not agree, do not use the App.

2. License
The App is open-source software released under the MIT License, and you may use it under that license. Third-party components keep their own licenses.

3. Your responsibilities
You alone are responsible for the files you process, save and share with the App, for having the rights to use them, and for complying with applicable laws. Keep your own backups of important files.

4. Your data
The App processes files on your device and does not send them to any server. If you use Send feedback, your device's mail app creates the message, and what you send is handled by your mail provider.

5. No warranty
The App is provided "AS IS" and "AS AVAILABLE", without warranty of any kind, express or implied, including merchantability, fitness for a particular purpose and non-infringement. There is no guarantee that it will be error-free or uninterrupted, or that its results will be accurate.

6. Limitation of liability
To the maximum extent permitted by applicable law, the authors, copyright holders and distributors are not liable for any claim, damages or other liability, including loss of data, loss of profits and indirect or consequential damages, arising from or connected with the App or its use.

7. No obligation to support
The authors have no obligation to provide support, updates or maintenance or to reply to feedback, and may change or stop the App at any time.

8. App stores and platforms
If you obtained the App through an app store, that store's terms also apply to your use of the App.

9. Changes
These Terms may change. If you keep using the App after a change, you accept the change.

10. Language
Translations are provided for convenience. If they differ, the English version prevails.

Contact: yncdev@gmail.com''';

const _koreanTerms = '''
최종 수정일: 2026년 11월 5일

1. 동의
Pic Merge(이하 '앱')를 설치하거나 사용하면 이 약관에 동의한 것으로 봅니다. 동의하지 않으면 앱을 사용하지 마세요.

2. 라이선스
앱은 MIT License로 배포되는 오픈소스 소프트웨어이며, 이 라이선스에 따라 사용할 수 있습니다. 제3자 구성 요소는 각자의 라이선스를 따릅니다.

3. 사용자의 책임
앱으로 처리·저장·공유하는 파일, 그 파일을 사용할 권리, 관련 법령 준수에 대한 책임은 모두 사용자에게 있습니다. 중요한 파일은 직접 백업하세요.

4. 사용자 데이터
앱은 파일을 기기 안에서 처리하며 어떤 서버로도 보내지 않습니다. '의견 보내기'를 사용하면 기기의 메일 앱에서 메시지가 만들어지고, 보낸 내용은 사용하는 메일 서비스가 처리합니다.

5. 보증의 부인
앱은 '있는 그대로', '제공되는 대로' 제공되며, 상품성, 특정 목적 적합성, 비침해를 포함해 명시적이든 묵시적이든 어떠한 보증도 하지 않습니다. 오류나 중단이 없다거나 결과가 정확하다고 보장하지 않습니다.

6. 책임의 제한
관련 법령이 허용하는 최대 범위에서, 저작자, 저작권자, 배포자는 앱 또는 앱의 사용으로 발생하거나 이와 관련된 어떠한 청구, 손해, 기타 책임(데이터 손실, 이익 손실, 간접·결과적 손해 포함)도 지지 않습니다.

7. 지원 의무 없음
저작자는 지원, 업데이트, 유지보수를 제공하거나 의견에 답변할 의무가 없으며, 언제든지 앱을 변경하거나 중단할 수 있습니다.

8. 앱 스토어와 플랫폼
앱을 앱 스토어에서 받았다면 해당 스토어의 약관도 함께 적용됩니다.

9. 약관 변경
이 약관은 변경될 수 있습니다. 변경 후 앱을 계속 사용하면 변경에 동의한 것으로 봅니다.

10. 언어
번역본은 편의를 위해 제공합니다. 내용이 다르면 영어본이 우선합니다.

문의: yncdev@gmail.com''';

void main() {
  group('resolveAppLocale', () {
    Locale resolve(List<Locale>? preferred) =>
        resolveAppLocale(preferred, AppLocalizations.supportedLocales);

    test('지원하지 않는 언어는 첫 알파벳(de)이 아니라 English', () {
      expect(resolve(const [Locale('sw')]), const Locale('en'));
      expect(resolve(const [Locale('ar', 'EG')]), const Locale('en'));
    });

    test('기기 언어가 없어도 English', () {
      expect(resolve(null), const Locale('en'));
      expect(resolve(const []), const Locale('en'));
    });

    test('지원 언어는 나라 코드와 상관없이 그 언어', () {
      expect(resolve(const [Locale('ko', 'KR')]), const Locale('ko'));
      expect(resolve(const [Locale('pt', 'BR')]), const Locale('pt'));
      expect(resolve(const [Locale('pt', 'PT')]), const Locale('pt'));
      expect(resolve(const [Locale('fr', 'CA')]), const Locale('fr'));
      expect(resolve(const [Locale('de', 'AT')]), const Locale('de'));
      expect(resolve(const [Locale('en', 'GB')]), const Locale('en'));
    });

    test('기기 언어 목록에서 처음으로 지원되는 언어', () {
      expect(resolve(const [Locale('sw'), Locale('ja'), Locale('en')]), const Locale('ja'));
    });

    test('중국어: Hant이거나 대만·홍콩·마카오면 번체', () {
      expect(resolve(const [hant]), hant);
      expect(
        resolve(const [Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW')]),
        hant,
      );
      expect(resolve(const [Locale('zh', 'TW')]), hant);
      expect(resolve(const [Locale('zh', 'HK')]), hant);
      expect(resolve(const [Locale('zh', 'MO')]), hant);
    });

    test('그 밖의 중국어는 간체', () {
      expect(resolve(const [Locale('zh')]), const Locale('zh'));
      expect(resolve(const [Locale('zh', 'CN')]), const Locale('zh'));
      expect(resolve(const [Locale('zh', 'SG')]), const Locale('zh'));
      expect(
        resolve(const [Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans', countryCode: 'CN')]),
        const Locale('zh'),
      );
    });

    test('글자 체계를 직접 고르면 나라보다 우선한다', () {
      expect(
        resolve(const [Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans', countryCode: 'HK')]),
        const Locale('zh'),
      );
      expect(
        resolve(const [Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans', countryCode: 'TW')]),
        const Locale('zh'),
      );
      expect(
        resolve(const [Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'CN')]),
        hant,
      );
    });

    test("Android의 옛 코드 'in'은 Bahasa Indonesia", () {
      expect(resolve(const [Locale('in')]), const Locale('id'));
      expect(resolve(const [Locale('in', 'ID')]), const Locale('id'));
      expect(resolve(const [Locale('id', 'ID')]), const Locale('id'));
    });

    test('결과는 항상 지원 목록 안에 있다', () {
      for (final locale in const [Locale('sw'), Locale('zh', 'TW'), Locale('zh'), Locale('in'), Locale('th', 'TH')]) {
        expect(AppLocalizations.supportedLocales, contains(resolve([locale])));
      }
    });
  });

  group('ARB 파일', () {
    final template = readArb('en');
    final keys = messageKeys(template);

    test('13개 언어 파일이 있고 그 밖의 파일은 없다', () {
      final found = Directory('lib/l10n')
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .where((n) => n.endsWith('.arb'))
          .toSet();
      expect(found, {for (final n in arbNames) 'app_$n.arb'});
      expect(AppLocalizations.supportedLocales, hasLength(13));
    });

    for (final name in arbNames) {
      group(name, () {
        final arb = readArb(name);

        test('템플릿과 키가 같다', () {
          expect(messageKeys(arb), keys);
        });

        test('언어 표시가 파일 이름과 같다', () {
          expect(arb['@@locale'], name);
        });

        test('자리표시자가 템플릿과 같다', () {
          for (final key in keys) {
            expect(
              placeholdersIn(arb[key]! as String),
              placeholdersIn(template[key]! as String),
              reason: key,
            );
          }
        });

        test('괄호 짝이 맞는다', () {
          for (final key in keys) {
            final message = arb[key]! as String;
            expect('{'.allMatches(message).length, '}'.allMatches(message).length, reason: key);
          }
        });

        test('빈 문구가 없고(English 부제 제외), 프로그램 이름은 Pic Merge', () {
          expect(arb['appName'], 'Pic Merge');
          for (final key in keys) {
            if (name == 'en' && key == 'appSubtitle') continue;
            expect((arb[key]! as String).trim(), isNotEmpty, reason: key);
          }
        });
      });
    }

    test('번역하지 않은 문구가 영어 그대로 남아 있지 않다', () {
      // 짧은 단어와 프랑스어의 'image'처럼 철자가 같은 말은 번역 누락이 아니다.
      const sameInBothLanguages = {'fr.imageCount'};
      for (final name in arbNames.where((n) => n != 'en')) {
        final arb = readArb(name);
        for (final key in keys.where((k) => k != 'appName')) {
          final english = template[key]! as String;
          if (english.length < 12 || sameInBothLanguages.contains('$name.$key')) continue;
          expect(arb[key], isNot(english), reason: '$name.$key');
        }
      }
    });

    test('자연 언어 안에 한글이 섞이지 않는다 (한국어 제외)', () {
      final hangul = RegExp(r'[가-힣]');
      for (final name in arbNames.where((n) => n != 'ko')) {
        final arb = readArb(name);
        for (final key in keys) {
          expect(hangul.hasMatch(arb[key]! as String), isFalse, reason: '$name.$key');
        }
      }
    });
  });

  group('AppLocalizations', () {
    final all = [for (final l in AppLocalizations.supportedLocales) lookupAppLocalizations(l)];

    test('부제: 한국어와 언어별 값은 설계서대로, English는 없음', () {
      const expected = {
        'ko': '이미지 합치기',
        'en': '',
        'ja': '画像結合',
        'zh': '图片合并',
        'zh_Hant': '圖片合併',
        'es': 'Unir imágenes',
        'fr': "Fusion d'images",
        'de': 'Bilder zusammenfügen',
        'pt': 'Juntar imagens',
        'ru': 'Объединение изображений',
        'vi': 'Ghép ảnh',
        'id': 'Gabung Gambar',
        'th': 'รวมรูปภาพ',
      };
      expected.forEach((name, subtitle) {
        final parts = name.split('_');
        final locale = Locale.fromSubtags(
          languageCode: parts.first,
          scriptCode: parts.length > 1 ? parts[1] : null,
        );
        expect(lookupAppLocalizations(locale).appSubtitle, subtitle, reason: name);
      });
    });

    test('복수형과 자리표시자를 넣어 만들면 숫자가 들어가고 ICU 문법이 남지 않는다', () {
      for (final l in all) {
        for (final n in const [1, 2, 3, 5, 11, 21, 30]) {
          for (final message in [
            l.maxImagesReached(n),
            l.unsupportedFilesExcluded(n),
            l.overLimitAdded(30, n),
            l.emptyTitle(n),
            l.previewSummary(n, 2),
            l.needMinImages(n),
            l.historyRateEmpty(n),
            l.historyRate(n, 50, 1, 2),
            l.imageCount(n),
            l.selectedCount(n, 30),
            l.processingImages(n, 30),
            l.errorUnsupportedFormatAt(n),
            l.errorCorruptFileAt(n),
            l.errorSourceUnavailableAt(n),
          ]) {
            expect(message.contains('{'), isFalse, reason: '${l.localeName}: $message');
            expect(message.contains('plural'), isFalse, reason: '${l.localeName}: $message');
            // 영어 n=1의 'one' 형식처럼 숫자를 쓰지 않는 표현(스페인어 "el último día")만 예외다.
            if (!(message == l.historyRateEmpty(n) || message.startsWith(l.historyRate(n, 50, 1, 2)))) {
              expect(message.contains('$n'), isTrue, reason: '${l.localeName}: $message');
            }
          }
        }
      }
    });

    test('미리보기 안내는 이제 PDF의 바깥 여백이 없다고 말하지 않는다 (DESIGN §2.2)', () {
      // 언어별로 앞선 안내에 있던 '바깥 여백'에 해당하는 말이다.
      const removed = {
        'ko': '바깥 여백',
        'en': 'outer margin',
        'ja': '外側の余白',
        'zh': '外边距',
        'zh_Hant': '外邊距',
        'es': 'márgenes exteriores',
        'fr': 'marges extérieures',
        'de': 'Außenrand',
        'pt': 'margens externas',
        'ru': 'внешних полей',
        'vi': 'lề ngoài',
        'id': 'margin luar',
        'th': 'ระยะขอบด้านนอก',
      };
      removed.forEach((name, word) {
        final arb = readArb(name);
        for (final key in const ['previewNoteHorizontal', 'previewNoteVertical', 'previewNoteOriginal']) {
          expect(arb[key], isNot(contains(word)), reason: '$name.$key');
        }
      });
    });

    test('러시아어는 1·2·5·21에 맞는 복수형을 쓴다', () {
      final ru = lookupAppLocalizations(const Locale('ru'));
      expect(ru.imageCount(1), '1 изображение');
      expect(ru.imageCount(2), '2 изображения');
      expect(ru.imageCount(5), '5 изображений');
      expect(ru.imageCount(21), '21 изображение');
    });

    test('영어·독일어·프랑스어는 단수와 복수를 구분한다', () {
      expect(lookupAppLocalizations(const Locale('en')).imageCount(1), '1 image');
      expect(lookupAppLocalizations(const Locale('en')).imageCount(2), '2 images');
      expect(lookupAppLocalizations(const Locale('de')).imageCount(1), '1 Bild');
      expect(lookupAppLocalizations(const Locale('de')).imageCount(2), '2 Bilder');
      expect(lookupAppLocalizations(const Locale('fr')).imageCount(1), '1 image');
      expect(lookupAppLocalizations(const Locale('fr')).imageCount(2), '2 images');
    });

    test('번체 조회는 번체 문구를 돌려준다', () {
      expect(lookupAppLocalizations(hant).share, '分享');
      expect(lookupAppLocalizations(hant).historyEmpty, '尚未儲存過。');
      expect(lookupAppLocalizations(const Locale('zh')).historyEmpty, '还没有保存过。');
    });
  });

  group('한국어 문구는 이전 그대로다', () {
    final ko = lookupAppLocalizations(const Locale('ko'));

    test('오류 안내 (DESIGN §3.4)', () {
      expect(ko.mergeError(MergeErrorCode.unsupportedFormat, imageNumber: 3), '3번째 이미지는 지원하지 않는 형식입니다.');
      expect(ko.mergeError(MergeErrorCode.corruptFile, imageNumber: 3), '3번째 이미지 파일이 손상되었습니다.');
      expect(ko.mergeError(MergeErrorCode.sourceUnavailable, imageNumber: 3), '3번째 이미지를 열 수 없습니다. 다시 선택해 주세요.');
      expect(ko.mergeError(MergeErrorCode.unsupportedFormat), '지원하지 않는 형식의 이미지가 있습니다.');
      expect(ko.mergeError(MergeErrorCode.corruptFile), '손상된 이미지 파일이 있습니다.');
      expect(ko.mergeError(MergeErrorCode.sourceUnavailable), '이미지를 열 수 없습니다. 다시 선택해 주세요.');
      expect(ko.mergeError(MergeErrorCode.outOfSpace), '저장 공간이 부족합니다.');
      expect(ko.mergeError(MergeErrorCode.folderUnavailable), '저장 폴더에 접근할 수 없습니다. 폴더를 다시 골라 주세요.');
      expect(ko.mergeError(MergeErrorCode.outputTooLarge), '결과 파일이 너무 큽니다. 이미지 수를 줄여 주세요.');
      expect(ko.mergeError(MergeErrorCode.outOfMemory), '메모리가 부족합니다. 이미지 수를 줄여 주세요.');
      expect(ko.mergeError(MergeErrorCode.unknown), '알 수 없는 오류가 발생했습니다.');
    });

    test('코드를 문구로 옮긴다', () {
      expect(ko.paperName(PaperSize.original), '원본 크기');
      expect(ko.paperName(PaperSize.a4), 'A4');
      expect(ko.paperName(PaperSize.legal), 'Legal');
      expect(ko.orientationName(PaperOrientation.portrait), '세로');
      expect(ko.orientationName(PaperOrientation.landscape), '가로');
      expect(ko.autoDirection(LayoutDirection.vertical), '자동: 세로 배치 (위 → 아래)');
      expect(ko.autoDirection(LayoutDirection.horizontal), '자동: 가로 배치 (왼쪽 → 오른쪽)');
      expect(ko.sessionStatus(SessionStatus.running), '진행 중');
      expect(ko.sessionStatus(SessionStatus.success), '성공');
      expect(ko.sessionStatus(SessionStatus.failed), '실패');
      expect(ko.sessionStatus(SessionStatus.cancelled), '취소');
      expect(ko.sessionStatus(SessionStatus.crashed), '비정상 종료');
    });

    test('폴더 변경 창의 버튼', () {
      expect(ko.useDefaultFolder('Download'), '기본 폴더 쓰기 (Download)');
      expect(ko.pickOtherFolder, '다른 폴더 고르기');
    });

    test('빈 화면 안내는 비율을 말하지 않는다: 용지를 고르면 용지가 방향을 정한다', () {
      expect(ko.emptyHint, '배치 방향은 자동으로 정합니다.');
    });

    test('미리보기 요약은 설계서 형식이다', () {
      expect(ko.previewSummary(3, 1), '총 3페이지 · 용지당 1개');
    });
  });

  group('이용약관', () {
    final numbered = RegExp(r'^(\d+)\. ', multiLine: true);

    const englishHeadings = [
      '1. Acceptance',
      '2. License',
      '3. Your responsibilities',
      '4. Your data',
      '5. No warranty',
      '6. Limitation of liability',
      '7. No obligation to support',
      '8. App stores and platforms',
      '9. Changes',
      '10. Language',
    ];
    const koreanHeadings = [
      '1. 동의',
      '2. 라이선스',
      '3. 사용자의 책임',
      '4. 사용자 데이터',
      '5. 보증의 부인',
      '6. 책임의 제한',
      '7. 지원 의무 없음',
      '8. 앱 스토어와 플랫폼',
      '9. 약관 변경',
      '10. 언어',
    ];

    test('영어와 한국어 본문에 번호 붙은 제목이 순서대로 모두 있다', () {
      for (final (name, headings) in const [('en', englishHeadings), ('ko', koreanHeadings)]) {
        final lines = (readArb(name)['termsBody']! as String).split('\n');
        var from = 0;
        for (final heading in headings) {
          final at = lines.indexOf(heading, from);
          expect(at, greaterThanOrEqualTo(0), reason: '$name: $heading');
          from = at + 1;
        }
      }
    });

    for (final name in arbNames) {
      test('$name: 번호가 1부터 10까지 순서대로 있고 문의 주소로 끝난다', () {
        final body = readArb(name)['termsBody']! as String;
        expect(
          [for (final m in numbered.allMatches(body)) int.parse(m.group(1)!)],
          [for (var n = 1; n <= 10; n++) n],
        );
        expect(body.trimRight(), endsWith('yncdev@gmail.com'));
        expect(body, contains('MIT License'));
        expect(body, contains('Pic Merge'));
      });
    }

    test('영어 본문은 지정한 문구와 정확히 같다', () {
      expect(readArb('en')['termsBody'], _englishTerms);
    });

    test('한국어 본문은 지정한 문구와 정확히 같다', () {
      expect(readArb('ko')['termsBody'], _koreanTerms);
    });

    test('약관이 말하는 메뉴 이름이 실제 메뉴 이름과 같다', () {
      for (final name in arbNames) {
        final arb = readArb(name);
        expect(arb['termsBody'], contains(arb['sendFeedback']! as String), reason: name);
      }
    });

    test('생성된 코드도 지정한 문구와 같다', () {
      expect(lookupAppLocalizations(const Locale('en')).termsBody, _englishTerms);
      expect(lookupAppLocalizations(const Locale('ko')).termsBody, _koreanTerms);
    });
  });

  group('개인정보 처리방침', () {
    /// 공개 문서의 마크다운에서 표시만 지운 글. 문서 제목은 앱 바에 나오므로 뺀다.
    String plainSection(String section) {
      final lines = section.trim().split('\n').skip(1).skipWhile((line) => line.isEmpty).toList();
      final out = <String>[];
      for (var i = 0; i < lines.length; i++) {
        out.add(lines[i].startsWith('## ') ? lines[i].substring(3) : lines[i]);
        if (lines[i].startsWith('## ') && lines[i + 1].isEmpty) i++;
      }
      return out.join('\n').replaceAll('**', '');
    }

    final document = File('PRIVACY.md').readAsStringSync().replaceAll('\r\n', '\n').split('\n---\n');

    test('영어와 한국어 본문은 공개 문서와 낱말까지 같다', () {
      expect(document, hasLength(2));
      expect(readArb('en')['privacyBody'], plainSection(document[0]));
      expect(readArb('ko')['privacyBody'], plainSection(document[1]));
    });

    test('생성된 코드도 공개 문서와 같다', () {
      expect(lookupAppLocalizations(const Locale('en')).privacyBody, plainSection(document[0]));
      expect(lookupAppLocalizations(const Locale('ko')).privacyBody, plainSection(document[1]));
    });

    for (final name in arbNames) {
      test('$name: 비어 있지 않고 문의 주소와 메뉴 이름이 있다', () {
        final arb = readArb(name);
        final body = arb['privacyBody']! as String;
        expect(body.trim(), isNotEmpty);
        expect(body, contains('yncdev@gmail.com'));
        expect(body, contains('Pic Merge'));
        expect(body, contains(arb['sendFeedback']! as String));
        expect(body, isNot(contains('**')));
        expect(body, isNot(contains('## ')));
      });
    }
  });

  group('outputFolderName', () {
    test('공유 표식만 기기 언어로 옮기고 폴더 이름은 그대로 둔다', () {
      final en = lookupAppLocalizations(const Locale('en'));
      final ko = lookupAppLocalizations(const Locale('ko'));
      final ru = lookupAppLocalizations(const Locale('ru'));

      expect(en.outputFolderName(kShareFolderSentinel), 'Share');
      expect(ko.outputFolderName(kShareFolderSentinel), '공유');
      expect(ru.outputFolderName(kShareFolderSentinel), 'Поделиться');
      expect(en.outputFolderName('Documents'), 'Documents');
      expect(en.outputFolderName('공유 문서'), '공유 문서');
    });
  });
}
