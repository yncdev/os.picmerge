import 'package:flutter_test/flutter_test.dart';
import 'package:image_merger/features/image_merger/domain/output_settings.dart';

void main() {
  test('기본값은 A4·세로·용지당 1개·100%·여백 5%·컬러', () {
    const settings = OutputSettings();

    expect(settings.paper, PaperSize.a4);
    expect(settings.orientation, PaperOrientation.portrait);
    expect(settings.imagesPerPaper, 1);
    expect(settings.imageSizePercent, 100);
    expect(settings.marginPercent, 5);
    expect(settings.grayscale, isFalse);
    expect(settings.paperDimensions!.widthMm, 210);
    expect(settings.paperDimensions!.heightMm, 297);
  });

  test('가로로 쓰면 폭과 높이가 바뀐다', () {
    const settings = OutputSettings(orientation: PaperOrientation.landscape);

    expect(settings.paperDimensions!.widthMm, 297);
    expect(settings.paperDimensions!.heightMm, 210);
  });

  test('용지 치수: B4·B5는 JIS', () {
    const expected = {
      PaperSize.a3: (297.0, 420.0),
      PaperSize.a4: (210.0, 297.0),
      PaperSize.a5: (148.0, 210.0),
      PaperSize.b4: (257.0, 364.0),
      PaperSize.b5: (182.0, 257.0),
      PaperSize.letter: (215.9, 279.4),
      PaperSize.legal: (215.9, 355.6),
    };
    for (final entry in expected.entries) {
      final d = OutputSettings(paper: entry.key).paperDimensions!;
      expect((d.widthMm, d.heightMm), entry.value, reason: entry.key.name);
    }
  });

  test('원본 크기는 용지가 없고, 방향과 무관하다', () {
    expect(const OutputSettings(paper: PaperSize.original).paperDimensions, isNull);
    expect(
      const OutputSettings(paper: PaperSize.original, orientation: PaperOrientation.landscape)
          .paperDimensions,
      isNull,
    );
  });

  test('copyWith는 준 값만 바꾼다', () {
    final changed = const OutputSettings().copyWith(grayscale: true);

    expect(changed.grayscale, isTrue);
    expect(changed.paper, PaperSize.a4);
    expect(changed.orientation, PaperOrientation.portrait);
    expect(changed.imagesPerPaper, 1);
    expect(changed.imageSizePercent, 100);

    final grid = const OutputSettings().copyWith(imagesPerPaper: 6, imageSizePercent: 30);
    expect(grid.imagesPerPaper, 6);
    expect(grid.imageSizePercent, 30);
    expect(grid.grayscale, isFalse);
    expect(grid.marginPercent, 5);

    final margin = const OutputSettings().copyWith(marginPercent: 10);
    expect(margin.marginPercent, 10);
    expect(margin.imagesPerPaper, 1);
  });

  test('선택지: 용지당 1·2·3·4·6·8·9, 이미지 크기 100·50·30, 여백 0·3·5·10', () {
    expect(kImagesPerPaperChoices, [1, 2, 3, 4, 6, 8, 9]);
    expect(kImageSizePercentChoices, [100, 50, 30]);
    expect(kMarginPercentChoices, [0, 3, 5, 10]);
  });
}
