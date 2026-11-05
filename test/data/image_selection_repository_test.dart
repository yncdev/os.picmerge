import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_merger/core/crop_rect.dart';
import 'package:image_merger/core/storage/temp_storage.dart';
import 'package:image_merger/features/image_selection/data/image_selection_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../support/fake_native_bridge.dart';

class _FakePicker extends ImagePicker {
  _FakePicker(this.files);

  final List<XFile> files;
  int? requestedLimit;

  /// pickImage(카메라)가 돌려줄 파일. null이면 찍지 않고 돌아온 경우다.
  XFile? cameraFile;
  ImageSource? requestedSource;
  bool cameraFails = false;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    requestedSource = source;
    if (cameraFails) throw PlatformException(code: 'no_available_camera');
    return cameraFile;
  }

  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) async {
    requestedLimit = limit;
    return files;
  }
}

void main() {
  late Directory cache;
  late FakeNativeBridge bridge;
  late TempStorage storage;
  const uuid = '3f2b8c1e-9a4d-4e2f-8b1a-0c9d8e7f6a5b';

  setUp(() async {
    cache = await Directory.systemTemp.createTemp('selection_repo_test');
    bridge = FakeNativeBridge(cacheDirPath: cache.path);
    storage = TempStorage(cache.path);
  });
  tearDown(() async => cache.delete(recursive: true));

  /// picker가 하는 것처럼 cacheDir/<UUID>/이름 에 복사본을 만든다.
  XFile pickerCopy(String name) {
    final dir = Directory(p.join(cache.path, uuid))..createSync(recursive: true);
    return XFile((File(p.join(dir.path, name))..writeAsStringSync('x')).path);
  }

  test('읽지 못한 파일과 상한을 넘는 파일은 빼고 복사본을 지운다', () async {
    final a = pickerCopy('a.jpg');
    final bad = pickerCopy('bad.gif');
    final c = pickerCopy('c.jpg');
    final d = pickerCopy('d.jpg');
    bridge.failures[bad.path] = 'unsupported_format';
    final picker = _FakePicker([a, bad, c, d]);
    final repo = ImageSelectionRepository(bridge: bridge, tempStorage: storage, picker: picker);

    final result = await repo.pick(remaining: 2);

    expect(picker.requestedLimit, 2);
    expect(result.images.map((i) => i.displayName), ['a.jpg', 'c.jpg']);
    expect(result.unsupported, 1);
    expect(result.overLimit, 1);
    expect(File(bad.path).existsSync(), isFalse);
    expect(File(d.path).existsSync(), isFalse);
    expect(File(a.path).existsSync(), isTrue);
  });

  test('썸네일은 긴 변 512px 이하 JPEG로 만들고, 목록에서 빼면 복사본과 함께 지운다', () async {
    final a = pickerCopy('a.jpg');
    final repo = ImageSelectionRepository(bridge: bridge, tempStorage: storage, picker: _FakePicker([a]));

    final image = (await repo.pick(remaining: 30)).images.single;

    expect(File(image.thumbnailPath).existsSync(), isTrue);
    expect(p.isWithin(storage.thumbnailDir.path, image.thumbnailPath), isTrue);
    final call = bridge.jpegCalls.single;
    expect(call.path, a.path);
    expect(call.width <= 512 && call.height <= 512, isTrue);

    await repo.discard(image);
    expect(File(image.thumbnailPath).existsSync(), isFalse);
    expect(File(a.path).existsSync(), isFalse);
    expect(Directory(p.join(cache.path, uuid)).existsSync(), isFalse);
  });

  test('썸네일을 못 만들면(디코딩 불가) 고를 때 뺀다', () async {
    final a = pickerCopy('a.heic');
    final repo = ImageSelectionRepository(bridge: bridge, tempStorage: storage, picker: _FakePicker([a]));
    bridge.reportedJpegBytes = null;
    bridge.failJpeg[a.path] = 'unsupported_format';

    final result = await repo.pick(remaining: 30);

    expect(result.images, isEmpty);
    expect(result.unsupported, 1);
    expect(storage.thumbnailDir.listSync(), isEmpty);
  });

  group('카메라', () {
    ImageSelectionRepository repoWith(_FakePicker picker) => ImageSelectionRepository(
          bridge: bridge,
          tempStorage: storage,
          picker: picker,
          clock: () => DateTime(2026, 11, 5, 9, 7, 3),
        );

    test('찍은 사진 1장을 시각이 들어간 이름으로 추가한다', () async {
      final picker = _FakePicker(const [])
        ..cameraFile = XFile(
          (File(p.join(cache.path, '${uuid}123.jpg'))..writeAsStringSync('x')).path,
        );

      final result = await repoWith(picker).takePhoto();

      expect(picker.requestedSource, ImageSource.camera);
      expect(result.images.single.displayName, 'camera_20261105_090703.jpg');
    });

    test('찍지 않고 돌아오면 빈 결과', () async {
      final result = await repoWith(_FakePicker(const [])).takePhoto();

      expect(result.images, isEmpty);
      expect(result.unsupported, 0);
    });

    test('카메라를 쓸 수 없으면 PlatformException을 그대로 던진다', () async {
      final picker = _FakePicker(const [])..cameraFails = true;

      await expectLater(repoWith(picker).takePhoto(), throwsA(isA<PlatformException>()));
    });
  });

  group('PDF', () {
    ImageSelectionRepository repo() =>
        ImageSelectionRepository(bridge: bridge, tempStorage: storage, picker: _FakePicker(const []));

    test('페이지마다 항목 1개로 펼치고, 원본 복사본은 지운다', () async {
      bridge
        ..pickedPdfUris = ['content://x/report.pdf']
        ..pdfPages['content://x/report.pdf'] = 3;
      final progress = <String>[];

      final result = await repo().pickPdfs(
        remaining: 30,
        onProgress: (done, total) => progress.add('$done/$total'),
      );

      expect(result.images.map((i) => i.displayName), [
        'report.pdf (1/3)',
        'report.pdf (2/3)',
        'report.pdf (3/3)',
      ]);
      expect(result.images.every((i) => File(i.path).existsSync()), isTrue);
      expect(result.unsupported, 0);
      expect(result.overLimit, 0);
      expect(progress, ['0/3', '1/3', '2/3', '3/3']);
      expect(bridge.renderCalls.map((c) => c.pageIndex), [0, 1, 2]);
      expect(bridge.renderCalls.first.dpi, 300);
      expect(bridge.renderCalls.first.maxLongSide, 4000);
      expect(bridge.renderCalls.first.quality, 92);
      expect(storage.pdfSourceDir.listSync(), isEmpty, reason: '고른 PDF 복사본은 남기지 않는다');
    });

    test('남은 자리보다 페이지가 많으면 앞에서부터 담고 넘친 수를 알린다', () async {
      bridge
        ..pickedPdfUris = ['content://x/a.pdf', 'content://x/b.pdf']
        ..pdfPages['content://x/a.pdf'] = 2
        ..pdfPages['content://x/b.pdf'] = 4;

      final result = await repo().pickPdfs(remaining: 3);

      expect(result.images.map((i) => i.displayName), ['a.pdf (1/2)', 'a.pdf (2/2)', 'b.pdf (1/4)']);
      expect(result.overLimit, 3);
      expect(bridge.renderCalls.length, 3, reason: '넘친 페이지는 렌더링하지 않는다');
    });

    test('암호 PDF는 빼고 세고, 나머지 PDF는 그대로 담는다', () async {
      bridge
        ..pickedPdfUris = ['content://x/locked.pdf', 'content://x/ok.pdf']
        ..pdfPages['content://x/ok.pdf'] = 1;

      final result = await repo().pickPdfs(remaining: 30);

      expect(result.images.single.displayName, 'ok.pdf (1/1)');
      expect(result.unsupported, 1);
      expect(storage.pdfSourceDir.listSync(), isEmpty);
    });

    test('렌더링에 실패한 페이지만 빼고 그 임시 파일을 남기지 않는다', () async {
      bridge
        ..pickedPdfUris = ['content://x/a.pdf']
        ..pdfPages['content://x/a.pdf'] = 2
        ..failPdfPages.add(0);

      final result = await repo().pickPdfs(remaining: 30);

      expect(result.images.single.displayName, 'a.pdf (2/2)');
      expect(result.unsupported, 1);
      expect(storage.pdfPageDir.listSync().length, 1);
    });

    test('문서 선택기를 닫으면 빈 결과', () async {
      final result = await repo().pickPdfs(remaining: 30);

      expect(result.images, isEmpty);
      expect(result.unsupported, 0);
    });

    test('항목을 버리면 페이지 이미지와 썸네일을 지운다', () async {
      bridge
        ..pickedPdfUris = ['content://x/a.pdf']
        ..pdfPages['content://x/a.pdf'] = 1;
      final repository = repo();
      final image = (await repository.pickPdfs(remaining: 30)).images.single;

      await repository.discard(image);

      expect(File(image.path).existsSync(), isFalse);
      expect(File(image.thumbnailPath).existsSync(), isFalse);
    });
  });

  group('영역 편집', () {
    ImageSelectionRepository repo() =>
        ImageSelectionRepository(bridge: bridge, tempStorage: storage, picker: _FakePicker(const []));

    Future<dynamic> item(ImageSelectionRepository repository) async {
      bridge
        ..pickedPdfUris = ['content://x/a.pdf']
        ..pdfPages['content://x/a.pdf'] = 1;
      return (await repository.pickPdfs(remaining: 30)).images.single;
    }

    test('영역을 적용하면 잘린 크기로 새 썸네일을 만들고 이전 썸네일을 지운다', () async {
      final repository = repo();
      final image = await item(repository);
      const crop = CropRect(0, 0, 0.5, 0.25);

      final updated = await repository.applyCrop(image, crop);

      expect(updated.crop, crop);
      expect((updated.size.width, updated.size.height), (50, 25), reason: '가짜 scan은 100×100');
      expect(File(image.thumbnailPath as String).existsSync(), isFalse);
      expect(File(updated.thumbnailPath).existsSync(), isTrue);
      expect(bridge.jpegCalls.last.crop, crop);
      expect((bridge.jpegCalls.last.width, bridge.jpegCalls.last.height), (50, 25));
    });

    test('전체 선택을 적용하면 영역을 지운다', () async {
      final repository = repo();
      final image = await item(repository);
      final cropped = await repository.applyCrop(image, const CropRect(0, 0, 0.5, 0.5));

      final reset = await repository.applyCrop(cropped, CropRect.full);

      expect(reset.crop, isNull);
      expect((reset.size.width, reset.size.height), (100, 100));
    });

    test('편집기 미리보기는 전체 영역이고 긴 변 1600px 이하다', () async {
      final repository = repo();
      final image = await item(repository);

      final path = await repository.createCropPreview(image);

      expect(File(path).existsSync(), isTrue);
      expect(bridge.jpegCalls.last.crop, isNull);
      await repository.discardPreview(path);
      expect(File(path).existsSync(), isFalse);
    });
  });
}
