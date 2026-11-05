import 'package:flutter_test/flutter_test.dart';
import 'package:image_merger/features/image_merger/domain/file_naming.dart';

void main() {
  group('baseFileName: YYYYMMDDHHMI', () {
    test('24시간제 오후', () {
      expect(baseFileName(DateTime(2026, 10, 30, 15, 36)), '202610301536');
    });

    test('한 자리 달·날·분은 0을 채운다', () {
      expect(baseFileName(DateTime(2026, 1, 5, 9, 7)), '202601050907');
    });

    test('자정과 하루의 끝', () {
      expect(baseFileName(DateTime(2026, 12, 31, 0, 0)), '202612310000');
      expect(baseFileName(DateTime(2026, 12, 31, 23, 59)), '202612312359');
    });
  });

  group('resolveFileName: 비어 있는 가장 작은 연번', () {
    const base = '202610301536';

    test('아무것도 없으면 _1', () {
      expect(resolveFileName(base, 'png', const []), '202610301536_1.png');
    });

    test('_1이 있으면 _2', () {
      expect(resolveFileName(base, 'png', const ['202610301536_1.png']), '202610301536_2.png');
    });

    test('중간이 비었으면 그 번호', () {
      expect(
        resolveFileName(base, 'png', const ['202610301536_1.png', '202610301536_3.png']),
        '202610301536_2.png',
      );
    });

    test('자릿수를 채우지 않는다: 9 다음은 10', () {
      expect(
        resolveFileName(base, 'png', [for (var n = 1; n <= 9; n++) '202610301536_$n.png']),
        '202610301536_10.png',
      );
    });

    test('_10이 있어도 _1은 비어 있다', () {
      expect(resolveFileName(base, 'png', const ['202610301536_10.png']), '202610301536_1.png');
    });

    test('확장자가 다르면 연번을 따로 센다: _1.png와 _1.pdf가 함께 있을 수 있다', () {
      expect(resolveFileName(base, 'pdf', const ['202610301536_1.png']), '202610301536_1.pdf');
      expect(resolveFileName(base, 'png', const ['202610301536_1.pdf']), '202610301536_1.png');
    });

    test('대소문자만 달라도 겹친 것으로 본다', () {
      expect(resolveFileName(base, 'png', const ['202610301536_1.PNG']), '202610301536_2.png');
    });

    test('시스템이 바꾼 이름과 다른 시각의 파일은 겹치지 않는다', () {
      expect(
        resolveFileName(base, 'png', const ['202610301536_1 (1).png', '202610301537_1.png']),
        '202610301536_1.png',
      );
    });
  });
}
