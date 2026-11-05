import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:image_merger/core/image_size.dart';
import 'package:image_merger/features/image_merger/domain/layout_direction.dart';
import 'package:image_merger/features/image_merger/domain/output_settings.dart';
import 'package:image_merger/features/image_merger/domain/page_layout.dart';
import 'package:image_merger/features/image_merger/domain/png_plan.dart';

// 기대값은 함수를 다시 불러 구하지 않고 설계 규칙(DESIGN §2.1.2)에서 손으로 계산해 적었다.

const original = OutputSettings(paper: PaperSize.original);
const a4 = OutputSettings();
const a4Landscape = OutputSettings(orientation: PaperOrientation.landscape);

void main() {
  paperTests();

  group('planPng 원본 크기', () {
    test('스크린샷 3장: 가로 배치, 높이 그대로, [여백][이미지][여백][선] 순서', () {
      const s = ImageSize(1080, 2340);
      final plan = planPng(const [s, s, s], original);

      // 공통 변 2340. 여백 2340 × 5% = 117, 두께 2340 × 0.3% = 7.02 → 7.
      // 폭 (117 + 1080 + 117) × 3 + 7 × 2 = 3956, 높이 117 + 2340 + 117 = 2574
      expect(plan.direction, LayoutDirection.horizontal);
      expect(plan.canvasWidth, 3956);
      expect(plan.canvasHeight, 2574);
      expect(plan.dividerThickness, 7);
      // 첫 이미지 117. 그 뒤 선은 117 + 1080 + 117 = 1314. 둘째 이미지는 1314 + 7 + 117 = 1438.
      // 둘째 선은 1438 + 1080 + 117 = 2635. 셋째 이미지는 2635 + 7 + 117 = 2759.
      expect([for (final p in plan.placements) p.x], [117, 1438, 2759]);
      expect(plan.placements.every((p) => p.y == 117 && p.width == 1080 && p.height == 2340), isTrue);
      expect(plan.placements.every((p) => p.scale == 1.0), isTrue);
      // 선은 캔버스 전체 길이다.
      expect(plan.dividers, const [PixelRect(1314, 0, 7, 2574), PixelRect(2635, 0, 7, 2574)]);
    });

    test('세로 배치는 폭을 가장 좁은 이미지에 맞춘다 (확대 안 함)', () {
      final plan = planPng(const [ImageSize(4000, 3000), ImageSize(2000, 1500)], original);

      // 공통 변 2000. 여백 100, 두께 6. 폭 2200, 높이 (100 + 1500 + 100) × 2 + 6 = 3406
      expect(plan.direction, LayoutDirection.vertical);
      expect(plan.canvasWidth, 2200);
      expect(plan.canvasHeight, 3406);
      expect((plan.placements[0].x, plan.placements[0].y), (100, 100));
      expect(plan.placements[0].width, 2000);
      expect(plan.placements[0].height, 1500);
      expect(plan.placements[0].scale, 0.5);
      // 선 1700~1705, 둘째 이미지 1706 + 100 = 1806
      expect((plan.placements[1].x, plan.placements[1].y), (100, 1806));
      expect(plan.placements[1].scale, 1.0);
      expect(plan.dividers, const [PixelRect(0, 1700, 2200, 6)]);
    });

    test('가로 배치는 높이를 가장 낮은 이미지에 맞춘다', () {
      final plan = planPng(const [ImageSize(1080, 2340), ImageSize(720, 1560)], original);

      // 공통 변 1560. 여백 78, 두께 4.68 → 5. 폭 (78 + 720 + 78) × 2 + 5 = 1757, 높이 1716
      expect(plan.direction, LayoutDirection.horizontal);
      expect(plan.canvasHeight, 1716);
      expect(plan.placements[0].width, 720);
      expect(plan.canvasWidth, 1757);
    });

    test('구분선은 최소 2px', () {
      final plan = planPng(const [ImageSize(100, 200), ImageSize(100, 200)], original);

      // 공통 변 200. 여백 10, 두께 0.6이지만 최소 2px. 폭 (10 + 100 + 10) × 2 + 2 = 242, 높이 220
      expect(plan.onPaper, isFalse);
      expect((plan.canvasWidth, plan.canvasHeight), (242, 220));
      expect(plan.dividers, const [PixelRect(120, 0, 2, 220)]);
      expect([for (final p in plan.placements) (p.x, p.y)], [(10, 10), (132, 10)]);
    });

    test('긴 변 4000px 초과 입력은 먼저 4000px로 줄이고, 여백·구분선까지 합해 상한을 맞춘다', () {
      final plan = planPng(const [ImageSize(8000, 6000), ImageSize(4000, 3000)], original);

      // 이미지만이면 4000×6000으로 딱 2,400만이다. 여백 200과 구분선 12까지 합하면
      // 4400 × (3400 × 2 + 12) = 29,972,800이라 넘는다. 비율 √(24,000,000 ÷ 29,972,800) = 0.89483
      // 폭 floor(3579.3) = 3579, 장당 높이 floor(2684.5) = 2684, 여백 178.95 → 179, 두께 10.7 → 11
      // 폭 3579 + 358 = 3937, 높이 (2684 + 358) × 2 + 11 = 6095, 총 23,996,015
      expect(plan.canvasWidth, 3937);
      expect(plan.canvasHeight, 6095);
      expect(plan.placements[0].width, 3579);
      expect(plan.placements[0].scale, 3579 / 8000);
      expect(plan.dividerThickness, 11);
      expect(plan.pixelCount, 23996015);
    });

    test('캔버스가 2,400만 픽셀을 넘으면 전체를 같은 비율로 줄인다', () {
      final plan = planPng(List.filled(10, const ImageSize(4000, 3000)), original);

      // 처음 4400 × (3400 × 10 + 12 × 9) = 150,075,200 → 비율 √0.15992 = 0.39990
      // 폭 floor(1599.6) = 1599, 장당 높이 1199.7 → 1200, 여백 79.95 → 80, 두께 4.8 → 5
      // 1759 × (1360 × 10 + 45) = 24,001,555로 아직 넘는다. 비율에 √(상한 ÷ 총) × 0.999를 곱한다 → 0.39949
      // 폭 floor(1597.9) = 1597, 장당 높이 1198.5 → 1198, 여백 79.85 → 80, 두께 4.8 → 5
      // 폭 1597 + 160 = 1757, 높이 (1198 + 160) × 10 + 5 × 9 = 13625, 총 23,939,125
      expect(plan.canvasWidth, 1757);
      expect(plan.canvasHeight, 13625);
      expect(plan.dividerThickness, 5);
      expect(plan.pixelCount, 23939125);
      expect(plan.dividers.length, 9);
    });

    test('자리와 여백과 구분선이 겹치지 않고 캔버스를 빈틈없이 채운다', () {
      final random = math.Random(7);
      for (var trial = 0; trial < 200; trial++) {
        final sizes = List.generate(
          1 + random.nextInt(30),
          (_) => ImageSize(1 + random.nextInt(9000), 1 + random.nextInt(9000)),
        );
        final plan = planPng(sizes, original);
        final vertical = plan.direction == LayoutDirection.vertical;
        final crossLength = vertical ? plan.canvasWidth : plan.canvasHeight;
        // 맨 앞 이미지의 위치가 곧 여백이다.
        final padding = vertical ? plan.placements.first.x : plan.placements.first.y;
        var offset = 0;
        for (var i = 0; i < plan.placements.length; i++) {
          final p = plan.placements[i];
          offset += padding;
          expect(vertical ? p.y : p.x, offset);
          expect(vertical ? p.x : p.y, padding);
          expect(vertical ? p.width : p.height, crossLength - 2 * padding);
          offset += (vertical ? p.height : p.width) + padding;
          if (i < plan.placements.length - 1) {
            final d = plan.dividers[i];
            expect(vertical ? d.y : d.x, offset);
            expect(vertical ? d.width : d.height, crossLength);
            offset += plan.dividerThickness;
          }
        }
        expect(offset, vertical ? plan.canvasHeight : plan.canvasWidth);
        expect(plan.dividers, hasLength(sizes.length - 1));
        expect(plan.pixelCount, lessThanOrEqualTo(24000000));
      }
    });

    group('여백 설정', () {
      const s = ImageSize(1080, 2340);

      test('P=0%: [이미지][선][이미지], 흰 여백이 없다', () {
        final plan = planPng(const [s, s, s], const OutputSettings(paper: PaperSize.original, marginPercent: 0));

        // 폭 1080 × 3 + 7 × 2 = 3254, 높이 2340. 이미지 0, 1087, 2174. 선 1080, 2167.
        expect((plan.canvasWidth, plan.canvasHeight), (3254, 2340));
        expect([for (final p in plan.placements) (p.x, p.y)], [(0, 0), (1087, 0), (2174, 0)]);
        expect(plan.dividers, const [PixelRect(1080, 0, 7, 2340), PixelRect(2167, 0, 7, 2340)]);
      });

      test('P=3%', () {
        final plan = planPng(const [s, s, s], const OutputSettings(paper: PaperSize.original, marginPercent: 3));

        // 여백 2340 × 3% = 70.2 → 70. 폭 (70 + 1080 + 70) × 3 + 7 × 2 = 3674, 높이 2480
        expect((plan.canvasWidth, plan.canvasHeight), (3674, 2480));
        expect((plan.placements[0].x, plan.placements[0].y), (70, 70));
        expect(plan.dividers.first, const PixelRect(1220, 0, 7, 2480));
      });

      test('P=10%', () {
        final plan = planPng(const [s, s, s], const OutputSettings(paper: PaperSize.original, marginPercent: 10));

        // 여백 234. 폭 (234 + 1080 + 234) × 3 + 7 × 2 = 4658, 높이 2808
        expect((plan.canvasWidth, plan.canvasHeight), (4658, 2808));
        expect((plan.placements[0].x, plan.placements[0].y), (234, 234));
        expect(plan.dividers.first, const PixelRect(1548, 0, 7, 2808));
      });

      test('상한 계산에 여백이 들어간다: 사진 10장, P=10%', () {
        final plan = planPng(
          List.filled(10, const ImageSize(4000, 3000)),
          const OutputSettings(paper: PaperSize.original, marginPercent: 10),
        );

        // 처음 4800 × (3800 × 10 + 12 × 9) = 4800 × 38108 = 182,918,400 → 비율 √0.131206 = 0.36222
        // 폭 floor(1448.9) = 1448, 장당 높이 1086.7 → 1087, 여백 144.8 → 145, 두께 4.3 → 4
        // 폭 1448 + 290 = 1738, 높이 (1087 + 290) × 10 + 4 × 9 = 13806, 총 23,994,828
        expect((plan.canvasWidth, plan.canvasHeight), (1738, 13806));
        expect(plan.pixelCount, 23994828);
      });
    });

    group('작은 이미지가 찌그러지지 않게 다른 변은 반올림한다', () {
      test('501×90 + 90×501 + 16×16: 공통 폭 16', () {
        final plan = planPng(const [ImageSize(501, 90), ImageSize(90, 501), ImageSize(16, 16)], original);

        // 비율 곱이 1이라 세로 배치. 90 × 16 ÷ 501 = 2.87 → 3, 501 × 16 ÷ 90 = 89.07 → 89, 16
        expect(plan.direction, LayoutDirection.vertical);
        expect([for (final p in plan.placements) (p.width, p.height)], [(16, 3), (16, 89), (16, 16)]);
      });

      test('501×90 + 32×32: 공통 폭 32', () {
        final plan = planPng(const [ImageSize(501, 90), ImageSize(32, 32)], original);

        // 90 × 32 ÷ 501 = 5.75 → 6
        expect([for (final p in plan.placements) (p.width, p.height)], [(32, 6), (32, 32)]);
      });

      test('.5는 올린다', () {
        final plan = planPng(const [ImageSize(100, 50), ImageSize(25, 25)], original);

        // 공통 폭 25, 50 × 25 ÷ 100 = 12.5 → 13
        expect([for (final p in plan.placements) (p.width, p.height)], [(25, 13), (25, 25)]);
      });

      test('올려서 상한을 넘으면 더 줄여 상한을 지킨다', () {
        final plan = planPng(List.filled(10, const ImageSize(4000, 3000)), original);

        expect(plan.pixelCount, lessThanOrEqualTo(24000000));
      });
    });

    test('용지당 이미지 수와 이미지 크기는 쓰지 않는다', () {
      final plan = planPng(
        const [ImageSize(100, 200), ImageSize(100, 200)],
        const OutputSettings(paper: PaperSize.original, imagesPerPaper: 4, imageSizePercent: 30),
      );

      expect((plan.canvasWidth, plan.canvasHeight), (242, 220));
      expect(plan.placements[1].x, 132);
    });

    test('빈 목록은 오류', () {
      expect(() => planPng(const [], original), throwsArgumentError);
    });
  });
}

void paperTests() {
  group('용지', () {
    test('A4 세로 2장: 페이지 2480×3508을 옆으로, 사이에 7px 구분선, 페이지 여백 124px', () {
      final plan = planPng(const [ImageSize(1080, 2340), ImageSize(1080, 2340)], a4);

      // 방향은 이미지가 아니라 용지 비율로: 210÷297 < 1이라 가로 배치.
      // 여백 2480 × 5% = 124, 칸 2232×3260. 맞춤 비율 min(2232÷1080, 3260÷2340) = 1.39316
      // 폭 1504.6 → 1504, 높이 3260. 왼쪽 124 + (2232 − 1504.6) ÷ 2 = 487.7 → 488, 위 124.
      // 둘째 페이지는 2480 + 7 = 2487에서 시작.
      expect(plan.onPaper, isTrue);
      expect(plan.direction, LayoutDirection.horizontal);
      expect((plan.canvasWidth, plan.canvasHeight), (4967, 3508));
      expect(plan.dividerThickness, 7);
      expect(plan.placements.map((p) => (p.width, p.height)).toSet(), {(1504, 3260)});
      expect((plan.placements[0].x, plan.placements[0].y), (488, 124));
      expect((plan.placements[1].x, plan.placements[1].y), (2487 + 488, 124));
      expect(plan.dividers, const [PixelRect(2480, 0, 7, 3508)]);
    });

    test('A4 가로 2장: 페이지 3508×2480을 위아래로', () {
      final plan = planPng(const [ImageSize(1000, 500), ImageSize(1000, 500)], a4Landscape);

      // 297÷210 ≥ 1이라 세로 배치. 여백 2480 × 5% = 124, 칸 3260×2232.
      // 맞춤 비율 min(3.26, 4.464) = 3.26 → 3260×1630. 왼쪽 124, 위 124 + (2232 − 1630) ÷ 2 = 425
      // 둘째 페이지는 2480 + 7 = 2487에서 시작.
      expect(plan.direction, LayoutDirection.vertical);
      expect((plan.canvasWidth, plan.canvasHeight), (3508, 4967));
      expect(plan.placements.map((p) => (p.width, p.height)).toList(), [(3260, 1630), (3260, 1630)]);
      expect((plan.placements[0].x, plan.placements[0].y), (124, 425));
      expect((plan.placements[1].x, plan.placements[1].y), (124, 2487 + 425));
      expect(plan.dividers, const [PixelRect(0, 2480, 3508, 7)]);
    });

    test('A4 세로 N=2, 3장: 한 페이지에 2장, 칸 사이 가로줄은 여백 안쪽, 마지막 페이지는 선 없음', () {
      final plan = planPng(
        List.filled(3, const ImageSize(1000, 500)),
        const OutputSettings(imagesPerPaper: 2),
      );

      // 페이지 2장 → 캔버스 4967×3508. 여백 124, 간격 99.2, 칸 높이 (3260 − 99.2) ÷ 2 = 1580.4.
      // 맞춤 비율 min(2.232, 3.1608) = 2.232 → 2232×1116.
      // 첫 칸 위 124 + (1580.4 − 1116) ÷ 2 = 356.2 → 356, 아래 1472.2 → 1472
      // 둘째 칸 위 1803.6 + 232.2 = 2035.8 → 2036, 아래 3151.8 → 3152
      // 가로줄: 첫 칸 아래 1704.4 + (99.2 − 7) ÷ 2 = 1750.5 → 1751, 폭은 여백 안쪽 2232
      expect((plan.canvasWidth, plan.canvasHeight), (4967, 3508));
      expect(plan.placements.map((p) => (p.x, p.y, p.width, p.height)).toList(), [
        (124, 356, 2232, 1116),
        (124, 2036, 2232, 1116),
        (2487 + 124, 356, 2232, 1116),
      ]);
      expect(plan.dividers, const [
        PixelRect(124, 1751, 2232, 7),
        PixelRect(2480, 0, 7, 3508),
      ]);
    });

    test('A4 가로 N=2, 2장: 칸이 좌우로, 줄 높이만큼의 세로줄', () {
      final plan = planPng(
        List.filled(2, const ImageSize(1000, 1000)),
        const OutputSettings(orientation: PaperOrientation.landscape, imagesPerPaper: 2),
      );

      // 페이지 3508×2480, 여백 124, 간격 99.2, 칸 (3260 − 99.2) ÷ 2 = 1580.4 × 2232.
      // 정사각형 1580.4. 왼쪽 124, 오른쪽 1704.4 → 1704, 폭 1580
      // 위 124 + (2232 − 1580.4) ÷ 2 = 449.8 → 450
      // 둘째 칸 왼쪽 1803.6 → 1804, 오른쪽 3384, 폭 1580
      // 세로줄: 첫 칸 오른쪽 1704.4 + (99.2 − 7) ÷ 2 = 1750.5 → 1751, 줄은 124에서 높이 2232
      expect((plan.canvasWidth, plan.canvasHeight), (3508, 2480));
      expect(plan.placements[0].x, 124);
      expect(plan.placements[0].y, 450);
      expect(plan.placements[0].width, 1580);
      expect(plan.placements[1].x, 1804);
      expect(plan.placements[1].width, 1580);
      expect(plan.dividers, const [PixelRect(1751, 124, 7, 2232)]);
    });

    test('N=4, 3장: 빈 칸 쪽으로 세로줄을 긋지 않는다', () {
      final plan = planPng(
        List.filled(3, const ImageSize(1000, 1000)),
        const OutputSettings(imagesPerPaper: 4),
      );

      // 칸 폭 (2232 − 99.2) ÷ 2 = 1066.4, 세로줄 124 + 1066.4 + 46.1 = 1236.5 → 1237
      // 칸 높이 1580.4, 첫 줄 124~1704.4 → 1704라 높이 1580. 가로줄 위치 1751, 폭은 여백 안쪽 2232.
      expect(plan.dividers, const [
        PixelRect(1237, 124, 7, 1580),
        PixelRect(124, 1751, 2232, 7),
      ]);
    });

    test('F=50%: 맞춘 크기의 절반을 칸 가운데에', () {
      final plan = planPng(
        List.filled(2, const ImageSize(1000, 500)),
        const OutputSettings(imageSizePercent: 50),
      );

      // 맞춤 2232×1116 → 절반 1116×558. 왼쪽 124 + (2232 − 1116) ÷ 2 = 682, 위 124 + (3260 − 558) ÷ 2 = 1475
      expect(plan.placements.map((p) => (p.x, p.y, p.width, p.height)).toList(), [
        (682, 1475, 1116, 558),
        (2487 + 682, 1475, 1116, 558),
      ]);
      expect(plan.placements[0].scale, 1116 / 1000);
    });

    test('F=30%', () {
      final plan = planPng(
        List.filled(2, const ImageSize(1000, 500)),
        const OutputSettings(imageSizePercent: 30),
      );

      // 맞춤 2232×1116 → 30% 669.6×334.8.
      // 왼쪽 124 + (2232 − 669.6) ÷ 2 = 905.2 → 905, 오른쪽 1574.8 → 1575, 폭 670
      // 위 124 + (3260 − 334.8) ÷ 2 = 1586.6 → 1587, 아래 1921.4 → 1921, 높이 334
      expect(plan.placements[0].width, 670);
      expect(plan.placements[0].height, 334);
      expect(plan.placements[0].x, 905);
      expect(plan.placements[0].y, 1587);
    });

    test('작은 이미지도 칸에 맞춰 키운다', () {
      final plan = planPng(const [ImageSize(10, 10), ImageSize(10, 10)], a4);

      // 칸 폭 2232에 맞춘다.
      expect(plan.placements[0].width, 2232);
      expect(plan.placements[0].scale, 223.2);
    });

    group('여백 설정: A4 세로 N=2, 1000×500 2장', () {
      PngPlan planFor(int percent) => planPng(
            List.filled(2, const ImageSize(1000, 500)),
            OutputSettings(imagesPerPaper: 2, marginPercent: percent),
          );

      test('P=0%: 여백 없음, 칸 사이는 구분선 두께만큼, 선은 용지 폭 전체', () {
        final plan = planFor(0);

        // 간격 7, 칸 높이 (3508 − 7) ÷ 2 = 1750.5. 이미지 2480×1240.
        // 첫 칸 위 (1750.5 − 1240) ÷ 2 = 255.25 → 255, 아래 1495.25 → 1495
        // 둘째 칸 위 1757.5 + 255.25 = 2012.75 → 2013, 아래 3252.75 → 3253
        expect(plan.placements.map((p) => (p.x, p.y, p.width, p.height)).toList(), [
          (0, 255, 2480, 1240),
          (0, 2013, 2480, 1240),
        ]);
        expect(plan.dividers, const [PixelRect(0, 1751, 2480, 7)]);
      });

      test('P=3%: 여백 74.4, 간격 59.52', () {
        final plan = planFor(3);

        // 칸 폭 2331.2, 높이 (3359.2 − 59.52) ÷ 2 = 1649.84. 이미지 2331.2×1165.6.
        // 왼쪽 74.4 → 74, 오른쪽 2405.6 → 2406, 폭 2332
        // 첫 칸 위 74.4 + 242.12 = 316.52 → 317, 아래 1482.12 → 1482, 높이 1165
        // 둘째 칸 위 1783.76 + 242.12 = 2025.88 → 2026, 아래 3191.48 → 3191, 높이 1165
        expect(plan.placements.map((p) => (p.x, p.y, p.width, p.height)).toList(), [
          (74, 317, 2332, 1165),
          (74, 2026, 2332, 1165),
        ]);
        expect(plan.dividers, const [PixelRect(74, 1751, 2332, 7)]);
      });

      test('P=10%: 여백 248, 간격 198.4', () {
        final plan = planFor(10);

        // 칸 폭 1984, 높이 (3012 − 198.4) ÷ 2 = 1406.8. 이미지 1984×992.
        // 첫 칸 위 248 + 207.4 = 455.4 → 455, 둘째 칸 위 1853.2 + 207.4 = 2060.6 → 2061
        expect(plan.placements.map((p) => (p.x, p.y, p.width, p.height)).toList(), [
          (248, 455, 1984, 992),
          (248, 2061, 1984, 992),
        ]);
        expect(plan.dividers, const [PixelRect(248, 1751, 1984, 7)]);
      });

      test('P=0%, 세로로 긴 이미지: 이미지가 선에 맞닿아 선으로만 나뉜다', () {
        final plan = planPng(
          List.filled(2, const ImageSize(1000, 2000)),
          const OutputSettings(imagesPerPaper: 2, marginPercent: 0),
        );

        // 위 칸 0~1751을 채워 높이 1751, 아래 칸 1758~3508을 채워 높이 1750. 선은 1751~1757.
        final line = plan.dividers.single;
        expect(plan.placements[0].y + plan.placements[0].height, line.y);
        expect(plan.placements[1].y, line.y + line.height);
        expect(plan.placements[1].y + plan.placements[1].height, 3508);
      });

      test('P=0%, 페이지 사이: 캔버스 전체 길이의 선만 있다', () {
        final plan = planPng(
          List.filled(2, const ImageSize(2480, 3508)),
          const OutputSettings(marginPercent: 0),
        );

        // 이미지가 페이지를 꽉 채운다. 2480 + 7 + 2480
        expect((plan.canvasWidth, plan.canvasHeight), (4967, 3508));
        expect(plan.placements.map((p) => (p.x, p.y, p.width, p.height)).toList(), [
          (0, 0, 2480, 3508),
          (2487, 0, 2480, 3508),
        ]);
        expect(plan.dividers, const [PixelRect(2480, 0, 7, 3508)]);
      });
    });

    group('캔버스 상한은 구분선까지 포함한다', () {
      test('3페이지', () {
        final plan = planPng(List.filled(3, const ImageSize(100, 100)), a4);

        // 3508 × (2480 × 3 + 7 × 2) = 26,148,632 → 비율 √(24,000,000 ÷ 26,148,632) = 0.95803
        // 폭 floor(2480 × 0.95803) = 2375, 높이 floor(3508 × 0.95803) = 3360, 두께 7.1 → 7
        // 폭 2375 × 3 + 7 × 2 = 7139, 총 7139 × 3360 = 23,987,040 (약 287DPI)
        expect((plan.canvasWidth, plan.canvasHeight), (7139, 3360));
        expect(plan.dividerThickness, 7);
        expect(plan.pixelCount, 23987040);
      });

      test('10페이지', () {
        final plan = planPng(List.filled(10, const ImageSize(100, 100)), a4);

        // 3508 × (24800 + 63) = 87,219,404 → 비율 √0.27517 = 0.52456
        // 폭 floor(1300.9) = 1300, 높이 floor(1840.2) = 1840, 두께 3.9 → 4
        // 폭 1300 × 10 + 4 × 9 = 13036, 총 13036 × 1840 = 23,986,240 (약 157DPI)
        expect((plan.canvasWidth, plan.canvasHeight), (13036, 1840));
        expect(plan.dividerThickness, 4);
        expect(plan.pixelCount, 23986240);
      });

      test('이미지만 세면 상한 안이어도 구분선까지 세면 넘으면 줄인다', () {
        // 페이지만 2480 × 2 × 3508 = 17,399,680. 구분선까지 4967 × 3508 = 17,424,236
        // 상한을 페이지만의 값으로 두면 넘는다. 비율 √(17,399,680 ÷ 17,424,236) = 0.99930
        // 폭 floor(2478.25) = 2478, 높이 floor(3505.53) = 3505, 두께 7.4 → 7
        // 폭 2478 × 2 + 7 = 4963, 총 4963 × 3505 = 17,395,315
        final plan = planPng(
          List.filled(2, const ImageSize(100, 100)),
          a4,
          maxCanvasPixels: 17399680,
        );

        expect((plan.canvasWidth, plan.canvasHeight), (4963, 3505));
        expect(plan.pixelCount, 17395315);
      });

      test('30페이지: 두께와 여백은 줄어든 짧은 변으로 다시 잰다', () {
        final plan = planPng(List.filled(30, const ImageSize(100, 100)), a4);

        // 3508 × (74400 + 203) = 261,707,324 → 비율 √0.091706 = 0.30283
        // 폭 floor(751.1) = 751, 높이 floor(1062.3) = 1062, 두께 2.25 → 2
        // 폭 751 × 30 + 2 × 29 = 22588, 총 22588 × 1062 = 23,988,456 (약 91DPI)
        expect((plan.canvasWidth, plan.canvasHeight), (22588, 1062));
        expect(plan.dividerThickness, 2);
        expect(plan.pixelCount, 23988456);
        expect(plan.dividers, hasLength(29));
        expect(plan.dividers.first, const PixelRect(751, 0, 2, 1062));
        // 여백 751 × 5% = 37.55, 칸 675.9×986.9, 정사각형 675.9.
        // 왼쪽 37.55 → 38, 오른쪽 713.45 → 713, 폭 675
        // 위 37.55 + (986.9 − 675.9) ÷ 2 = 193.05 → 193. 둘째 페이지는 753에서 시작.
        expect(plan.placements[0].width, 675);
        expect((plan.placements[0].x, plan.placements[0].y), (38, 193));
        expect(plan.placements[1].x, 753 + 38);
      });

      test('30페이지 가로 용지는 위아래로 쌓는다', () {
        final plan = planPng(List.filled(30, const ImageSize(100, 100)), a4Landscape);

        expect((plan.canvasWidth, plan.canvasHeight), (1062, 22588));
        expect(plan.direction, LayoutDirection.vertical);
        expect(plan.dividers.first, const PixelRect(0, 751, 1062, 2));
      });
    });

    test('A3도 페이지 크기가 300DPI이고, 상한을 낮추면 줄인다', () {
      final plan = planPng(const [ImageSize(100, 100)], const OutputSettings(paper: PaperSize.a3));
      expect((plan.canvasWidth, plan.canvasHeight), (3508, 4961));
      expect(plan.pixelCount, lessThan(24000000));

      final capped = planPng(
        const [ImageSize(100, 100), ImageSize(100, 100)],
        const OutputSettings(paper: PaperSize.a3),
        maxCanvasPixels: 1000000,
      );
      expect(capped.pixelCount, lessThanOrEqualTo(1000000));
    });

    test('모든 자리와 구분선이 캔버스 안에 있고 구분선이 이미지를 덮지 않는다: 모든 N과 F와 P', () {
      final random = math.Random(11);
      for (final orientation in PaperOrientation.values) {
        for (final n in kImagesPerPaperChoices) {
          for (final percent in kImageSizePercentChoices) {
            for (final margin in kMarginPercentChoices) {
              final sizes = List.generate(
                2 + random.nextInt(29),
                (_) => ImageSize(1 + random.nextInt(4000), 1 + random.nextInt(4000)),
              );
              final plan = planPng(
                sizes,
                OutputSettings(
                  orientation: orientation,
                  imagesPerPaper: n,
                  imageSizePercent: percent,
                  marginPercent: margin,
                ),
              );

              expect(plan.placements, hasLength(sizes.length));
              expect(plan.pixelCount, lessThanOrEqualTo(24000000));
              for (final d in plan.dividers) {
                expect(d.x, greaterThanOrEqualTo(0));
                expect(d.y, greaterThanOrEqualTo(0));
                expect(d.x + d.width, lessThanOrEqualTo(plan.canvasWidth));
                expect(d.y + d.height, lessThanOrEqualTo(plan.canvasHeight));
              }
              for (final p in plan.placements) {
                expect(p.width, greaterThanOrEqualTo(1));
                expect(p.height, greaterThanOrEqualTo(1));
                expect(p.x, greaterThanOrEqualTo(0));
                expect(p.y, greaterThanOrEqualTo(0));
                expect(p.x + p.width, lessThanOrEqualTo(plan.canvasWidth));
                expect(p.y + p.height, lessThanOrEqualTo(plan.canvasHeight));
                for (final d in plan.dividers) {
                  final apart = p.x + p.width <= d.x ||
                      d.x + d.width <= p.x ||
                      p.y + p.height <= d.y ||
                      d.y + d.height <= p.y;
                  expect(apart, isTrue, reason: '$orientation N=$n F=$percent P=$margin 자리 ${p.x},${p.y} $d');
                }
              }
            }
          }
        }
      }
    });
  });
}
