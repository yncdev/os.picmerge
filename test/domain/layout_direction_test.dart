import 'package:flutter_test/flutter_test.dart';
import 'package:image_merger/core/image_size.dart';
import 'package:image_merger/features/image_merger/domain/layout_direction.dart';
import 'package:image_merger/features/image_merger/domain/output_settings.dart';

void main() {
  group('decideDirection', () {
    test('세로형 스크린샷 3장은 가로 배치(옆으로 나란히)', () {
      const s = ImageSize(1080, 2340);
      expect(decideDirection([s, s, s]), LayoutDirection.horizontal);
    });

    test('가로형 사진 3장은 세로 배치(위아래로 쌓기)', () {
      const s = ImageSize(4000, 3000);
      expect(decideDirection([s, s, s]), LayoutDirection.vertical);
    });

    test('2:1과 1:2는 기하 평균이 정확히 1이라 세로 배치', () {
      expect(
        decideDirection(const [ImageSize(200, 100), ImageSize(100, 200)]),
        LayoutDirection.vertical,
      );
    });

    test('정사각형만 있으면 세로 배치', () {
      expect(decideDirection(const [ImageSize(500, 500)]), LayoutDirection.vertical);
    });

    test('산술 평균은 1보다 크지만 기하 평균은 1보다 작으면 가로 배치', () {
      // 산술 평균 (3 + 0.5 + 0.5) / 3 = 1.33, 기하 평균 (3 × 0.25)^(1/3) ≈ 0.91
      expect(
        decideDirection(const [
          ImageSize(300, 100),
          ImageSize(100, 200),
          ImageSize(100, 200),
        ]),
        LayoutDirection.horizontal,
      );
    });

    test('역수 쌍은 부동소수점 오차가 있어도 세로 배치', () {
      expect(
        decideDirection(const [
          ImageSize(3, 7),
          ImageSize(7, 3),
          ImageSize(10, 3),
          ImageSize(3, 10),
        ]),
        LayoutDirection.vertical,
      );
    });

    test('빈 목록은 오류', () {
      expect(() => decideDirection(const []), throwsArgumentError);
    });
  });

  group('용지 비율로 정한다', () {
    const landscapePhoto = ImageSize(4000, 3000);
    const screenshot = ImageSize(1080, 2340);

    test('A4 세로는 가로 배치(페이지를 옆으로 나란히), 이미지 비율은 보지 않는다', () {
      const a4 = PaperDimensions(210, 297);
      expect(decideDirectionForPaper(a4), LayoutDirection.horizontal);
      expect(pngDirection(const [landscapePhoto, landscapePhoto], a4), LayoutDirection.horizontal);
    });

    test('A4 가로는 세로 배치(위아래로 쌓기), 이미지 비율은 보지 않는다', () {
      const a4Landscape = PaperDimensions(297, 210);
      expect(decideDirectionForPaper(a4Landscape), LayoutDirection.vertical);
      expect(pngDirection(const [screenshot, screenshot], a4Landscape), LayoutDirection.vertical);
    });

    test('모든 용지: 세로 용지는 가로 배치, 가로 용지는 세로 배치', () {
      for (final paper in PaperSize.values.where((p) => p != PaperSize.original)) {
        final portrait = OutputSettings(paper: paper).paperDimensions!;
        final landscape =
            OutputSettings(paper: paper, orientation: PaperOrientation.landscape).paperDimensions!;
        expect(decideDirectionForPaper(portrait), LayoutDirection.horizontal, reason: paper.name);
        expect(decideDirectionForPaper(landscape), LayoutDirection.vertical, reason: paper.name);
      }
    });

    test('정사각형 비율(기하 평균 1)은 세로 배치', () {
      expect(decideDirectionForPaper(const PaperDimensions(100, 100)), LayoutDirection.vertical);
    });

    test('원본 크기는 이미지 비율로 정한다', () {
      expect(pngDirection(const [landscapePhoto], null), LayoutDirection.vertical);
      expect(pngDirection(const [screenshot], null), LayoutDirection.horizontal);
    });
  });
}
