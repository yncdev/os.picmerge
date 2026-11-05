// 플랫폼 채널 계약 시험. 기기에서 실행한다 (Android·iOS 공통):
//   flutter test integration_test/native_bridge_test.dart -d <기기 ID>
//
// PC 단위 테스트는 FakeNativeBridge를 쓰므로 Kotlin·Swift 코드를 실행하지 않는다.
// 이 시험이 실제 네이티브 디코딩·자르기·회색조·PDF 이미지화·공유 시트를 확인한다.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_merger/core/crop_rect.dart';
import 'package:image_merger/core/database/app_database.dart';
import 'package:image_merger/core/platform/native_bridge.dart';
import 'package:image_merger/features/about/domain/feedback.dart';
import 'package:image_merger/features/image_merger/data/merge_service.dart';
import 'package:image_merger/features/image_merger/domain/output_format.dart';
import 'package:image_merger/features/image_merger/domain/output_settings.dart';
import 'package:image_merger/features/image_selection/domain/selected_image.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sqflite/sqflite.dart' show getDatabasesPath;

const bridge = NativeBridge();

/// 사분면마다 색이 다른 이미지. 원본 기준: 왼쪽 위 빨강, 오른쪽 위 초록, 왼쪽 아래 파랑, 오른쪽 아래 노랑.
img.Image quadrants({int width = 400, int height = 200, int channels = 3}) {
  final image = img.Image(width: width, height: height, numChannels: channels);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final left = x < width / 2;
      final top = y < height / 2;
      if (top && left) {
        image.setPixelRgb(x, y, 255, 0, 0);
      } else if (top) {
        image.setPixelRgb(x, y, 0, 255, 0);
      } else if (left) {
        image.setPixelRgb(x, y, 0, 0, 255);
      } else {
        image.setPixelRgb(x, y, 255, 255, 0);
      }
    }
  }
  return image;
}

/// 색이 [expected]에 가까운지 본다. JPEG 손실을 감안한다.
Matcher closeToColor(List<int> expected, {int tolerance = 40}) => predicate<img.Pixel>(
      (c) =>
          (c.r - expected[0]).abs() <= tolerance &&
          (c.g - expected[1]).abs() <= tolerance &&
          (c.b - expected[2]).abs() <= tolerance,
      'RGB 약 $expected',
    );

const red = [255, 0, 0];
const green = [0, 255, 0];
const blue = [0, 0, 255];
const yellow = [255, 255, 0];
const white = [255, 255, 255];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;

  setUp(() async {
    final cache = await bridge.cacheDir();
    dir = await Directory(p.join(cache, 'bridge_test')).create(recursive: true);
  });
  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  String path(String name) => p.join(dir.path, name);

  File writeJpeg(String name, img.Image image) =>
      File(path(name))..writeAsBytesSync(img.encodeJpg(image, quality: 100));

  /// EXIF 방향 6: 표시하려면 시계 방향으로 90도 돌린다.
  /// 표시 기준: 왼쪽 위 파랑, 오른쪽 위 빨강, 왼쪽 아래 노랑, 오른쪽 아래 초록.
  File rotatedJpeg(String name) {
    final image = quadrants()..exif.imageIfd.orientation = 6;
    return writeJpeg(name, image);
  }

  img.Image readJpeg(String file) => img.decodeJpg(File(file).readAsBytesSync())!;

  group('scan', () {
    test('EXIF 방향을 반영한 크기와 MIME을 돌려준다', () async {
      final header = await bridge.scan(rotatedJpeg('a.jpg').path);

      expect((header.width, header.height), (200, 400));
      expect(header.mime, 'image/jpeg');
      expect(header.bytes, greaterThan(0));
    });

    test('없는 파일은 source_unavailable, 이미지가 아니면 unsupported_format', () async {
      await expectLater(
        bridge.scan(path('none.jpg')),
        throwsA(isA<PlatformException>().having((e) => e.code, 'code', 'source_unavailable')),
      );
      final text = File(path('a.txt'))..writeAsStringSync('hello');
      await expectLater(
        bridge.scan(text.path),
        throwsA(isA<PlatformException>().having((e) => e.code, 'code', 'unsupported_format')),
      );
    });
  });

  group('encodeJpeg', () {
    test('EXIF 회전을 반영해 그린다', () async {
      final out = path('o.jpg');
      final bytes = await bridge.encodeJpeg(
        path: rotatedJpeg('a.jpg').path,
        width: 200,
        height: 400,
        quality: 95,
        outPath: out,
      );

      expect(bytes, File(out).lengthSync());
      final r = readJpeg(out);
      expect((r.width, r.height), (200, 400));
      expect(r.getPixel(50, 100), closeToColor(blue));
      expect(r.getPixel(150, 100), closeToColor(red));
      expect(r.getPixel(50, 300), closeToColor(yellow));
      expect(r.getPixel(150, 300), closeToColor(green));
    });

    test('자르기는 EXIF 회전 뒤 좌표로 한다: 표시 기준 오른쪽 위 사분면은 빨강', () async {
      final out = path('o.jpg');
      await bridge.encodeJpeg(
        path: rotatedJpeg('a.jpg').path,
        width: 100,
        height: 200,
        quality: 95,
        outPath: out,
        crop: const CropRect(0.5, 0, 1, 0.5),
      );

      final r = readJpeg(out);
      expect((r.width, r.height), (100, 200));
      for (final point in [(10, 10), (90, 10), (10, 190), (90, 190)]) {
        expect(r.getPixel(point.$1, point.$2), closeToColor(red), reason: '$point');
      }
    });

    test('회전 없는 이미지도 자른다: 왼쪽 아래 사분면은 파랑', () async {
      final out = path('o.jpg');
      await bridge.encodeJpeg(
        path: writeJpeg('a.jpg', quadrants()).path,
        width: 200,
        height: 100,
        quality: 95,
        outPath: out,
        crop: const CropRect(0, 0.5, 0.5, 1),
      );

      final r = readJpeg(out);
      expect((r.width, r.height), (200, 100));
      expect(r.getPixel(100, 50), closeToColor(blue));
    });

    test('회색조는 R=G=B이고 밝기가 살아 있다', () async {
      final out = path('o.jpg');
      await bridge.encodeJpeg(
        path: writeJpeg('a.jpg', quadrants()).path,
        width: 400,
        height: 200,
        quality: 95,
        outPath: out,
        grayscale: true,
      );

      final r = readJpeg(out);
      for (final point in [(100, 50), (300, 50), (100, 150), (300, 150)]) {
        final c = r.getPixel(point.$1, point.$2);
        expect((c.r - c.g).abs(), lessThanOrEqualTo(6), reason: '$point');
        expect((c.g - c.b).abs(), lessThanOrEqualTo(6), reason: '$point');
      }
      // 노랑은 파랑보다 훨씬 밝아야 한다.
      expect(r.getPixel(300, 150).r, greaterThan(r.getPixel(100, 150).r + 100));
    });

    test('투명 영역은 흰색으로 채운다', () async {
      final png = img.Image(width: 40, height: 40, numChannels: 4)
        ..clear(img.ColorRgba8(0, 0, 0, 0));
      final source = File(path('t.png'))..writeAsBytesSync(img.encodePng(png));
      final out = path('o.jpg');

      await bridge.encodeJpeg(path: source.path, width: 40, height: 40, quality: 95, outPath: out);

      expect(readJpeg(out).getPixel(20, 20), closeToColor(white));
    });
  });

  group('decodeRaw', () {
    test('RGB raw는 행 단위이고, 투명 영역은 흰색 위에 합친다', () async {
      final png = img.Image(width: 2, height: 1, numChannels: 4);
      png.setPixelRgba(0, 0, 255, 0, 0, 255);
      png.setPixelRgba(1, 0, 0, 0, 0, 0);
      final source = File(path('t.png'))..writeAsBytesSync(img.encodePng(png));
      final out = path('o.raw');

      await bridge.decodeRaw(path: source.path, width: 2, height: 1, channels: 3, outPath: out);

      final raw = File(out).readAsBytesSync();
      expect(raw.length, 6);
      expect(raw.sublist(0, 3), [255, 0, 0]);
      expect(raw.sublist(3, 6), [255, 255, 255]);
    });

    test('RGBA raw는 투명도를 그대로 둔다', () async {
      final png = img.Image(width: 2, height: 1, numChannels: 4);
      png.setPixelRgba(0, 0, 255, 0, 0, 255);
      png.setPixelRgba(1, 0, 0, 0, 0, 0);
      final source = File(path('t.png'))..writeAsBytesSync(img.encodePng(png));
      final out = path('o.raw');

      await bridge.decodeRaw(path: source.path, width: 2, height: 1, channels: 4, outPath: out);

      final raw = File(out).readAsBytesSync();
      expect(raw.length, 8);
      expect(raw.sublist(0, 4), [255, 0, 0, 255]);
      expect(raw[7], 0);
    });

    test('자르기와 회색조를 함께 적용한다', () async {
      final source = writeJpeg('a.jpg', quadrants());
      final out = path('o.raw');

      await bridge.decodeRaw(
        path: source.path,
        width: 100,
        height: 50,
        channels: 3,
        outPath: out,
        crop: const CropRect(0.5, 0.5, 1, 1),
        grayscale: true,
      );

      final raw = File(out).readAsBytesSync();
      expect(raw.length, 100 * 50 * 3);
      final middle = (25 * 100 + 50) * 3;
      expect((raw[middle] - raw[middle + 1]).abs(), lessThanOrEqualTo(2));
      expect(raw[middle], greaterThan(180), reason: '노랑의 회색조는 밝다');
    });
  });

  group('PDF', () {
    Future<File> pdfFile() async {
      final doc = pw.Document();
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Align(
          alignment: pw.Alignment.topLeft,
          // PdfColors.red는 Material 색이라 순수 빨강이 아니다.
          child: pw.Container(width: 300, height: 300, color: const PdfColor(1, 0, 0)),
        ),
      ));
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Container(color: const PdfColor(0, 0, 1)),
      ));
      return File(path('in.pdf'))..writeAsBytesSync(await doc.save());
    }

    test('페이지 수를 세고, A4를 300DPI로 렌더링한다', () async {
      final source = await pdfFile();
      expect(await bridge.pdfPageCount(source.path), 2);

      final out = path('p0.jpg');
      final watch = Stopwatch()..start();
      await bridge.renderPdfPage(
        path: source.path,
        pageIndex: 0,
        dpi: 300,
        maxLongSide: 4000,
        quality: 92,
        outPath: out,
      );
      debugPrint('renderPdfPage A4 300DPI: ${watch.elapsedMilliseconds}ms, ${File(out).lengthSync()} bytes');

      // 870만 화소를 Dart로 풀면 기기에서 수십 초 걸려 크기만 네이티브로 읽는다.
      final header = await bridge.scan(out);
      // A4는 595.28×841.89pt = 2480×3508px다. Android PdfRenderer는 페이지 크기를 정수 pt(595×841)로
      // 주므로 2479×3504가 된다. 비율 차이가 0.1% 미만이라 허용한다.
      expect(header.width, closeTo(2480, 6));
      expect(header.height, closeTo(3508, 6));
      expect(header.mime, 'image/jpeg');
    });

    test('흰 배경 위에 페이지 내용을 제 위치에 그린다', () async {
      final source = await pdfFile();
      final out = path('p0.jpg');

      await bridge.renderPdfPage(
        path: source.path,
        pageIndex: 0,
        dpi: 300,
        maxLongSide: 842,
        quality: 92,
        outPath: out,
      );

      // 긴 변 842px면 1pt ≈ 1px이다. 왼쪽 위 300pt 사각형만 빨강이고 나머지는 흰색이다.
      final r = readJpeg(out);
      expect(r.getPixel(100, 100), closeToColor(red));
      expect(r.getPixel(280, 280), closeToColor(red));
      expect(r.getPixel(400, 100), closeToColor(white));
      expect(r.getPixel(100, 400), closeToColor(white));
      expect(r.getPixel(r.width - 10, r.height - 10), closeToColor(white));
    });

    test('가로 페이지와 긴 변 상한', () async {
      final source = await pdfFile();
      final out = path('p1.jpg');

      await bridge.renderPdfPage(
        path: source.path,
        pageIndex: 1,
        dpi: 300,
        maxLongSide: 1000,
        quality: 92,
        outPath: out,
      );

      final r = readJpeg(out);
      expect(r.width, 1000);
      expect(r.height, closeTo(707, 2));
      expect(r.getPixel(500, 300), closeToColor(blue));
    });

    test('PDF가 아니면 corrupt_file', () async {
      final bad = File(path('bad.pdf'))..writeAsStringSync('not a pdf');

      await expectLater(
        bridge.pdfPageCount(bad.path),
        throwsA(isA<PlatformException>().having((e) => e.code, 'code', 'corrupt_file')),
      );
    });

    test('이미지로 만든 페이지를 일반 이미지처럼 읽을 수 있다', () async {
      final source = await pdfFile();
      final out = path('p0.jpg');
      await bridge.renderPdfPage(
        path: source.path,
        pageIndex: 0,
        dpi: 300,
        maxLongSide: 1000,
        quality: 92,
        outPath: out,
      );
      final thumb = path('thumb.jpg');

      final header = await bridge.scan(out);
      await bridge.encodeJpeg(
        path: out,
        width: header.width ~/ 2,
        height: header.height ~/ 2,
        quality: 80,
        outPath: thumb,
        crop: const CropRect(0, 0, 0.5, 0.5),
      );

      expect(header.height, 1000);
      expect(header.mime, 'image/jpeg');
      expect(readJpeg(thumb).getPixel(50, 50), closeToColor(red));
    });
  });

  group('importDocument', () {
    test('file URI를 복사하고 표시 이름을 돌려준다', () async {
      final source = File(path('보고서 1.pdf'))..writeAsStringSync('%PDF-data');
      final out = path('copy.pdf');

      final document = await bridge.importDocument(uri: Uri.file(source.path).toString(), outPath: out);

      expect(File(out).readAsStringSync(), '%PDF-data');
      expect(document.name, '보고서 1.pdf');
      expect(document.path, out);
    });
  });

  group('실제 합성', () {
    SelectedImage selected(File file, int width, int height, {CropRect? crop}) => SelectedImage(
          path: file.path,
          thumbnailPath: '',
          displayName: p.basename(file.path),
          width: width,
          height: height,
          bytes: file.lengthSync(),
          mime: 'image/jpeg',
          crop: crop,
        );

    Future<MergeResult> merge(List<SelectedImage> images, OutputFormat format, OutputSettings settings) async {
      final jobDir = await Directory(path('job')).create(recursive: true);
      return MergeService(bridge: bridge).merge(
        images: images,
        format: format,
        settings: settings,
        jobDir: jobDir,
        token: CancelToken(),
        onProgress: (_) {},
      );
    }

    test('A4 PNG: 페이지마다 흰 여백 위에 잘라낸 영역과 회전한 이미지를 놓고 구분선으로 잇는다', () async {
      final a = writeJpeg('a.jpg', quadrants());
      final b = rotatedJpeg('b.jpg');

      final result = await merge(
        [
          // 왼쪽 위 사분면만 쓴다 (빨강 200×100).
          selected(a, 400, 200, crop: const CropRect(0, 0, 0.5, 0.5)),
          selected(b, 200, 400),
        ],
        OutputFormat.png,
        const OutputSettings(),
      );

      // A4 세로 → 가로 배치. 페이지 2480×3508 두 장과 사이 구분선 7px.
      expect((result.width, result.height), (4967, 3508));
      final decoded = img.decodePng(File(result.tempPath).readAsBytesSync())!;
      expect(decoded.numChannels, 3);
      // 첫 페이지: 여백 124 안쪽 칸 2232×3260. 2:1 이미지는 폭을 채워 2232×1116, 위 124 + (3260 − 1116) ÷ 2 = 1196
      expect(decoded.getPixel(1240, 1196 + 558), closeToColor(red), reason: '잘라낸 영역');
      expect(decoded.getPixel(20, 20), closeToColor(white), reason: '용지 여백');
      // 페이지 사이 구분선은 정확히 #D0D0D0이다.
      final line = decoded.getPixel(2483, 1000);
      expect([line.r, line.g, line.b], [0xD0, 0xD0, 0xD0]);
      // 둘째 페이지(왼쪽 2487): 1:2 이미지는 높이를 채워 1630×3260
      // 왼쪽 2487 + 124 + (2232 − 1630) ÷ 2 = 2912, 위 124
      // 표시 기준 왼쪽 위가 파랑, 오른쪽 아래가 초록
      expect(decoded.getPixel(2912 + 407, 124 + 815), closeToColor(blue));
      expect(decoded.getPixel(2912 + 1222, 124 + 2445), closeToColor(green));
    });

    test('A4 PDF N=2: 두 이미지가 한 페이지에 들어간다', () async {
      final result = await merge(
        [selected(writeJpeg('a.jpg', quadrants()), 400, 200), selected(rotatedJpeg('b.jpg'), 200, 400)],
        OutputFormat.pdf,
        const OutputSettings(imagesPerPaper: 2),
      );

      final text = String.fromCharCodes(File(result.tempPath).readAsBytesSync());
      expect(RegExp(r'/Type\s*/Page(?!s)').allMatches(text).length, 1);
    });

    test('흑백 PDF: 용지 페이지 수와 크기, DCTDecode', () async {
      final result = await merge(
        [selected(writeJpeg('a.jpg', quadrants()), 400, 200), selected(rotatedJpeg('b.jpg'), 200, 400)],
        OutputFormat.pdf,
        const OutputSettings(grayscale: true, orientation: PaperOrientation.landscape),
      );

      final bytes = File(result.tempPath).readAsBytesSync();
      final text = String.fromCharCodes(bytes);
      expect(text.startsWith('%PDF'), isTrue);
      expect(RegExp(r'/Type\s*/Page(?!s)').allMatches(text).length, 2);
      expect(RegExp(r'/MediaBox\s*\[\s*0\s+0\s+841\.88').allMatches(text).length, 2);
      expect(text, contains('/DCTDecode'));

      // 실제로 그린 페이지 픽셀이 회색인지 네이티브 렌더러로 확인한다.
      final out = path('check.jpg');
      await bridge.renderPdfPage(
        path: result.tempPath,
        pageIndex: 0,
        dpi: 72,
        maxLongSide: 1000,
        quality: 95,
        outPath: out,
      );
      final page = readJpeg(out);
      final c = page.getPixel(page.width ~/ 4, page.height ~/ 3);
      expect((c.r - c.g).abs(), lessThanOrEqualTo(8));
      expect((c.g - c.b).abs(), lessThanOrEqualTo(8));
    });
  });

  group('기본 저장 폴더', () {
    // Android는 실제 Download 폴더에 파일이 남는다. 만든 이름을 출력하니 확인한 뒤 지운다.
    const prefix = 'picmerge_integration_test_';

    File writePng(String name) =>
        File(path(name))..writeAsBytesSync(Uint8List.fromList(img.encodePng(img.Image(width: 4, height: 4))));

    if (Platform.isAndroid) {
      test('Android: Download에 저장하고, 이름이 겹치면 실제 이름을 돌려주고, 실패하면 남기지 않는다', () async {
        final folder = await bridge.defaultFolder();
        if (folder == null) {
          // API 29 미만은 기본 폴더가 없다.
          expect((await bridge.checkFolder('default')).ok, isFalse);
          expect(await bridge.listNames('default', prefix), isEmpty);
          return;
        }
        expect((folder.uri, folder.name), ('default', 'Download'));
        final checked = await bridge.checkFolder(folder.uri);
        expect((checked.ok, checked.name), (true, 'Download'));

        final name = '$prefix${DateTime.now().millisecondsSinceEpoch}.png';
        final source = writePng('source.png');

        final first = await bridge.copyToFolder(
          uri: folder.uri,
          sourcePath: source.path,
          name: name,
          mimeType: 'image/png',
        );
        debugPrint('created in Download: ${first.name} (${first.uri})');
        expect(first.name, name);
        expect(await bridge.listNames(folder.uri, prefix), contains(name));

        // 같은 이름으로 다시 저장하면 시스템이 이름을 바꾼다. 앱은 실제 이름을 받아야 한다.
        final second = await bridge.copyToFolder(
          uri: folder.uri,
          sourcePath: source.path,
          name: name,
          mimeType: 'image/png',
        );
        debugPrint('created in Download: ${second.name} (${second.uri})');
        expect(second.name, isNot(name));
        expect(second.name, startsWith(name.substring(0, name.length - 4)));
        expect(second.uri, isNot(first.uri));
        final listed = await bridge.listNames(folder.uri, prefix);
        expect(listed, containsAll([first.name, second.name]));

        // 원본이 없어 쓰다 실패하면 만든 행을 지운다.
        final failedName = '${prefix}failed_${DateTime.now().millisecondsSinceEpoch}.png';
        await expectLater(
          bridge.copyToFolder(
            uri: folder.uri,
            sourcePath: path('none.png'),
            name: failedName,
            mimeType: 'image/png',
          ),
          throwsA(isA<PlatformException>()),
        );
        expect(await bridge.listNames(folder.uri, failedName), isEmpty);

        // 이름 앞부분은 글자 그대로 찾는다. LIKE의 %가 와일드카드로 쓰이면 여기서 무언가 나온다.
        expect(await bridge.listNames(folder.uri, 'picmerge%'), isEmpty);
      });
    }

    if (Platform.isIOS) {
      test('iOS: 앱 Documents에 저장하고 데이터베이스는 그 밖에 있다', () async {
        final folder = (await bridge.defaultFolder())!;
        expect((folder.uri, folder.name), ('default', 'Pic Merge'));
        final checked = await bridge.checkFolder(folder.uri);
        expect((checked.ok, checked.name), (true, 'Pic Merge'));

        final documents = await getDatabasesPath();
        expect(p.basename(documents), 'Documents');

        final name = '$prefix${DateTime.now().millisecondsSinceEpoch}.png';
        final saved = await bridge.copyToFolder(
          uri: folder.uri,
          sourcePath: writePng('source.png').path,
          name: name,
          mimeType: 'image/png',
        );

        expect(saved.name, name);
        final target = File(p.join(documents, name));
        expect(target.existsSync(), isTrue, reason: 'Documents에 있어야 한다');
        expect(await bridge.listNames(folder.uri, prefix), contains(name));
        target.deleteSync();

        final database = await AppDatabase.open();
        await database.close();
        expect(File(p.join(AppDatabase.iosDatabaseDirectory(documents), 'image_merger.db')).existsSync(), isTrue);
        expect(File(p.join(documents, 'image_merger.db')).existsSync(), isFalse);
      });
    }
  });

  group('appInfo', () {
    test('설치된 앱과 기기 정보를 돌려준다', () async {
      final info = await bridge.appInfo();

      expect(info.versionName, isNotEmpty);
      expect(int.tryParse(info.buildNumber), isNotNull);
      expect(info.manufacturer, isNotEmpty);
      expect(info.model, isNotEmpty);
      expect(info.osVersion, isNotEmpty);
      expect(info.osName, Platform.isIOS ? 'iOS' : 'Android');
      if (Platform.isIOS) expect(info.manufacturer, 'Apple');
      // 메일을 여는 메서드는 시험하지 않는다. 제목이 어떻게 되는지만 출력한다.
      debugPrint('feedback subject: ${feedbackSubject(info)}');
    });
  });

  group('공유', () {
    test('공유 시트를 오류 없이 연다', () async {
      final cache = await bridge.cacheDir();
      final share = await Directory(p.join(cache, 'share')).create(recursive: true);
      final file = File(p.join(share.path, 'test.png'))
        ..writeAsBytesSync(Uint8List.fromList(img.encodePng(img.Image(width: 2, height: 2))));

      await bridge.shareFile(path: file.path, mimeType: 'image/png', name: 'test.png');

      await share.delete(recursive: true);
    });
  });
}
