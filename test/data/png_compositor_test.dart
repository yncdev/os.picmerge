import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_merger/core/errors/merge_exception.dart';
import 'package:image_merger/features/image_merger/data/png_compositor.dart';
import 'package:image_merger/features/image_merger/domain/page_layout.dart';

Uint8List solid(int w, int h, List<int> pixel) {
  final out = Uint8List(w * h * pixel.length);
  for (var i = 0; i < out.length; i += pixel.length) {
    out.setRange(i, i + pixel.length, pixel);
  }
  return out;
}

void main() {
  group('PngCompositor', () {
    test('raw 픽셀을 자리에 복사하고 PNG로 인코딩한다 (RGB)', () {
      final c = PngCompositor(width: 4, height: 3, channels: 3)
        ..blit(solid(4, 1, [255, 0, 0]), x: 0, y: 0, width: 4, height: 1)
        ..blit(solid(4, 2, [0, 0, 255]), x: 0, y: 1, width: 4, height: 2);
      final result = c.encode();

      final decoded = img.decodePng(result.bytes)!;
      expect(decoded.width, 4);
      expect(decoded.height, 3);
      expect(decoded.numChannels, 3);
      final top = decoded.getPixel(2, 0);
      final bottom = decoded.getPixel(2, 2);
      expect([top.r, top.g, top.b], [255, 0, 0]);
      expect([bottom.r, bottom.g, bottom.b], [0, 0, 255]);
      expect(result.scale, 1.0);
    });

    test('캔버스는 4채널이어도 불투명한 흰색에서 시작하고, 이미지의 투명 픽셀은 그대로다', () {
      final c = PngCompositor(width: 3, height: 1, channels: 4)
        ..blit(solid(1, 1, [10, 20, 30, 0]), x: 0, y: 0, width: 1, height: 1)
        ..blit(solid(1, 1, [10, 20, 30, 128]), x: 1, y: 0, width: 1, height: 1);
      final decoded = img.decodePng(c.encode().bytes)!;
      expect(decoded.getPixel(0, 0).a, 0);
      expect(decoded.getPixel(1, 0).a, 128);
      expect(decoded.getPixel(1, 0).r, 10);
      final untouched = decoded.getPixel(2, 0);
      expect([untouched.r, untouched.g, untouched.b, untouched.a], [255, 255, 255, 255]);
    });

    test('3채널 캔버스도 흰색에서 시작한다', () {
      final decoded = img.decodePng(PngCompositor(width: 2, height: 2, channels: 3).encode().bytes)!;
      final pixel = decoded.getPixel(1, 1);
      expect([pixel.r, pixel.g, pixel.b], [255, 255, 255]);
    });

    test('구분선은 #D0D0D0으로 칠하고 주변은 건드리지 않는다 (RGB)', () {
      final c = PngCompositor(width: 6, height: 4, channels: 3)
        ..drawDividers(const [PixelRect(2, 0, 2, 4)]);

      final decoded = img.decodePng(c.encode().bytes)!;
      final line = decoded.getPixel(3, 2);
      expect([line.r, line.g, line.b], [0xD0, 0xD0, 0xD0]);
      final left = decoded.getPixel(1, 2);
      expect([left.r, left.g, left.b], [255, 255, 255]);
      final right = decoded.getPixel(4, 2);
      expect([right.r, right.g, right.b], [255, 255, 255]);
    });

    test('4채널 캔버스의 구분선은 불투명이고, 이미지의 투명도는 그대로다', () {
      final c = PngCompositor(width: 5, height: 1, channels: 4)
        ..blit(solid(2, 1, [10, 20, 30, 0]), x: 0, y: 0, width: 2, height: 1)
        ..drawDividers(const [PixelRect(2, 0, 1, 1)])
        ..blit(solid(2, 1, [10, 20, 30, 128]), x: 3, y: 0, width: 2, height: 1);

      final decoded = img.decodePng(c.encode().bytes)!;
      expect(decoded.numChannels, 4);
      final line = decoded.getPixel(2, 0);
      expect([line.r, line.g, line.b, line.a], [0xD0, 0xD0, 0xD0, 255]);
      expect(decoded.getPixel(1, 0).a, 0);
      expect(decoded.getPixel(3, 0).a, 128);
    });

    test('캔버스 밖의 구분선은 오류', () {
      final c = PngCompositor(width: 4, height: 4, channels: 3);
      expect(() => c.drawDividers(const [PixelRect(3, 0, 2, 1)]), throwsArgumentError);
    });

    test('raw 파일을 행 단위로 바로 캔버스에 읽어 들인다', () async {
      final dir = await Directory.systemTemp.createTemp('png_compositor_test');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/a.raw')..writeAsBytesSync(solid(2, 3, [7, 8, 9]));
      final c = PngCompositor(width: 5, height: 4, channels: 3)
        ..blitFile(file, x: 3, y: 1, width: 2, height: 3);

      final decoded = img.decodePng(c.encode().bytes)!;
      final inside = decoded.getPixel(4, 3);
      expect([inside.r, inside.g, inside.b], [7, 8, 9]);
      expect(decoded.getPixel(2, 1).r, 255, reason: '자리 밖은 흰색 그대로');
      expect(decoded.getPixel(3, 0).r, 255);
    });

    test('raw 크기가 자리와 다르면 corrupt_file', () {
      final c = PngCompositor(width: 4, height: 4, channels: 3);
      expect(
        () => c.blit(Uint8List(10), x: 0, y: 0, width: 2, height: 2),
        throwsA(isA<MergeException>().having((e) => e.code, 'code', MergeErrorCode.corruptFile)),
      );
    });

    test('상한을 넘으면 줄여서 다시 인코딩한다', () {
      // 압축이 거의 안 되는 노이즈 300×300 RGB ≈ 270KB
      final random = math.Random(1);
      final noise = Uint8List.fromList(List.generate(300 * 300 * 3, (_) => random.nextInt(256)));
      final c = PngCompositor(width: 300, height: 300, channels: 3)
        ..blit(noise, x: 0, y: 0, width: 300, height: 300);
      final result = c.encode(maxBytes: 100000);

      expect(result.bytes.length, lessThanOrEqualTo(100000));
      expect(result.width, lessThan(300));
      expect(result.scale, closeTo(result.width / 300, 1e-9));
      final decoded = img.decodePng(result.bytes)!;
      expect(decoded.width, result.width);
    });

    group('줄여서 다시 인코딩해도 구분선은 흐려지지 않는다', () {
      const white = 255;

      /// [size]×[size] 캔버스. 왼쪽 절반은 압축되지 않는 노이즈이고 오른쪽 절반은 흰색이다.
      /// 노이즈 덕분에 파일이 커져 줄여서 다시 인코딩하게 되고, 흰 쪽에서 선 둘레의 색을 그대로 볼 수 있다.
      PngCompositor halfNoise(int channels, List<PixelRect> dividers, {int size = 600}) {
        final random = math.Random(5);
        final raw = Uint8List(size * size * channels)..fillRange(0, size * size * channels, white);
        for (var y = 0; y < size; y++) {
          for (var x = 0; x < size ~/ 2; x++) {
            final i = (y * size + x) * channels;
            raw[i] = random.nextInt(256);
            raw[i + 1] = random.nextInt(256);
            raw[i + 2] = random.nextInt(256);
          }
        }
        return PngCompositor(width: size, height: size, channels: channels)
          ..blit(raw, x: 0, y: 0, width: size, height: size)
          ..drawDividers(dividers);
      }

      /// 흰 쪽의 세로줄 하나를 따라 위에서 아래로 읽은, 흰색이 아닌 값들.
      List<int> nonWhiteDown(img.Image image, int x) => [
            for (var y = 0; y < image.height; y++)
              if (image.getPixel(x, y).r != white) image.getPixel(x, y).r.toInt(),
          ];

      /// 흰 쪽의 가로줄 하나를 따라 읽은, 흰색이 아닌 값들. 노이즈 쪽은 보지 않는다.
      List<int> nonWhiteAcross(img.Image image, int y) => [
            for (var x = image.width ~/ 2 + 2; x < image.width; x++)
              if (image.getPixel(x, y).r != white) image.getPixel(x, y).r.toInt(),
          ];

      test('두꺼운 가로줄 둘레에 중간 색이 남지 않는다', () {
        final c = halfNoise(3, const [PixelRect(0, 200, 600, 7)]);
        final result = c.encode(maxBytes: 300000);
        expect(result.width, lessThan(600), reason: '실제로 줄어야 시험이 된다');

        final decoded = img.decodePng(result.bytes)!;
        final line = nonWhiteDown(decoded, decoded.width * 3 ~/ 4);
        expect(line, everyElement(0xD0), reason: '선과 흰색만 있고 그 사이 색은 없다: $line');
        expect(line.length, greaterThanOrEqualTo(3), reason: '7 × 약 0.5');
      });

      test('두꺼운 세로줄 둘레에 중간 색이 남지 않는다', () {
        final c = halfNoise(3, const [PixelRect(450, 0, 7, 600)]);
        final result = c.encode(maxBytes: 300000);
        expect(result.width, lessThan(600));

        final decoded = img.decodePng(result.bytes)!;
        final line = nonWhiteAcross(decoded, decoded.height ~/ 2);
        expect(line, everyElement(0xD0), reason: '$line');
        expect(line.length, greaterThanOrEqualTo(3));
      });

      test('2px 선은 2px 아래로 줄지 않고 끊기지 않는다', () {
        final c = halfNoise(3, const [PixelRect(450, 0, 2, 600), PixelRect(0, 100, 600, 2)]);
        final result = c.encode(maxBytes: 300000);
        expect(result.width, lessThan(600));

        final decoded = img.decodePng(result.bytes)!;
        final across = nonWhiteAcross(decoded, decoded.height ~/ 2);
        expect(across, everyElement(0xD0), reason: '$across');
        expect(across.length, greaterThanOrEqualTo(2));
        // 세로줄은 위에서 아래까지 이어진다. 가로줄과 만나는 곳을 포함해 모두 선 색이다.
        final firstX = [
          for (var x = decoded.width ~/ 2 + 2; x < decoded.width; x++)
            if (decoded.getPixel(x, decoded.height ~/ 2).r != white) x,
        ].first;
        for (var y = 0; y < decoded.height; y++) {
          expect(decoded.getPixel(firstX, y).r, 0xD0, reason: 'y=$y');
        }
      });

      test('4채널에서도 선은 불투명이다', () {
        final c = halfNoise(4, const [PixelRect(450, 0, 2, 600)]);
        final result = c.encode(maxBytes: 300000);
        expect(result.width, lessThan(600));

        final decoded = img.decodePng(result.bytes)!;
        final y = decoded.height ~/ 2;
        final x = [
          for (var x = decoded.width ~/ 2 + 2; x < decoded.width; x++)
            if (decoded.getPixel(x, y).r != white) x,
        ].first;
        final p = decoded.getPixel(x, y);
        expect([p.r, p.g, p.b, p.a], [0xD0, 0xD0, 0xD0, 255]);
      });

      test('줄일 일이 없으면 그대로다', () {
        final c = halfNoise(3, const [PixelRect(450, 0, 2, 600)], size: 600);
        final decoded = img.decodePng(c.encode().bytes)!;

        expect(decoded.width, 600);
        expect(nonWhiteAcross(decoded, 300), [0xD0, 0xD0]);
      });
    });

    group('4채널 축소는 알파를 곱해 평균한다', () {
      /// 왼쪽 위는 노이즈(불투명)로 파일을 키우고, 나머지는 [pixel]을 그린다.
      /// 흰색과 완전 투명이 맞닿은 경계가 칸 안에 들어오도록 오른쪽을 두 픽셀마다 번갈아 칠한다.
      Uint8List canvas(int size) {
        final random = math.Random(6);
        final raw = Uint8List(size * size * 4);
        for (var y = 0; y < size; y++) {
          for (var x = 0; x < size; x++) {
            final i = (y * size + x) * 4;
            if (x < size ~/ 2) {
              raw[i] = random.nextInt(256);
              raw[i + 1] = random.nextInt(256);
              raw[i + 2] = random.nextInt(256);
              raw[i + 3] = 255;
            } else if (x % 2 == 0) {
              raw.fillRange(i, i + 4, 255); // 불투명한 흰색
            }
            // 나머지는 0,0,0,0: 완전 투명
          }
        }
        return raw;
      }

      test('흰색과 투명이 섞인 칸은 어두워지지 않고 흰색에 알파만 낮아진다', () {
        const size = 600;
        final c = PngCompositor(width: size, height: size, channels: 4)
          ..blit(canvas(size), x: 0, y: 0, width: size, height: size);
        final result = c.encode(maxBytes: 400000);
        expect(result.width, lessThan(size), reason: '실제로 줄어야 시험이 된다');

        final decoded = img.decodePng(result.bytes)!;
        var partial = 0;
        for (var y = 0; y < decoded.height; y += 7) {
          for (var x = decoded.width ~/ 2 + 2; x < decoded.width; x++) {
            final p = decoded.getPixel(x, y);
            if (p.a == 0) {
              expect([p.r, p.g, p.b], [0, 0, 0], reason: '완전 투명은 그대로');
            } else {
              // 곱하지 않고 평균하면 127,127,127,127처럼 어두워진다.
              expect([p.r, p.g, p.b], [255, 255, 255], reason: 'x=$x y=$y a=${p.a}');
              if (p.a < 255) partial++;
            }
          }
        }
        expect(partial, greaterThan(0), reason: '섞인 칸이 있어야 시험이 된다');
      });

      test('섞인 칸의 알파는 면적 비율이다', () {
        // 모두 불투명·반투명으로 된 작은 경우를 손으로 계산한다.
        // 왼쪽 위 2×2 칸: 흰색 불투명 2개와 투명 2개 → 흰색, 알파 (255 + 255) ÷ 4 = 127.5 → 128
        // 그 오른쪽 2×2 칸: 빨강 알파 128 2개와 투명 2개 → 빨강 그대로, 알파 64
        final raw = Uint8List.fromList([
          255, 255, 255, 255, 0, 0, 0, 0, 255, 0, 0, 128, 0, 0, 0, 0, //
          0, 0, 0, 0, 255, 255, 255, 255, 0, 0, 0, 0, 255, 0, 0, 128, //
        ]);
        final c = PngCompositor(width: 4, height: 2, channels: 4)..blit(raw, x: 0, y: 0, width: 4, height: 2);

        final shrunk = c.shrink(2, 1);

        final first = shrunk.getPixel(0, 0);
        expect([first.r, first.g, first.b, first.a], [255, 255, 255, 128]);
        final second = shrunk.getPixel(1, 0);
        expect([second.r, second.g, second.b, second.a], [255, 0, 0, 64]);
      });

      test('불투명하면 보통 평균과 같고, 알파 0은 그대로다', () {
        // 왼쪽 칸: 불투명한 100, 200 → 150. 오른쪽 칸: 모두 투명 → 0,0,0,0
        final raw = Uint8List.fromList([
          100, 100, 100, 255, 200, 200, 200, 255, 9, 9, 9, 0, 8, 8, 8, 0, //
        ]);
        final c = PngCompositor(width: 4, height: 1, channels: 4)..blit(raw, x: 0, y: 0, width: 4, height: 1);

        final shrunk = c.shrink(2, 1);

        final first = shrunk.getPixel(0, 0);
        expect([first.r, first.g, first.b, first.a], [150, 150, 150, 255]);
        final second = shrunk.getPixel(1, 0);
        expect([second.r, second.g, second.b, second.a], [0, 0, 0, 0]);
      });

      test('3채널은 채널마다 평균한다', () {
        // 10, 21 → 15.5 → 16 (반올림)
        final raw = Uint8List.fromList([10, 20, 30, 21, 40, 60]);
        final c = PngCompositor(width: 2, height: 1, channels: 3)..blit(raw, x: 0, y: 0, width: 2, height: 1);

        final shrunk = c.shrink(1, 1);

        final p = shrunk.getPixel(0, 0);
        expect([p.r, p.g, p.b], [16, 30, 45]);
      });
    });

    test('다시 인코딩 2회 후에도 넘으면 output_too_large', () {
      final random = math.Random(2);
      final noise = Uint8List.fromList(List.generate(200 * 200 * 3, (_) => random.nextInt(256)));
      final c = PngCompositor(width: 200, height: 200, channels: 3)
        ..blit(noise, x: 0, y: 0, width: 200, height: 200);
      expect(
        () => c.encode(maxBytes: 100),
        throwsA(isA<MergeException>().having((e) => e.code, 'code', MergeErrorCode.outputTooLarge)),
      );
    });
  });
}
