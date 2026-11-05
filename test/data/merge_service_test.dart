import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_merger/core/crop_rect.dart';
import 'package:image_merger/core/errors/merge_exception.dart';
import 'package:image_merger/features/image_merger/data/merge_service.dart';
import 'package:image_merger/features/image_merger/domain/layout_direction.dart';
import 'package:image_merger/features/image_merger/domain/output_format.dart';
import 'package:image_merger/features/image_merger/domain/output_settings.dart';
import 'package:image_merger/features/image_selection/domain/selected_image.dart';

import '../support/fake_native_bridge.dart';

const original = OutputSettings(paper: PaperSize.original);

SelectedImage image(String name, int w, int h, {String mime = 'image/jpeg', CropRect? crop}) => SelectedImage(
      path: '/picked/$name',
      thumbnailPath: '/thumbs/$name.jpg',
      displayName: name,
      width: w,
      height: h,
      bytes: 1000,
      mime: mime,
      crop: crop,
    );

/// 가짜 브리지가 그 파일의 모든 채널에 쓰는 값.
int fakeValue(String name) => '/picked/$name'.codeUnits.fold<int>(0, (a, b) => a + b) % 256;

(int, int, int) fakeColor(String name) => (fakeValue(name), fakeValue(name), fakeValue(name));

const white = (255, 255, 255);
const divider = (0xD0, 0xD0, 0xD0);

(int, int, int) rgb(img.Image image, int x, int y) {
  final p = image.getPixel(x, y);
  return (p.r.toInt(), p.g.toInt(), p.b.toInt());
}

/// PDF에는 구분선이 없다: 칠한 사각형도, 선이나 채우기도, 구분선 색도 없다.
/// pw.Image가 쓰는 `re W n`은 칠하지 않는 잘라내기 영역이다.
void expectNoDividers(String drawing) {
  expect(RegExp(r'\bre\b(?! W n)').hasMatch(drawing), isFalse, reason: '사각형이 없다');
  expect(RegExp(r'\b[lSsfF]\b').hasMatch(drawing), isFalse, reason: '선이나 채우기가 없다');
  expect(drawing.contains('0.8156'), isFalse, reason: '#D0D0D0 색을 쓰지 않는다');
}

/// PDF의 압축된 스트림을 풀어 이어 붙인 텍스트. 페이지 그리기 명령을 확인할 때 쓴다.
String inflatedStreams(List<int> pdf) {
  final buffer = StringBuffer();
  final text = latin1.decode(pdf);
  for (final m in RegExp(r'stream\r?\n').allMatches(text)) {
    final end = text.indexOf('endstream', m.end);
    if (end < 0) continue;
    try {
      buffer.writeln(latin1.decode(zlib.decode(pdf.sublist(m.end, end))));
    } on FormatException {
      // JPEG(DCTDecode) 스트림은 zlib이 아니다.
    }
  }
  return buffer.toString();
}

void main() {
  late Directory jobDir;
  late FakeNativeBridge bridge;
  late MergeService service;

  setUp(() async {
    jobDir = await Directory.systemTemp.createTemp('merge_service_test');
    bridge = FakeNativeBridge();
    service = MergeService(bridge: bridge);
  });
  tearDown(() async => jobDir.delete(recursive: true));

  test('PNG: 계획대로 한 장씩 디코딩해 합치고 진행률을 알린다', () async {
    final progress = <String>[];
    final result = await service.merge(
      images: [image('a.jpg', 90, 195), image('b.jpg', 90, 195), image('c.jpg', 60, 130)],
      format: OutputFormat.png,
      settings: original,
      jobDir: jobDir,
      token: CancelToken(),
      onProgress: (p) => progress.add(switch (p) {
        ProcessingImages(:final completed, :final total) => '$completed/$total',
        BuildingFile() => 'building',
      }),
    );

    expect(result.direction, LayoutDirection.horizontal);
    // 세로형 3장 → 가로 배치, 높이는 가장 낮은 130에 맞춤. 여백 130 × 5% = 6.5 → 7, 구분선 2.
    // 폭 (7 + 60 + 7) × 3 + 2 × 2 = 226, 높이 7 + 130 + 7 = 144
    expect((result.width, result.height), (226, 144));
    expect(bridge.decodeCalls.map((c) => (c.width, c.height, c.channels)).toList(),
        [(60, 130, 3), (60, 130, 3), (60, 130, 3)]);
    expect(progress, ['0/3', '1/3', '2/3', '3/3', 'building']);
    final decoded = img.decodePng(File(result.tempPath).readAsBytesSync())!;
    expect((decoded.width, decoded.height), (226, 144));
    expect(result.appliedScales[0], closeTo(60 / 90, 1e-9));
  });

  test('PNG·WebP가 하나라도 있으면 RGBA 캔버스', () async {
    await service.merge(
      images: [image('a.jpg', 100, 100), image('b.png', 100, 100, mime: 'image/png')],
      format: OutputFormat.png,
      settings: original,
      jobDir: jobDir,
      token: CancelToken(),
      onProgress: (_) {},
    );
    expect(bridge.decodeCalls.every((c) => c.channels == 4), isTrue);
  });

  test('네이티브 오류는 몇 번째 이미지인지 담아 MergeException으로', () async {
    bridge.failures['/picked/b.jpg'] = 'corrupt_file';
    await expectLater(
      service.merge(
        images: [image('a.jpg', 100, 100), image('b.jpg', 100, 100)],
        format: OutputFormat.png,
        settings: original,
        jobDir: jobDir,
        token: CancelToken(),
        onProgress: (_) {},
      ),
      throwsA(isA<MergeException>()
          .having((e) => e.code, 'code', MergeErrorCode.corruptFile)
          .having((e) => e.imageNumber, 'imageNumber', 2)),
    );
  });

  test('디코딩 중에 취소하면 다음 장으로 넘어가지 않고 MergeCancelled', () async {
    final token = CancelToken();
    bridge.onDecode = (path) {
      if (path.endsWith('b.jpg')) token.cancel();
    };
    await expectLater(
      service.merge(
        images: [image('a.jpg', 100, 100), image('b.jpg', 100, 100), image('c.jpg', 100, 100)],
        format: OutputFormat.png,
        settings: original,
        jobDir: jobDir,
        token: token,
        onProgress: (_) {},
      ),
      throwsA(isA<MergeCancelled>()),
    );
    expect(bridge.decodeCalls.length, 2);
  });

  test('PDF: 예산을 넘으면 품질 70 → 축소 순으로 다시 인코딩한다', () async {
    // 2장이면 페이지 예산 9,500,000. 품질 85는 넘고 품질 70 원본 크기는 넘는다고 흉내 → 첫 축소에서 통과
    bridge.reportedJpegBytes = (w, h, q) => (q == 85 || w == 400) ? 10000000 : 5000000;
    final result = await service.merge(
      images: [image('a.jpg', 400, 300), image('b.jpg', 400, 300)],
      format: OutputFormat.pdf,
      settings: original,
      jobDir: jobDir,
      token: CancelToken(),
      onProgress: (_) {},
    );

    final first = bridge.jpegCalls.where((c) => c.path.endsWith('a.jpg')).map((c) => '${c.width}x${c.height} q${c.quality}');
    expect(first.toList(), ['400x300 q85', '400x300 q70', '300x225 q70']);
    expect(result.appliedScales, [0.75, 0.75]);
    expect(result.direction, isNull);
    expect(File(result.tempPath).readAsBytesSync().take(4), '%PDF'.codeUnits);
  });

  test('PDF: 마지막 시도까지 예산을 넘으면 output_too_large', () async {
    bridge.reportedJpegBytes = (_, _, _) => 50000000;
    await expectLater(
      service.merge(
        images: [image('a.jpg', 400, 300), image('b.jpg', 400, 300)],
        format: OutputFormat.pdf,
        settings: original,
        jobDir: jobDir,
        token: CancelToken(),
        onProgress: (_) {},
      ),
      throwsA(isA<MergeException>()
          .having((e) => e.code, 'code', MergeErrorCode.outputTooLarge)
          .having((e) => e.imageNumber, 'imageNumber', 1)),
    );
    expect(bridge.jpegCalls.length, 5, reason: '처음 1회 + 다시 인코딩 4회');
  });

  group('출력 설정', () {
    Future<MergeResult> run(List<SelectedImage> images, OutputFormat format, OutputSettings settings) =>
        service.merge(
          images: images,
          format: format,
          settings: settings,
          jobDir: jobDir,
          token: CancelToken(),
          onProgress: (_) {},
        );

    test('PNG 기본 A4 세로: 용지 한 장에 이미지 하나, 페이지를 옆으로 잇고, 흰 여백, RGB', () async {
      final result = await run(
        [image('a.png', 1000, 500, mime: 'image/png'), image('b.png', 1000, 500, mime: 'image/png')],
        OutputFormat.png,
        const OutputSettings(),
      );

      // A4 세로라 이미지 비율과 상관없이 가로 배치. 2480 + 구분선 7 + 2480.
      // 여백 124 안쪽 폭 2232에 맞추면 높이는 1116이고, 위는 124 + (3260 − 1116) ÷ 2 = 1196이다.
      expect((result.width, result.height), (4967, 3508));
      expect(result.direction, LayoutDirection.horizontal);
      expect(bridge.decodeCalls.map((c) => (c.width, c.height, c.channels)).toList(),
          [(2232, 1116, 3), (2232, 1116, 3)]);
      final decoded = img.decodePng(File(result.tempPath).readAsBytesSync())!;
      expect(decoded.numChannels, 3);
      expect(rgb(decoded, 5, 5), white);
      expect(rgb(decoded, 5, 3500), white);
      expect(rgb(decoded, 1240, 1754), fakeColor('a.png'));
      expect(rgb(decoded, 123, 1754), white, reason: '왼쪽 여백 끝');
      expect(rgb(decoded, 124, 1754), fakeColor('a.png'), reason: '이미지 시작');
      expect(rgb(decoded, 2355, 1754), fakeColor('a.png'), reason: '이미지 끝');
      expect(rgb(decoded, 2356, 1754), white, reason: '오른쪽 여백 시작');
      // 이웃한 페이지는 여백·선·여백 순이다.
      expect(rgb(decoded, 2479, 1754), white);
      expect(rgb(decoded, 2483, 1754), divider);
      expect(rgb(decoded, 2487, 1754), white);
      expect(rgb(decoded, 2487 + 1240, 1754), fakeColor('b.png'));
    });

    test('용지 방향 가로는 페이지 가로·세로를 바꾸고 위아래로 잇는다', () async {
      final result = await run(
        [image('a.jpg', 1000, 500), image('b.jpg', 1000, 500)],
        OutputFormat.png,
        const OutputSettings(orientation: PaperOrientation.landscape),
      );

      expect((result.width, result.height), (3508, 4967));
      expect(result.direction, LayoutDirection.vertical);
      final decoded = img.decodePng(File(result.tempPath).readAsBytesSync())!;
      expect(rgb(decoded, 1754, 2483), divider, reason: '페이지 사이 구분선은 캔버스 폭 전체');
      expect(rgb(decoded, 0, 2483), divider);
      expect(rgb(decoded, 3507, 2483), divider);
    });

    test('PNG N=2: 실제 파일에서 구분선은 #D0D0D0이고 이미지 픽셀은 그대로다', () async {
      final result = await run(
        [image('a.jpg', 1000, 500), image('b.jpg', 1000, 500), image('c.jpg', 1000, 500)],
        OutputFormat.png,
        const OutputSettings(imagesPerPaper: 2),
      );

      // 페이지 2장. 여백 124, 칸 2232×1580.4, 이미지 2232×1116, 첫 칸 위 356, 둘째 칸 위 2036.
      // 칸 사이 가로줄은 1751~1757, 페이지 사이 세로줄은 2480~2486.
      expect((result.width, result.height), (4967, 3508));
      final decoded = img.decodePng(File(result.tempPath).readAsBytesSync())!;
      expect(rgb(decoded, 1240, 356 + 558), fakeColor('a.jpg'));
      expect(rgb(decoded, 1240, 2036 + 558), fakeColor('b.jpg'));
      expect(rgb(decoded, 2487 + 1240, 356 + 558), fakeColor('c.jpg'));

      // 칸 사이 가로줄: 여백 안쪽 폭 전체(124~2355), 7px
      expect(rgb(decoded, 124, 1751), divider);
      expect(rgb(decoded, 2355, 1757), divider);
      expect(rgb(decoded, 123, 1754), white, reason: '왼쪽 여백에는 줄이 없다');
      expect(rgb(decoded, 2356, 1754), white, reason: '오른쪽 여백에는 줄이 없다');
      expect(rgb(decoded, 1240, 1750), white, reason: '선 바로 위');
      expect(rgb(decoded, 1240, 1758), white, reason: '선 바로 아래');
      // 페이지 사이 세로줄: 캔버스 높이 전체, 7px
      expect(rgb(decoded, 2480, 0), divider);
      expect(rgb(decoded, 2486, 3507), divider);
      expect(rgb(decoded, 2479, 100), white);
      expect(rgb(decoded, 2487, 100), white);
      // 마지막 페이지의 빈 칸 쪽에는 칸 사이 선이 없다.
      expect(rgb(decoded, 2487 + 1240, 1754), white);
    });

    test('PNG N=4: 마지막 페이지의 빈 칸 쪽으로 세로줄을 긋지 않는다', () async {
      final result = await run(
        [for (var i = 0; i < 7; i++) image('$i.jpg', 1000, 1000)],
        OutputFormat.png,
        const OutputSettings(imagesPerPaper: 4),
      );

      // 페이지 2장. 칸 폭 1066.4, 세로줄 1237~1243. 첫 줄 124~1703, 둘째 줄 1804~3383.
      final decoded = img.decodePng(File(result.tempPath).readAsBytesSync())!;
      expect(rgb(decoded, 1240, 500), divider, reason: '첫 페이지 첫 줄');
      expect(rgb(decoded, 1240, 3000), divider, reason: '첫 페이지 둘째 줄');
      // 둘째 페이지(왼쪽 2487)에는 3장: 첫 줄은 꽉 차고 둘째 줄은 왼쪽 칸만 있다.
      expect(rgb(decoded, 2487 + 1240, 500), divider, reason: '양쪽 칸에 이미지가 있는 줄');
      expect(rgb(decoded, 2487 + 1240, 3000), white, reason: '오른쪽 칸이 비어 있는 줄');
      expect(rgb(decoded, 2487 + 1500, 1754), divider, reason: '아래 줄에 이미지가 있어 가로줄을 긋는다');
      expect(rgb(decoded, 2487 + 100, 1754), white, reason: '여백에는 긋지 않는다');
      expect(rgb(decoded, 1240, 100), white, reason: '세로줄도 위쪽 여백까지는 가지 않는다');
    });

    test('PNG 여백 10%: 페이지 네 변에 248px, 칸 사이 198px', () async {
      final result = await run(
        [image('a.jpg', 1000, 500), image('b.jpg', 1000, 500)],
        OutputFormat.png,
        const OutputSettings(imagesPerPaper: 2, marginPercent: 10),
      );

      // 이미지 1984×992. 칸 높이 1406.8, 첫 이미지 455~1446, 둘째 이미지 2061~3052.
      expect((result.width, result.height), (2480, 3508));
      expect(bridge.decodeCalls.first.width, 1984);
      expect(bridge.decodeCalls.first.height, 992);
      final decoded = img.decodePng(File(result.tempPath).readAsBytesSync())!;
      expect(rgb(decoded, 248, 456), fakeColor('a.jpg'));
      expect(rgb(decoded, 247, 456), white, reason: '왼쪽 여백');
      expect(rgb(decoded, 2231, 456), fakeColor('a.jpg'));
      expect(rgb(decoded, 2232, 456), white, reason: '오른쪽 여백');
      expect(rgb(decoded, 1240, 2061), fakeColor('b.jpg'));
      // 가로줄은 여백 안쪽 폭 전체다.
      expect(rgb(decoded, 248, 1754), divider);
      expect(rgb(decoded, 2231, 1754), divider);
      expect(rgb(decoded, 247, 1754), white);
      expect(rgb(decoded, 2232, 1754), white);
    });

    test('PNG 여백 0%: 흰 여백 없이 이미지가 구분선에 맞닿는다', () async {
      final result = await run(
        [image('a.jpg', 1000, 2000), image('b.jpg', 1000, 2000)],
        OutputFormat.png,
        const OutputSettings(imagesPerPaper: 2, marginPercent: 0),
      );

      // 칸 높이 1750.5. 가로줄 1751~1757. 위 이미지는 0~1750, 아래 이미지는 1758~3507.
      final decoded = img.decodePng(File(result.tempPath).readAsBytesSync())!;
      expect(rgb(decoded, 1240, 0), fakeColor('a.jpg'), reason: '위쪽 여백이 없다');
      expect(rgb(decoded, 1240, 1750), fakeColor('a.jpg'), reason: '선 바로 위');
      expect(rgb(decoded, 1240, 1751), divider);
      expect(rgb(decoded, 1240, 1757), divider);
      expect(rgb(decoded, 1240, 1758), fakeColor('b.jpg'), reason: '선 바로 아래');
      expect(rgb(decoded, 1240, 3507), fakeColor('b.jpg'), reason: '아래쪽 여백이 없다');
      expect(rgb(decoded, 0, 1754), divider, reason: '용지 폭 전체');
      expect(rgb(decoded, 2479, 1754), divider);
    });

    test('PNG 여백 0%, 페이지 사이와 원본 크기: 선만 있다', () async {
      final paged = await run(
        [image('a.jpg', 2480, 3508), image('b.jpg', 2480, 3508)],
        OutputFormat.png,
        const OutputSettings(marginPercent: 0),
      );
      final pagedImage = img.decodePng(File(paged.tempPath).readAsBytesSync())!;
      expect(rgb(pagedImage, 2479, 100), fakeColor('a.jpg'));
      expect(rgb(pagedImage, 2480, 100), divider);
      expect(rgb(pagedImage, 2486, 100), divider);
      expect(rgb(pagedImage, 2487, 100), fakeColor('b.jpg'));

      final original = await run(
        [image('c.jpg', 100, 200), image('d.jpg', 100, 200)],
        OutputFormat.png,
        const OutputSettings(paper: PaperSize.original, marginPercent: 0),
      );
      // [이미지 100][선 2][이미지 100]
      expect((original.width, original.height), (202, 200));
      final originalImage = img.decodePng(File(original.tempPath).readAsBytesSync())!;
      expect(rgb(originalImage, 99, 0), fakeColor('c.jpg'));
      expect(rgb(originalImage, 100, 0), divider);
      expect(rgb(originalImage, 101, 199), divider);
      expect(rgb(originalImage, 102, 0), fakeColor('d.jpg'));
    });

    test('PNG 이미지 크기 50%: 이미지 둘레에 흰색이 남는다', () async {
      final result = await run(
        [image('a.jpg', 1000, 500), image('b.jpg', 1000, 500)],
        OutputFormat.png,
        const OutputSettings(imageSizePercent: 50),
      );

      // 맞춤 2232×1116의 절반 1116×558을 칸 가운데에: 왼쪽 682, 위 1475
      expect(bridge.decodeCalls.first.width, 1116);
      expect(bridge.decodeCalls.first.height, 558);
      final decoded = img.decodePng(File(result.tempPath).readAsBytesSync())!;
      expect(rgb(decoded, 682, 1475), fakeColor('a.jpg'));
      expect(rgb(decoded, 1797, 2032), fakeColor('a.jpg'));
      expect(rgb(decoded, 681, 1475), white, reason: '왼쪽');
      expect(rgb(decoded, 1798, 2032), white, reason: '오른쪽');
      expect(rgb(decoded, 682, 1474), white, reason: '위');
      expect(rgb(decoded, 1797, 2033), white, reason: '아래');
    });

    test('PNG 원본 크기: 여백과 구분선은 불투명하고 이미지의 채널은 그대로다 (RGBA)', () async {
      final result = await run(
        [image('a.png', 100, 200, mime: 'image/png'), image('b.png', 100, 200, mime: 'image/png')],
        OutputFormat.png,
        original,
      );

      // 공통 변 200. 여백 10, 두께는 최소 2px. 10 + 100 + 10 + 2 + 10 + 100 + 10 = 242, 높이 220
      expect((result.width, result.height), (242, 220));
      final decoded = img.decodePng(File(result.tempPath).readAsBytesSync())!;
      expect(decoded.numChannels, 4);
      final line = decoded.getPixel(120, 50);
      expect([line.r, line.g, line.b, line.a], [0xD0, 0xD0, 0xD0, 255]);
      final lineEnd = decoded.getPixel(121, 219);
      expect([lineEnd.r, lineEnd.g, lineEnd.b, lineEnd.a], [0xD0, 0xD0, 0xD0, 255], reason: '캔버스 전체 길이');
      // 가짜 브리지는 모든 채널을 같은 값으로 쓴다. 알파도 그대로여야 한다.
      final a = fakeValue('a.png');
      final pixel = decoded.getPixel(50, 50);
      expect([pixel.r, pixel.g, pixel.b, pixel.a], [a, a, a, a]);
      // 여백은 불투명한 흰색이다: 네 변과 선의 양쪽
      for (final (x, y) in const [(5, 50), (50, 5), (50, 214), (115, 50), (125, 50), (236, 50)]) {
        final padding = decoded.getPixel(x, y);
        expect([padding.r, padding.g, padding.b, padding.a], [255, 255, 255, 255], reason: '$x,$y');
      }
    });

    test('PNG 흑백: 구분선 색은 같다', () async {
      final result = await run(
        [image('a.jpg', 100, 200), image('b.jpg', 100, 200)],
        OutputFormat.png,
        const OutputSettings(paper: PaperSize.original, grayscale: true),
      );

      final decoded = img.decodePng(File(result.tempPath).readAsBytesSync())!;
      expect(rgb(decoded, 120, 50), divider);
    });

    test('PDF N=2: 페이지 수가 줄고 이미지는 여백 안쪽 칸에 들어가며 구분선이 없다', () async {
      final result = await run(
        [image('a.jpg', 1000, 500), image('b.jpg', 1000, 500), image('c.jpg', 1000, 500)],
        OutputFormat.pdf,
        const OutputSettings(imagesPerPaper: 2),
      );

      expect(bridge.jpegCalls, hasLength(3));
      final bytes = File(result.tempPath).readAsBytesSync();
      final text = latin1.decode(bytes);
      expect(RegExp(r'/Type\s*/Page(?!s)').allMatches(text).length, 2, reason: '3장 ÷ 2 → 2페이지');
      expect(RegExp(r'/MediaBox\s*\[\s*0\s+0\s+595\.27').allMatches(text).length, 2);

      final drawing = inflatedStreams(bytes);
      expect(RegExp(r'/I\d+ Do').allMatches(drawing).length, 3, reason: '이미지 3장을 그린다');
      expectNoDividers(drawing);
      // 여백 29.76, 간격 23.81, 칸 535.75×379.28, 이미지 535.75×267.87.
      expect(drawing, matches(RegExp(r'535\.74\d* 0 0 267\.87\d* 0 0 cm')));
      // 첫 칸 위 85.46 → 아래 841.89 − 85.46 − 267.87 = 488.55
      expect(drawing, matches(RegExp(r'1 0 0 1 29\.76\d* 488\.55\d* cm')));
      // 둘째 칸 위 488.55 → 아래 841.89 − 488.55 − 267.87 = 85.46
      expect(drawing, matches(RegExp(r'1 0 0 1 29\.76\d* 85\.46\d* cm')));
    });

    test('PDF 기본 설정: 페이지 네 변에 여백이 있고 구분선은 없다', () async {
      final result = await run(
        [image('a.jpg', 1000, 500), image('b.jpg', 1000, 500)],
        OutputFormat.pdf,
        const OutputSettings(),
      );

      final bytes = File(result.tempPath).readAsBytesSync();
      final drawing = inflatedStreams(bytes);
      expectNoDividers(drawing);
      // 여백 29.76, 이미지 535.75×267.87, 위 287.01 → 아래 841.89 − 287.01 − 267.87 = 287.01
      expect(drawing, matches(RegExp(r'1 0 0 1 29\.76\d* 287\.00\d* cm')));
      expect(drawing, matches(RegExp(r'535\.74\d* 0 0 267\.87\d* 0 0 cm')));
    });

    test('PDF 이미지 크기 50%: 이미지가 작아지고 둘레는 비어 있다', () async {
      final result = await run(
        [image('a.jpg', 1000, 500), image('b.jpg', 1000, 500)],
        OutputFormat.pdf,
        const OutputSettings(imageSizePercent: 50),
      );

      final drawing = inflatedStreams(File(result.tempPath).readAsBytesSync());
      expectNoDividers(drawing);
      // 폭 267.87, 높이 133.94. 왼쪽 163.70, 아래 353.98
      expect(drawing, matches(RegExp(r'1 0 0 1 163\.70\d* 353\.97\d* cm')));
      expect(drawing, matches(RegExp(r'267\.87\d* 0 0 133\.93\d* 0 0 cm')));
    });

    test('PDF 여백 10%: 여백 59.53, 간격 47.62', () async {
      final result = await run(
        [image('a.jpg', 1000, 500), image('b.jpg', 1000, 500)],
        OutputFormat.pdf,
        const OutputSettings(imagesPerPaper: 2, marginPercent: 10),
      );

      final drawing = inflatedStreams(File(result.tempPath).readAsBytesSync());
      expectNoDividers(drawing);
      // 이미지 476.22×238.11. 첫 칸 위 109.28 → 아래 494.50. 둘째 칸 위 494.50 → 아래 109.28
      expect(drawing, matches(RegExp(r'476\.22\d* 0 0 238\.11\d* 0 0 cm')));
      expect(drawing, matches(RegExp(r'1 0 0 1 59\.52\d* 494\.50\d* cm')));
      expect(drawing, matches(RegExp(r'1 0 0 1 59\.52\d* 109\.27\d* cm')));
    });

    test('PDF 여백 0%: 칸이 맞닿는다', () async {
      final result = await run(
        [image('a.jpg', 1000, 2000), image('b.jpg', 1000, 2000)],
        OutputFormat.pdf,
        const OutputSettings(imagesPerPaper: 2, marginPercent: 0),
      );

      final drawing = inflatedStreams(File(result.tempPath).readAsBytesSync());
      expectNoDividers(drawing);
      // 칸 높이 420.94. 이미지 210.47×420.94, 왼쪽 192.40. 위 칸은 아래 420.94, 아래 칸은 아래 0.
      expect(drawing, matches(RegExp(r'1 0 0 1 192\.40\d* 420\.94\d* cm')));
      expect(drawing, matches(RegExp(r'1 0 0 1 192\.40\d* 0 cm')));
    });

    test('PDF 예산은 페이지가 아니라 이미지 장수로 나눈다', () async {
      // 4장이면 페이지는 2장이어도 예산은 19,000,000 ÷ 4 = 4,750,000이다.
      // 품질 85가 5,000,000이면 페이지 기준(9,500,000)으로는 통과하지만 장수 기준으로는 다시 인코딩한다.
      bridge.reportedJpegBytes = (_, _, q) => q == 85 ? 5000000 : 4000000;
      await run(
        [for (var i = 0; i < 4; i++) image('$i.jpg', 400, 300)],
        OutputFormat.pdf,
        const OutputSettings(imagesPerPaper: 2),
      );

      final first = bridge.jpegCalls.where((c) => c.path.endsWith('0.jpg'));
      expect(first.map((c) => c.quality).toList(), [85, 70]);
    });

    test('PDF 원본 크기: 항목 하나당 한 페이지, 그 이미지의 짧은 변 5% 여백, 구분선 없음', () async {
      final result = await run(
        [image('a.jpg', 1000, 2000), image('b.jpg', 2000, 1000)],
        OutputFormat.pdf,
        const OutputSettings(paper: PaperSize.original, imagesPerPaper: 4),
      );

      final bytes = File(result.tempPath).readAsBytesSync();
      final text = latin1.decode(bytes);
      expect(RegExp(r'/Type\s*/Page(?!s)').allMatches(text).length, 2);
      // 1000×2000: 여백 50, 내용 1100×2100, 페이지 440.99×841.89, 이미지 400.90×801.80, 위치 20.05
      expect(text, matches(RegExp(r'/MediaBox\s*\[\s*0\s+0\s+440\.98\d*\s+841\.88')));
      expect(text, matches(RegExp(r'/MediaBox\s*\[\s*0\s+0\s+841\.88\d*\s+440\.98')));
      final drawing = inflatedStreams(bytes);
      expectNoDividers(drawing);
      expect(drawing, matches(RegExp(r'1 0 0 1 20\.04\d* 20\.04\d* cm')));
      expect(drawing, matches(RegExp(r'400\.89\d* 0 0 801\.79\d* 0 0 cm')));
      expect(drawing, matches(RegExp(r'801\.79\d* 0 0 400\.89\d* 0 0 cm')));
    });

    test('PDF 원본 크기, 여백 0%: 페이지 비율이 이미지 비율과 같다', () async {
      final result = await run(
        [image('a.jpg', 1000, 2000), image('b.jpg', 1000, 2000)],
        OutputFormat.pdf,
        const OutputSettings(paper: PaperSize.original, marginPercent: 0),
      );

      final bytes = File(result.tempPath).readAsBytesSync();
      expect(latin1.decode(bytes), matches(RegExp(r'/MediaBox\s*\[\s*0\s+0\s+420\.94\d*\s+841\.88')));
      final drawing = inflatedStreams(bytes);
      expect(drawing, matches(RegExp(r'420\.94\d* 0 0 841\.88\d* 0 0 cm')));
      expectNoDividers(drawing);
    });

    test('영역 편집과 흑백을 디코딩에 넘기고, 계산은 자른 크기로 한다', () async {
      const crop = CropRect(0, 0, 0.5, 1);
      final result = await run(
        // 1000×500을 절반 자르면 500×500. 다른 한 장은 500×500이라 기하 평균 1 → 세로 배치.
      // 공통 변 500. 여백 25, 구분선 2. 폭 550, 높이 (25 + 500 + 25) × 2 + 2 = 1102
        [image('a.jpg', 1000, 500, crop: crop), image('b.jpg', 500, 500)],
        OutputFormat.png,
        const OutputSettings(paper: PaperSize.original, grayscale: true),
      );

      expect(result.direction, LayoutDirection.vertical);
      expect((result.width, result.height), (550, 1102));
      expect(bridge.decodeCalls[0].crop, crop);
      expect(bridge.decodeCalls[1].crop, isNull);
      expect(bridge.decodeCalls.every((c) => c.grayscale), isTrue);
    });

    test('PDF: 영역 편집과 흑백을 JPEG 인코딩에 넘기고 용지 페이지로 만든다', () async {
      const crop = CropRect(0.5, 0, 1, 1);
      final result = await run(
        [image('a.jpg', 1000, 500, crop: crop), image('b.jpg', 400, 600)],
        OutputFormat.pdf,
        const OutputSettings(grayscale: true),
      );

      expect(bridge.jpegCalls[0].crop, crop);
      expect((bridge.jpegCalls[0].width, bridge.jpegCalls[0].height), (500, 500));
      expect(bridge.jpegCalls.every((c) => c.grayscale), isTrue);
      final text = latin1.decode(File(result.tempPath).readAsBytesSync());
      expect(RegExp(r'/MediaBox\s*\[\s*0\s+0\s+595\.27').allMatches(text).length, 2,
          reason: 'A4 세로 폭 595.28pt 페이지 2장');
    });
  });
}
