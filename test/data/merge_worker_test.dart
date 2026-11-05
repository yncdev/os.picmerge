import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_merger/core/errors/merge_exception.dart';
import 'package:image_merger/features/image_merger/data/merge_worker.dart';
import 'package:image_merger/features/image_merger/domain/page_layout.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory dir;

  setUp(() async => dir = await Directory.systemTemp.createTemp('merge_worker_test'));
  tearDown(() async => dir.delete(recursive: true));

  File writeRaw(String name, int w, int h, List<int> pixel) {
    final bytes = Uint8List(w * h * pixel.length);
    for (var i = 0; i < bytes.length; i += pixel.length) {
      bytes.setRange(i, i + pixel.length, pixel);
    }
    return File(p.join(dir.path, name))..writeAsBytesSync(bytes);
  }

  test('raw 파일을 캔버스에 합쳐 PNG를 쓰고, raw 파일은 지운다', () async {
    final worker = await MergeWorker.spawn();
    final a = writeRaw('a.raw', 3, 2, [255, 0, 0]);
    final b = writeRaw('b.raw', 2, 2, [0, 255, 0]);

    await worker.startPng(width: 5, height: 2, channels: 3);
    await worker.addRaw(rawPath: a.path, x: 0, y: 0, width: 3, height: 2);
    await worker.addRaw(rawPath: b.path, x: 3, y: 0, width: 2, height: 2);
    final out = p.join(dir.path, 'out.png');
    final result = await worker.finishPng(outPath: out, maxBytes: 1000000);
    worker.close();

    expect(a.existsSync(), isFalse);
    expect(b.existsSync(), isFalse);
    expect(result.width, 5);
    expect(result.bytes, File(out).lengthSync());
    final decoded = img.decodePng(File(out).readAsBytesSync())!;
    expect(decoded.getPixel(1, 1).r, 255);
    expect(decoded.getPixel(4, 1).g, 255);
  });

  test('캔버스는 이미지가 닿지 않는 곳이 흰색이다', () async {
    final worker = await MergeWorker.spawn();
    final a = writeRaw('a.raw', 2, 2, [255, 0, 0]);

    await worker.startPng(width: 4, height: 2, channels: 3);
    await worker.addRaw(rawPath: a.path, x: 1, y: 0, width: 2, height: 2);
    final out = p.join(dir.path, 'out.png');
    await worker.finishPng(outPath: out, maxBytes: 1000000);
    worker.close();

    final decoded = img.decodePng(File(out).readAsBytesSync())!;
    expect(decoded.getPixel(0, 0).g, 255, reason: '왼쪽 여백은 흰색');
    expect(decoded.getPixel(1, 0).g, 0, reason: '이미지 자리');
    expect(decoded.getPixel(3, 1).b, 255, reason: '오른쪽 여백은 흰색');
  });

  test('구분선을 칠한다. 4채널이어도 불투명이다', () async {
    final worker = await MergeWorker.spawn();
    await worker.startPng(width: 4, height: 2, channels: 4);
    await worker.drawDividers(const [PixelRect(1, 0, 2, 2)]);
    final out = p.join(dir.path, 'out.png');
    await worker.finishPng(outPath: out, maxBytes: 1000000);
    worker.close();

    final decoded = img.decodePng(File(out).readAsBytesSync())!;
    final line = decoded.getPixel(1, 1);
    expect([line.r, line.g, line.b, line.a], [0xD0, 0xD0, 0xD0, 255]);
    final outside = decoded.getPixel(0, 1);
    expect([outside.r, outside.g, outside.b, outside.a], [255, 255, 255, 255], reason: '선 바깥은 불투명한 흰색');
  });

  test('결과가 상한을 넘어 줄여도 파일의 구분선은 #D0D0D0, 2px다', () async {
    final worker = await MergeWorker.spawn();
    const size = 300;
    final random = math.Random(9);
    final noise = File(p.join(dir.path, 'n.raw'))
      ..writeAsBytesSync(Uint8List.fromList(List.generate(size * size * 3, (_) => random.nextInt(256))));
    await worker.startPng(width: size, height: size, channels: 3);
    await worker.addRaw(rawPath: noise.path, x: 0, y: 0, width: size, height: size);
    await worker.drawDividers(const [PixelRect(149, 0, 2, size)]);
    final out = p.join(dir.path, 'out.png');
    final result = await worker.finishPng(outPath: out, maxBytes: 100000);
    worker.close();

    expect(result.width, lessThan(size));
    final decoded = img.decodePng(File(out).readAsBytesSync())!;
    // 줄인 칸 i는 원본 [⌊i × 300 ÷ w⌋, ⌊(i + 1) × 300 ÷ w⌋)의 평균이다. 원본 149가 든 칸부터 칠한다.
    final w = result.width;
    var x = 0;
    while ((x + 1) * size ~/ w <= 149) {
      x++;
    }
    for (final y in [0, 5, decoded.height - 1]) {
      expect(decoded.getPixel(x, y).r, 0xD0);
      expect(decoded.getPixel(x, y).g, 0xD0);
      expect(decoded.getPixel(x, y).b, 0xD0);
      expect(decoded.getPixel(x + 1, y).r, 0xD0);
    }
  });

  test('JPEG 파일을 페이지에 모아 PDF를 쓴다', () async {
    final worker = await MergeWorker.spawn();
    File jpeg(String name) => File(p.join(dir.path, name))
      ..writeAsBytesSync(img.encodeJpg(img.Image(width: 10, height: 10)));
    final a = jpeg('a.jpg');
    final b = jpeg('b.jpg');
    final c = jpeg('c.jpg');
    await worker.startPdf();
    await worker.addPdfImage(jpegPath: a.path, rect: const LayoutRect(0, 0, 100, 50));
    await worker.addPdfImage(jpegPath: b.path, rect: const LayoutRect(0, 50, 100, 50));
    await worker.finishPdfPage(widthPt: 100, heightPt: 100);
    await worker.addPdfImage(jpegPath: c.path, rect: const LayoutRect(0, 0, 100, 100));
    await worker.finishPdfPage(widthPt: 100, heightPt: 100);
    final out = p.join(dir.path, 'out.pdf');
    final bytes = await worker.finishPdf(outPath: out);
    worker.close();

    expect(a.existsSync(), isFalse, reason: '읽은 JPEG 파일은 지운다');
    expect(b.existsSync(), isFalse);
    expect(c.existsSync(), isFalse);
    expect(bytes, File(out).lengthSync());
    final text = latin1.decode(File(out).readAsBytesSync());
    expect(RegExp(r'/Type\s*/Page(?!s)').allMatches(text).length, 2, reason: '이미지는 3장, 페이지는 2장');
  });

  test('워커 안의 오류는 MergeException 코드로 돌아온다', () async {
    final worker = await MergeWorker.spawn();
    await worker.startPng(width: 2, height: 2, channels: 3);
    final wrong = writeRaw('w.raw', 1, 1, [0, 0, 0]);
    await expectLater(
      worker.addRaw(rawPath: wrong.path, x: 0, y: 0, width: 2, height: 2),
      throwsA(isA<MergeException>().having((e) => e.code, 'code', MergeErrorCode.corruptFile)),
    );
    worker.close();
  });

  test('kill하면 진행 중이던 인코딩과 이후 요청이 MergeCancelled로 끝난다', () async {
    final worker = await MergeWorker.spawn();
    const size = 1500;
    final random = math.Random(3);
    final noise = File(p.join(dir.path, 'n.raw'))
      ..writeAsBytesSync(Uint8List.fromList(List.generate(size * size * 3, (_) => random.nextInt(256))));
    await worker.startPng(width: size, height: size, channels: 3);
    await worker.addRaw(rawPath: noise.path, x: 0, y: 0, width: size, height: size);

    final encoding = worker.finishPng(outPath: p.join(dir.path, 'never.png'), maxBytes: 100000000);
    worker.kill();

    await expectLater(encoding, throwsA(isA<MergeCancelled>()));
    await expectLater(worker.startPdf(), throwsA(isA<MergeCancelled>()));
  });
}
