import 'package:flutter_test/flutter_test.dart';
import 'package:image_merger/core/image_size.dart';
import 'package:image_merger/features/image_merger/domain/output_settings.dart';
import 'package:image_merger/features/image_merger/domain/page_layout.dart';
import 'package:image_merger/features/image_merger/domain/pdf_plan.dart';

void main() {
  paperLayoutTests();

  group('pdfImageBudget', () {
    test('0.95 × 20,000,000 ÷ 장수 (내림)', () {
      expect(pdfImageBudget(10), 1900000);
      expect(pdfImageBudget(30), 633333);
    });

    test('0장은 오류', () {
      expect(() => pdfImageBudget(0), throwsArgumentError);
    });
  });

  group('pdfJpegAttempts', () {
    test('품질 85 → 70 → 긴 변 75%씩 3번, 처음 크기는 4000px 제한 적용', () {
      final attempts = pdfJpegAttempts(const ImageSize(8000, 6000));
      expect(attempts.map((a) => a.toString()).toList(), [
        '4000x3000 q85',
        '4000x3000 q70',
        '3000x2250 q70',
        '2250x1688 q70',
        '1688x1266 q70',
      ]);
    });

    test('작은 이미지는 원래 크기에서 시작', () {
      final first = pdfJpegAttempts(const ImageSize(800, 600)).first;
      expect(first.width, 800);
      expect(first.height, 600);
    });
  });
}

void paperLayoutTests() {
  // 기대값은 함수를 다시 불러 구하지 않고 설계 규칙(DESIGN §2.1.3)에서 손으로 계산해 적었다.
  group('용지 페이지', () {
    const a4Width = 595.2756; // 210mm ÷ 25.4 × 72
    const a4Height = 841.8898; // 297mm ÷ 25.4 × 72
    const wide = ImageSize(2000, 1000);

    void expectRect(LayoutRect rect, double left, double top, double width, double height) {
      expect(rect.left, closeTo(left, 0.001));
      expect(rect.top, closeTo(top, 0.001));
      expect(rect.width, closeTo(width, 0.001));
      expect(rect.height, closeTo(height, 0.001));
    }

    test('N=1: 이미지 하나당 한 페이지, 여백 안쪽 폭을 채우고 위아래 가운데', () {
      final pages = planPdf(const [wide, wide], const OutputSettings());

      expect(pages, hasLength(2));
      final page = pages.first;
      expect(page.widthPt, closeTo(a4Width, 0.001));
      expect(page.heightPt, closeTo(a4Height, 0.001));
      // 여백 595.2756 × 5% = 29.7638, 칸 535.7480×782.3622, 이미지 535.7480×267.8740
      // 위 29.7638 + (782.3622 − 267.8740) ÷ 2 = 287.0079
      expectRect(page.images.single.rect, 29.7638, 287.0079, 535.7480, 267.8740);
    });

    test('세로로 긴 이미지는 여백 안쪽 높이를 채운다', () {
      final rect = planPdf(const [ImageSize(1000, 4000)], const OutputSettings()).single.images.single.rect;

      // 높이 782.3622, 폭 ÷ 4 = 195.5906, 왼쪽 (595.2756 − 195.5906) ÷ 2 = 199.8425
      expectRect(rect, 199.8425, 29.7638, 195.5906, 782.3622);
    });

    test('작은 이미지도 칸에 맞춰 키운다', () {
      final rect = planPdf(const [ImageSize(10, 10)], const OutputSettings()).single.images.single.rect;

      // 535.7480 정사각형, 위 29.7638 + (782.3622 − 535.7480) ÷ 2 = 153.0709
      expectRect(rect, 29.7638, 153.0709, 535.7480, 535.7480);
    });

    test('N=2, 3장: 2페이지, 위아래 칸, 여백 29.76pt, 간격 23.81pt', () {
      final pages = planPdf(const [wide, wide, wide], const OutputSettings(imagesPerPaper: 2));

      expect([for (final p in pages) p.images.map((i) => i.imageIndex).toList()], [
        [0, 1],
        [2],
      ]);
      // 간격 29.7638 × 0.8 = 23.8110, 칸 높이 (782.3622 − 23.8110) ÷ 2 = 379.2756
      // 이미지 535.7480×267.8740, 첫 칸 위 29.7638 + (379.2756 − 267.8740) ÷ 2 = 85.4646
      // 둘째 칸 위 85.4646 + 379.2756 + 23.8110 = 488.5512
      expectRect(pages[0].images[0].rect, 29.7638, 85.4646, 535.7480, 267.8740);
      expectRect(pages[0].images[1].rect, 29.7638, 488.5512, 535.7480, 267.8740);
      expectRect(pages[1].images[0].rect, 29.7638, 85.4646, 535.7480, 267.8740);
    });

    test('가로 용지 N=2: 좌우 칸', () {
      final pages = planPdf(
        const [ImageSize(1000, 1000), ImageSize(1000, 1000)],
        const OutputSettings(orientation: PaperOrientation.landscape, imagesPerPaper: 2),
      );

      expect(pages, hasLength(1));
      expect(pages.single.widthPt, closeTo(a4Height, 0.001));
      expect(pages.single.heightPt, closeTo(a4Width, 0.001));
      // 칸 폭 (841.8898 − 59.5276 − 23.8110) ÷ 2 = 379.2756, 높이 535.7480. 정사각형 379.2756
      // 위 29.7638 + (535.7480 − 379.2756) ÷ 2 = 108
      // 둘째 칸 왼쪽 29.7638 + 379.2756 + 23.8110 = 432.8504
      expectRect(pages.single.images[0].rect, 29.7638, 108, 379.2756, 379.2756);
      expectRect(pages.single.images[1].rect, 432.8504, 108, 379.2756, 379.2756);
    });

    test('F=50%: 가로·세로가 절반이고 칸 가운데', () {
      final rect = planPdf(const [wide], const OutputSettings(imageSizePercent: 50)).single.images.single.rect;

      // 267.8740×133.9370. 왼쪽 29.7638 + (535.7480 − 267.8740) ÷ 2 = 163.7008
      // 위 29.7638 + (782.3622 − 133.9370) ÷ 2 = 353.9764
      expectRect(rect, 163.7008, 353.9764, 267.8740, 133.9370);
    });

    test('F=30%', () {
      final rect = planPdf(const [wide], const OutputSettings(imageSizePercent: 30)).single.images.single.rect;

      // 535.7480 × 0.3 = 160.7244, 267.8740 × 0.3 = 80.3622
      expectRect(rect, 217.2756, 380.7638, 160.7244, 80.3622);
    });

    group('여백 설정', () {
      test('P=0%: 여백이 없어 폭을 채운다', () {
        final rect = planPdf(const [wide], const OutputSettings(marginPercent: 0)).single.images.single.rect;

        // 595.2756×297.6378, 위 (841.8898 − 297.6378) ÷ 2 = 272.1260
        expectRect(rect, 0, 272.1260, 595.2756, 297.6378);
      });

      test('P=0%, N=2: 칸이 맞닿는다', () {
        final pages = planPdf(
          const [ImageSize(1000, 2000), ImageSize(1000, 2000)],
          const OutputSettings(imagesPerPaper: 2, marginPercent: 0),
        );

        // 칸 595.2756×420.9449. 이미지 210.4724×420.9449, 왼쪽 (595.2756 − 210.4724) ÷ 2 = 192.4016
        final images = pages.single.images;
        expectRect(images[0].rect, 192.4016, 0, 210.4724, 420.9449);
        expectRect(images[1].rect, 192.4016, 420.9449, 210.4724, 420.9449);
      });

      test('P=3%', () {
        final rect = planPdf(const [wide], const OutputSettings(marginPercent: 3)).single.images.single.rect;

        // 여백 17.8583, 폭 559.5591, 높이 279.7795, 위 17.8583 + (806.1732 − 279.7795) ÷ 2 = 281.0551
        expectRect(rect, 17.8583, 281.0551, 559.5591, 279.7795);
      });

      test('P=10%, N=2', () {
        final pages = planPdf(const [wide, wide], const OutputSettings(imagesPerPaper: 2, marginPercent: 10));

        // 여백 59.5276, 간격 47.6220, 칸 476.2205×337.6063, 이미지 476.2205×238.1102
        // 첫 칸 위 59.5276 + (337.6063 − 238.1102) ÷ 2 = 109.2756
        // 둘째 칸 위 109.2756 + 337.6063 + 47.6220 = 494.5039
        final images = pages.single.images;
        expectRect(images[0].rect, 59.5276, 109.2756, 476.2205, 238.1102);
        expectRect(images[1].rect, 59.5276, 494.5039, 476.2205, 238.1102);
      });
    });

    group('원본 크기: 항목 하나당 한 페이지, 긴 변 297mm', () {
      const tall = ImageSize(1000, 2000);

      test('P=5%, 1000×2000: 페이지 440.99×841.89, 이미지 400.90×801.80 at 20.05', () {
        // 여백 짧은 변 1000 × 5% = 50, 내용 1100×2100, 비율 841.8898 ÷ 2100 = 0.40090
        final pages = planPdf(const [tall, wide], const OutputSettings(paper: PaperSize.original));

        expect(pages, hasLength(2));
        expect(pages[0].widthPt, closeTo(440.9899, 0.001));
        expect(pages[0].heightPt, closeTo(841.8898, 0.001));
        expectRect(pages[0].images.single.rect, 20.0450, 20.0450, 400.8999, 801.7998);
      });

      test('가로형은 페이지 가로가 긴 변이다', () {
        final page = planPdf(const [wide], const OutputSettings(paper: PaperSize.original)).single;

        // 2000×1000, 여백 50, 내용 2100×1100
        expect(page.widthPt, closeTo(841.8898, 0.001));
        expect(page.heightPt, closeTo(440.9899, 0.001));
        expectRect(page.images.single.rect, 20.0450, 20.0450, 801.7998, 400.8999);
      });

      test('여백은 그 이미지의 짧은 변으로 잰다', () {
        final pages = planPdf(
          const [ImageSize(1000, 1000), ImageSize(100, 100)],
          const OutputSettings(paper: PaperSize.original, marginPercent: 10),
        );

        // 둘 다 내용 비율 1.2 : 1.2라 페이지와 비율 위치가 같다. 841.8898 × 100 ÷ 1200 = 70.1575
        expectRect(pages[0].images.single.rect, 70.1575, 70.1575, 701.5748, 701.5748);
        expectRect(pages[1].images.single.rect, 70.1575, 70.1575, 701.5748, 701.5748);
      });

      test('P=0%: 페이지 비율이 이미지 비율과 같고 여백이 없다', () {
        final settings = const OutputSettings(paper: PaperSize.original, marginPercent: 0);
        final photo = planPdf(const [ImageSize(4000, 3000)], settings).single;
        final screenshot = planPdf(const [ImageSize(1080, 2340)], settings).single;

        expect(photo.widthPt, closeTo(841.89, 0.01));
        expect(photo.heightPt, closeTo(631.42, 0.01));
        expect(screenshot.heightPt, closeTo(841.89, 0.01));
        expect(screenshot.widthPt, closeTo(388.56, 0.01));
        expectRect(photo.images.single.rect, 0, 0, photo.widthPt, photo.heightPt);
      });

      test('P=3%, P=10%', () {
        final three = planPdf(const [tall], const OutputSettings(paper: PaperSize.original, marginPercent: 3)).single;
        final ten = planPdf(const [tall], const OutputSettings(paper: PaperSize.original, marginPercent: 10)).single;

        // P=3: 여백 30, 내용 1060×2060, 비율 841.8898 ÷ 2060 = 0.40869
        expect(three.widthPt, closeTo(433.2054, 0.001));
        expectRect(three.images.single.rect, 12.2605, 12.2605, 408.6844, 817.3687);
        // P=10: 여백 100, 내용 1200×2200, 비율 841.8898 ÷ 2200 = 0.38268
        expect(ten.widthPt, closeTo(459.2126, 0.001));
        expectRect(ten.images.single.rect, 38.2677, 38.2677, 382.6772, 765.3543);
      });

      test('용지당 이미지 수와 이미지 크기는 쓰지 않는다', () {
        final pages = planPdf(
          const [wide, tall],
          const OutputSettings(paper: PaperSize.original, imagesPerPaper: 4, imageSizePercent: 30),
        );

        expect(pages, hasLength(2));
        expect(pages[0].images.single.rect.width, closeTo(801.7998, 0.001));
      });
    });
  });
}
