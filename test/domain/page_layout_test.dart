import 'package:flutter_test/flutter_test.dart';
import 'package:image_merger/core/image_size.dart';
import 'package:image_merger/features/image_merger/domain/output_settings.dart';
import 'package:image_merger/features/image_merger/domain/page_layout.dart';

// 기대값은 함수를 다시 불러 구하지 않고 설계 규칙(DESIGN §2.1.2)에서 손으로 계산해 적었다.

void main() {
  group('pageGrid: 표의 짧은 변 × 긴 변을 용지 방향에 맞춘다', () {
    // N: (짧은 변 칸 수, 긴 변 칸 수)
    const table = {1: (1, 1), 2: (1, 2), 3: (1, 3), 4: (2, 2), 6: (2, 3), 8: (2, 4), 9: (3, 3)};

    table.forEach((n, cells) {
      final (shortCells, longCells) = cells;
      test('N=$n 세로 용지: 폭이 짧은 변이라 가로 $shortCells칸, 세로 $longCells칸', () {
        expect(
          pageGrid(n, PaperOrientation.portrait),
          PageGrid(columns: shortCells, rows: longCells),
        );
      });
      test('N=$n 가로 용지: 높이가 짧은 변이라 가로 $longCells칸, 세로 $shortCells칸', () {
        expect(
          pageGrid(n, PaperOrientation.landscape),
          PageGrid(columns: longCells, rows: shortCells),
        );
      });
    });

    test('선택지에 없는 값은 오류', () {
      expect(() => pageGrid(5, PaperOrientation.portrait), throwsArgumentError);
    });
  });

  group('sheetCount = ⌈항목 수 ÷ N⌉', () {
    for (final (items, n, pages) in const [
      (5, 1, 5),
      (5, 2, 3),
      (6, 2, 3),
      (2, 9, 1),
      (9, 9, 1),
      (10, 9, 2),
      (30, 4, 8),
    ]) {
      test('$items개, 용지당 $n개 → $pages페이지', () => expect(sheetCount(items, n), pages));
    }
  });

  group('cellRects', () {
    void check(
      Map<int, (int, int, double, double)> cases,
      PaperOrientation orientation,
      double pageWidth,
      double pageHeight, {
      required int percent,
      required double margin,
      required double gap,
    }) {
      cases.forEach((n, expected) {
        final (columns, rows, width, height) = expected;
        test('${orientation.name} 여백 $percent% N=$n: $columns열 $rows행, 칸 $width×$height', () {
          final cells = cellRects(pageWidth, pageHeight, pageGrid(n, orientation), marginPercent: percent);

          expect(cells, hasLength(columns * rows));
          for (var row = 0; row < rows; row++) {
            for (var column = 0; column < columns; column++) {
              final cell = cells[row * columns + column];
              expect(cell.width, closeTo(width, 1e-3));
              expect(cell.height, closeTo(height, 1e-3));
              expect(cell.left, closeTo(margin + column * (width + gap), 1e-3));
              expect(cell.top, closeTo(margin + row * (height + gap), 1e-3));
            }
          }
          // 왼쪽에서 오른쪽, 위에서 아래 순서이고 마지막 칸이 여백 안쪽 끝에 닿는다.
          expect(cells.last.right, closeTo(pageWidth - margin, 1e-3));
          expect(cells.last.bottom, closeTo(pageHeight - margin, 1e-3));
        });
      });
    }

    // 세로 용지 1000×1400, 가로 용지 1400×1000. 여백 = 짧은 변 1000 × P, 간격 = 여백 × 0.8.
    // 칸 폭 = (폭 − 2 × 여백 − 간격 × (열 − 1)) ÷ 열, 칸 높이 = (높이 − 2 × 여백 − 간격 × (행 − 1)) ÷ 행

    // P=5%: 여백 50, 간격 40. 안쪽 900×1300
    check(
      const {
        1: (1, 1, 900.0, 1300.0),
        2: (1, 2, 900.0, 630.0), // (1300 − 40) ÷ 2
        3: (1, 3, 900.0, 406.6667), // (1300 − 80) ÷ 3
        4: (2, 2, 430.0, 630.0), // (900 − 40) ÷ 2
        6: (2, 3, 430.0, 406.6667),
        8: (2, 4, 430.0, 295.0), // (1300 − 120) ÷ 4
        9: (3, 3, 273.3333, 406.6667), // (900 − 80) ÷ 3
      },
      PaperOrientation.portrait,
      1000,
      1400,
      percent: 5,
      margin: 50,
      gap: 40,
    );
    check(
      const {
        1: (1, 1, 1300.0, 900.0),
        2: (2, 1, 630.0, 900.0),
        3: (3, 1, 406.6667, 900.0),
        4: (2, 2, 630.0, 430.0),
        6: (3, 2, 406.6667, 430.0),
        8: (4, 2, 295.0, 430.0),
        9: (3, 3, 406.6667, 273.3333),
      },
      PaperOrientation.landscape,
      1400,
      1000,
      percent: 5,
      margin: 50,
      gap: 40,
    );

    // P=0%: 여백도 간격도 없어 칸이 맞닿는다 (PDF).
    check(
      const {
        1: (1, 1, 1000.0, 1400.0),
        2: (1, 2, 1000.0, 700.0),
        3: (1, 3, 1000.0, 466.6667),
        4: (2, 2, 500.0, 700.0),
        6: (2, 3, 500.0, 466.6667),
        8: (2, 4, 500.0, 350.0),
        9: (3, 3, 333.3333, 466.6667),
      },
      PaperOrientation.portrait,
      1000,
      1400,
      percent: 0,
      margin: 0,
      gap: 0,
    );
    check(
      const {
        2: (2, 1, 700.0, 1000.0),
        9: (3, 3, 466.6667, 333.3333),
      },
      PaperOrientation.landscape,
      1400,
      1000,
      percent: 0,
      margin: 0,
      gap: 0,
    );

    // P=3%: 여백 30, 간격 24. 안쪽 940×1340
    check(
      const {
        2: (1, 2, 940.0, 658.0), // (1340 − 24) ÷ 2
        3: (1, 3, 940.0, 430.6667), // (1340 − 48) ÷ 3
        4: (2, 2, 458.0, 658.0), // (940 − 24) ÷ 2
        8: (2, 4, 458.0, 317.0), // (1340 − 72) ÷ 4
        9: (3, 3, 297.3333, 430.6667), // (940 − 48) ÷ 3
      },
      PaperOrientation.portrait,
      1000,
      1400,
      percent: 3,
      margin: 30,
      gap: 24,
    );

    // P=10%: 여백 100, 간격 80. 안쪽 800×1200
    check(
      const {
        2: (1, 2, 800.0, 560.0), // (1200 − 80) ÷ 2
        3: (1, 3, 800.0, 346.6667), // (1200 − 160) ÷ 3
        4: (2, 2, 360.0, 560.0), // (800 − 80) ÷ 2
        8: (2, 4, 360.0, 240.0), // (1200 − 240) ÷ 4
        9: (3, 3, 213.3333, 346.6667), // (800 − 160) ÷ 3
      },
      PaperOrientation.portrait,
      1000,
      1400,
      percent: 10,
      margin: 100,
      gap: 80,
    );

    group('A4 300DPI: 여백과 간격은 실수 그대로다', () {
      const twoRows = PageGrid(columns: 1, rows: 2);

      void expectCells(int percent, double margin, double gap) {
        final cells = cellRects(2480, 3508, twoRows, marginPercent: percent, minGap: 7);
        expect(cells.first.left, closeTo(margin, 1e-9));
        expect(cells.first.top, closeTo(margin, 1e-9));
        expect(cells.first.width, closeTo(2480 - 2 * margin, 1e-9));
        expect(cells.last.top - cells.first.bottom, closeTo(gap, 1e-9));
        expect(cells.last.bottom, closeTo(3508 - margin, 1e-9));
      }

      test('P=5: 여백 124(2480 × 5%), 간격 99.2', () => expectCells(5, 124, 99.2));
      test('P=10: 여백 248(2480 × 10%), 간격 198.4', () => expectCells(10, 248, 198.4));
      test('P=3: 여백 74.4, 간격 59.52', () => expectCells(3, 74.4, 59.52));
      test('P=0: 여백 없음, 간격은 정확히 구분선 두께 7', () => expectCells(0, 0, 7));
    });

    test('포인트로 재면 A4의 여백은 29.76pt, 간격은 23.81pt다', () {
      // 595.2756 × 5% = 29.7638, × 0.8 = 23.8110
      final cells = cellRects(595.2756, 841.8898, const PageGrid(columns: 1, rows: 2), marginPercent: 5);

      expect(cells.first.left, closeTo(29.7638, 1e-3));
      expect(cells.last.top - cells.first.bottom, closeTo(23.8110, 1e-3));
    });
  });

  group('fitInCell: 칸에 맞춘 뒤 가로·세로에 F를 곱하고 가운데에 놓는다', () {
    const cell = LayoutRect(10, 20, 100, 200);
    const wide = ImageSize(400, 100);

    test('F=100%: 폭을 채우고 위아래 가운데', () {
      // 맞춤 비율 min(100÷400, 200÷100) = 0.25 → 100×25. 위 = 20 + (200 − 25) ÷ 2 = 107.5
      final r = fitInCell(wide, cell, 1);
      expect((r.left, r.top, r.width, r.height), (10, 107.5, 100, 25));
    });

    test('F=50%: 변의 길이가 절반이고 칸 가운데는 그대로', () {
      // 50×12.5. 왼쪽 = 10 + (100 − 50) ÷ 2 = 35, 위 = 20 + (200 − 12.5) ÷ 2 = 113.75
      final r = fitInCell(wide, cell, 0.5);
      expect((r.left, r.top, r.width, r.height), (35, 113.75, 50, 12.5));
    });

    test('F=30%', () {
      // 30×7.5. 왼쪽 = 10 + 35 = 45, 위 = 20 + 96.25 = 116.25
      final r = fitInCell(wide, cell, 0.3);
      expect(r.width, closeTo(30, 1e-9));
      expect(r.height, closeTo(7.5, 1e-9));
      expect(r.left, closeTo(45, 1e-9));
      expect(r.top, closeTo(116.25, 1e-9));
    });

    test('세로로 긴 이미지는 높이를 채운다', () {
      // 맞춤 비율 min(100÷50, 200÷800) = 0.25 → 12.5×200
      final r = fitInCell(const ImageSize(50, 800), cell, 1);
      expect((r.left, r.top, r.width, r.height), (53.75, 20, 12.5, 200));
    });

    test('칸보다 작은 이미지도 칸에 맞춰 키운다', () {
      // 맞춤 비율 min(100÷10, 200÷10) = 10 → 100×100
      final r = fitInCell(const ImageSize(10, 10), cell, 1);
      expect((r.width, r.height), (100, 100));
    });
  });

  group('layoutSheets', () {
    const square = ImageSize(100, 100);

    test('N=2, 5장, 여백 0%: 2장·2장·1장으로 묶고 순서를 지킨다', () {
      final sheets = layoutSheets(
        List.filled(5, square),
        pageWidth: 1000,
        pageHeight: 1400,
        settings: const OutputSettings(imagesPerPaper: 2, marginPercent: 0),
      );

      expect([for (final s in sheets) s.map((i) => i.imageIndex).toList()], [
        [0, 1],
        [2, 3],
        [4],
      ]);
      // 칸 1000×700. 정사각형은 700×700, 왼쪽 (1000 − 700) ÷ 2 = 150
      expect(sheets[0][0].rect.left, 150);
      expect(sheets[0][0].rect.top, 0);
      // 간격이 없어 아래 칸은 바로 700에서 시작한다.
      expect(sheets[0][1].rect.top, 700);
      expect(sheets[2][0].rect.top, 0, reason: '마지막 페이지의 첫 칸');
    });

    test('N=2, 여백 5%: 칸이 여백 안쪽에 있다', () {
      final sheets = layoutSheets(
        List.filled(2, square),
        pageWidth: 1000,
        pageHeight: 1400,
        settings: const OutputSettings(imagesPerPaper: 2),
      );

      // 칸 900×630. 정사각형 630×630, 왼쪽 50 + (900 − 630) ÷ 2 = 185, 위 50
      final first = sheets.single[0].rect;
      expect(first.width, closeTo(630, 1e-9));
      expect(first.left, closeTo(185, 1e-9));
      expect(first.top, closeTo(50, 1e-9));
      // 둘째 칸 위 50 + 630 + 40 = 720
      expect(sheets.single[1].rect.top, closeTo(720, 1e-9));
    });

    test('N=4, F=50%, 여백 5%: 칸마다 가운데', () {
      final sheets = layoutSheets(
        List.filled(4, square),
        pageWidth: 1000,
        pageHeight: 1400,
        settings: const OutputSettings(imagesPerPaper: 4, imageSizePercent: 50),
      );

      // 칸 430×630. 맞춤 430 → F=50%면 215. 넷째 칸은 왼쪽 50 + 430 + 40 = 520, 위 50 + 630 + 40 = 720
      // 칸 안에서 왼쪽 (430 − 215) ÷ 2 = 107.5, 위 (630 − 215) ÷ 2 = 207.5
      final last = sheets.single.last.rect;
      expect(last.width, closeTo(215, 1e-9));
      expect(last.left, closeTo(520 + 107.5, 1e-9));
      expect(last.top, closeTo(720 + 207.5, 1e-9));
    });
  });

  group('반올림: 0.5는 올리고, 사각형은 변마다 맞춘다', () {
    for (final (value, expected) in const [
      (0.0, 0),
      (0.49, 0),
      (0.5, 1),
      (1.5, 2),
      (2.5, 3),
      (1750.5, 1751),
      (1750.49, 1750),
    ]) {
      test('$value → $expected', () => expect(snapPx(value), expected));
    }

    test('부동소수점 오차로 .5 바로 아래가 되어도 올린다', () {
      // 0.1 + 0.2 + 1.2 = 1.5000000000000002처럼 어긋나는 값의 반대쪽이다.
      expect(snapPx(1.4999999999999), 2);
    });

    test('폭을 더해 가지 않고 네 변을 각각 맞춘다', () {
      // 왼쪽 905.2 → 905, 오른쪽 905.2 + 669.6 = 1574.8 → 1575, 폭 670
      // 위 1586.6 → 1587, 아래 1586.6 + 334.8 = 1921.4 → 1921, 높이 334
      expect(snapRect(const LayoutRect(905.2, 1586.6, 669.6, 334.8)), const PixelRect(905, 1587, 670, 334));
    });

    test('아주 작아도 1px은 남긴다', () {
      expect(snapRect(const LayoutRect(10.1, 10.1, 0.1, 0.1)), const PixelRect(10, 10, 1, 1));
    });
  });

  group('scaleDividers: 줄인 캔버스에서 옛 선이 닿는 칸을 모두 덮는다', () {
    // 줄인 칸 i는 원본 [⌊i × 원본 ÷ 줄인 크기⌋, ⌊(i + 1) × 원본 ÷ 줄인 크기⌋)의 평균이다.
    test('7px 선, 1000 → 547: 옛 선이 닿는 다섯 줄', () {
      // 원본 y 200~206. 칸 108은 197~198이라 안 닿고, 칸 109는 199~200, 칸 113은 206~207이라 닿는다.
      // 칸 114는 208~209라 안 닿는다. 그래서 109~113, 다섯 줄이다.
      final scaled = scaleDividers(
        const [PixelRect(0, 200, 1000, 7)],
        fromWidth: 1000,
        fromHeight: 1000,
        toWidth: 547,
        toHeight: 547,
      );

      expect(scaled, const [PixelRect(0, 109, 547, 5)]);
    });

    test('세로줄과 가로줄을 절반으로', () {
      // 칸 i는 원본 2i, 2i + 1. 원본 100~106은 칸 50~53에 닿는다.
      final scaled = scaleDividers(
        const [PixelRect(100, 0, 7, 500), PixelRect(0, 100, 1000, 7)],
        fromWidth: 1000,
        fromHeight: 500,
        toWidth: 500,
        toHeight: 250,
      );

      expect(scaled, const [PixelRect(50, 0, 4, 250), PixelRect(0, 50, 500, 4)]);
    });

    test('줄 높이만큼의 선은 양쪽 끝도 닿는 칸까지 덮는다', () {
      // 비율 1/2. 세로로 원본 124~1704는 칸 62~852, 가로로 원본 1237~1243은 칸 618~621
      final scaled = scaleDividers(
        const [PixelRect(1237, 124, 7, 1581)],
        fromWidth: 2480,
        fromHeight: 3508,
        toWidth: 1240,
        toHeight: 1754,
      );

      expect(scaled, const [PixelRect(618, 62, 4, 791)]);
    });

    test('2px 아래로 줄지 않는다', () {
      // 1000 → 300: 칸 i는 원본 ⌊3.33i⌋부터 ⌊3.33(i + 1)⌋ 전까지다.
      // 원본 500~501은 칸 150(500~502)에만 닿아 한 칸이지만 최소 2px로 칸 150~151을 칠한다.
      final scaled = scaleDividers(
        const [PixelRect(500, 0, 2, 1000)],
        fromWidth: 1000,
        fromHeight: 1000,
        toWidth: 300,
        toHeight: 300,
      );

      expect(scaled, const [PixelRect(150, 0, 2, 300)]);
    });

    test('캔버스 끝의 선도 2px을 지키며 안쪽으로 들어온다', () {
      // 1000 → 300: 원본 998~999는 마지막 칸 299에 닿는다. 2px이 되도록 칸 298~299를 칠한다.
      final scaled = scaleDividers(
        const [PixelRect(998, 0, 2, 1000)],
        fromWidth: 1000,
        fromHeight: 1000,
        toWidth: 300,
        toHeight: 300,
      );

      expect(scaled, const [PixelRect(298, 0, 2, 300)]);
    });

    test('캔버스 전체 길이의 선은 줄어도 전체 길이다', () {
      final scaled = scaleDividers(
        const [PixelRect(2480, 0, 7, 3508)],
        fromWidth: 4967,
        fromHeight: 3508,
        toWidth: 2483,
        toHeight: 1754,
      );

      expect(scaled.single.y, 0);
      expect(scaled.single.height, 1754);
    });
  });

  group('dividerThickness = 기준 변의 0.3%, 최소 2px', () {
    // 2480 × 0.003 = 7.44 → 7, 751 → 2.25 → 2, 1000 → 3, 3508 → 10.52 → 11, 4000 → 12
    for (final (side, thickness) in const [
      (100, 2),
      (751, 2),
      (1000, 3),
      (2480, 7),
      (3508, 11),
      (4000, 12),
    ]) {
      test('$side → $thickness', () => expect(dividerThickness(side), thickness));
    }
  });

  group('sheetDividers: 칸 사이 간격의 가운데, 여백 안쪽', () {
    List<PixelRect> lines(
      int pageWidth,
      int pageHeight,
      PageGrid grid,
      int filled, {
      int thickness = 4,
      int marginPercent = 5,
    }) =>
        sheetDividers(
          pageWidth: pageWidth,
          pageHeight: pageHeight,
          grid: grid,
          filled: filled,
          thickness: thickness,
          marginPercent: marginPercent,
        );

    const oneByTwo = PageGrid(columns: 1, rows: 2);
    const twoByOne = PageGrid(columns: 2, rows: 1);
    const twoByTwo = PageGrid(columns: 2, rows: 2);
    const threeByThree = PageGrid(columns: 3, rows: 3);

    // 1000×1400, 여백 50, 간격 40, 두께 4. 여백 안쪽은 가로 50~950, 세로 50~1350.
    // 2행이면 칸 높이 630, 간격 680~720, 가운데 700, 선은 698~702.
    // 2열이면 칸 폭 430, 간격 480~520, 가운데 500, 선은 498~502.
    test('N=1은 선이 없다', () {
      expect(lines(1000, 1400, const PageGrid(columns: 1, rows: 1), 1), isEmpty);
    });

    test('세로 용지 N=2: 여백 안쪽 폭 전체의 가로줄', () {
      expect(lines(1000, 1400, oneByTwo, 2), [const PixelRect(50, 698, 900, 4)]);
    });

    test('아래 칸이 비면 가로줄을 긋지 않는다', () {
      expect(lines(1000, 1400, oneByTwo, 1), isEmpty);
    });

    test('가로 용지 N=2: 줄 높이만큼의 세로줄', () {
      // 1400×1000, 2열이면 칸 폭 630, 간격 680~720, 가운데 700. 줄은 50~950.
      expect(lines(1400, 1000, twoByOne, 2), [const PixelRect(698, 50, 4, 900)]);
    });

    test('N=4 꽉 참: 가로줄 하나, 줄마다 세로줄', () {
      expect(lines(1000, 1400, twoByTwo, 4), [
        const PixelRect(498, 50, 4, 630),
        const PixelRect(50, 698, 900, 4),
        const PixelRect(498, 720, 4, 630),
      ]);
    });

    test('N=4, 3장: 마지막 페이지의 빈 칸 쪽으로는 세로줄을 긋지 않는다', () {
      expect(lines(1000, 1400, twoByTwo, 3), [
        const PixelRect(498, 50, 4, 630),
        const PixelRect(50, 698, 900, 4),
      ]);
    });

    test('N=4, 2장: 아래 줄이 비어 가로줄도 없다', () {
      expect(lines(1000, 1400, twoByTwo, 2), [const PixelRect(498, 50, 4, 630)]);
    });

    test('N=4, 1장: 선이 없다', () {
      expect(lines(1000, 1400, twoByTwo, 1), isEmpty);
    });

    test('N=9, 5장: 첫 줄 세로줄 2개, 가로줄, 둘째 줄 세로줄 1개', () {
      // 칸 폭 273.33. 세로 간격 323.33~363.33(가운데 343.33, 선 위치 341.33 → 341)
      // 636.67~676.67(가운데 656.67, 선 위치 654.67 → 655)
      // 칸 높이 406.67. 첫 줄 50 → 456.67(457)이라 줄 높이 407.
      // 가로 간격 456.67~496.67, 가운데 476.67, 선 위치 474.67 → 475
      // 둘째 줄은 496.67 → 497에서 903.33 → 903까지라 높이 406
      expect(lines(1000, 1400, threeByThree, 5), [
        const PixelRect(341, 50, 4, 407),
        const PixelRect(655, 50, 4, 407),
        const PixelRect(50, 475, 900, 4),
        const PixelRect(341, 497, 4, 406),
      ]);
    });

    test('P=10%: 여백 100 안쪽 폭 800의 가로줄', () {
      // 칸 높이 560, 간격 660~740, 가운데 700, 선 698~702
      expect(lines(1000, 1400, oneByTwo, 2, marginPercent: 10), [const PixelRect(100, 698, 800, 4)]);
    });

    test('P=10%, N=4', () {
      // 칸 360×560. 세로 간격 460~540, 가운데 500, 선 498~502. 줄은 100~660, 740~1300.
      expect(lines(1000, 1400, twoByTwo, 4, marginPercent: 10), [
        const PixelRect(498, 100, 4, 560),
        const PixelRect(100, 698, 800, 4),
        const PixelRect(498, 740, 4, 560),
      ]);
    });

    test('P=3%: 여백 30 안쪽 폭 940의 가로줄', () {
      // 칸 높이 658, 간격 688~712, 가운데 700
      expect(lines(1000, 1400, oneByTwo, 2, marginPercent: 3), [const PixelRect(30, 698, 940, 4)]);
    });

    group('P=0%: 간격이 정확히 두께이고 선이 그 자리를 채운다', () {
      test('N=2: 용지 폭 전체의 가로줄', () {
        // 간격 4, 칸 높이 (1400 − 4) ÷ 2 = 698, 간격 698~702
        expect(lines(1000, 1400, oneByTwo, 2, marginPercent: 0), [const PixelRect(0, 698, 1000, 4)]);
      });

      test('N=4: 가로줄과 줄마다 세로줄', () {
        // 칸 폭 (1000 − 4) ÷ 2 = 498, 간격 498~502. 줄은 0~698, 702~1400.
        expect(lines(1000, 1400, twoByTwo, 4, marginPercent: 0), [
          const PixelRect(498, 0, 4, 698),
          const PixelRect(0, 698, 1000, 4),
          const PixelRect(498, 702, 4, 698),
        ]);
      });

      test('칸 높이가 반 픽셀이어도 선과 칸 사이에 틈이 없다: A4 N=2', () {
        // 두께 7, 칸 높이 (3508 − 7) ÷ 2 = 1750.5. 위 칸은 0~1751, 아래 칸은 1758~3508. 선은 1751~1757.
        final line = lines(2480, 3508, oneByTwo, 2, thickness: 7, marginPercent: 0).single;
        final cells = cellRects(2480, 3508, oneByTwo, marginPercent: 0, minGap: 7);

        expect(line, const PixelRect(0, 1751, 2480, 7));
        expect(snapPx(cells.first.bottom), line.y);
        expect(snapPx(cells.last.top), line.y + line.height);
      });
    });
  });
}
