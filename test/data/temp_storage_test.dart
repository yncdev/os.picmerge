import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_merger/core/storage/temp_storage.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory cache;
  late TempStorage storage;
  const uuid = '3f2b8c1e-9a4d-4e2f-8b1a-0c9d8e7f6a5b';

  setUp(() async {
    cache = await Directory.systemTemp.createTemp('temp_storage_test');
    storage = TempStorage(cache.path);
  });
  tearDown(() async => cache.delete(recursive: true));

  test('시작 정리: 작업 폴더와 picker UUID 폴더만 지운다', () async {
    final job = await storage.createJobDir();
    File(p.join(job.path, 'image_0.raw')).writeAsStringSync('x');
    final picker = Directory(p.join(cache.path, uuid))..createSync();
    File(p.join(picker.path, 'IMG_0001.jpg')).writeAsStringSync('x');
    final other = Directory(p.join(cache.path, 'flutter_engine'))..createSync();

    await storage.cleanupLeftovers();

    expect(storage.workDir.existsSync(), isFalse);
    expect(picker.existsSync(), isFalse);
    expect(other.existsSync(), isTrue);
  });

  test('picker 복사본을 지우고, 비면 UUID 폴더도 지운다', () async {
    final picker = Directory(p.join(cache.path, uuid))..createSync();
    final file = File(p.join(picker.path, 'IMG_0001.jpg'))..writeAsStringSync('x');

    await storage.deletePickerCopy(file.path);

    expect(file.existsSync(), isFalse);
    expect(picker.existsSync(), isFalse);
  });

  test('UUID 폴더에 다른 파일이 남아 있으면 폴더는 둔다', () async {
    final picker = Directory(p.join(cache.path, uuid))..createSync();
    final a = File(p.join(picker.path, 'a.jpg'))..writeAsStringSync('x');
    File(p.join(picker.path, 'b.jpg')).writeAsStringSync('x');

    await storage.deletePickerCopy(a.path);

    expect(picker.existsSync(), isTrue);
  });

  test('시작 정리: PDF 페이지·원본 복사본·공유 파일과 카메라·iOS picker 임시 파일도 지운다', () async {
    File(await storage.newPdfPagePath()).writeAsStringSync('x');
    File(await storage.newPdfSourcePath()).writeAsStringSync('x');
    final source = File(p.join(cache.path, 'out.png'))..writeAsStringSync('x');
    await storage.prepareShareFile(source.path, 'share.png');
    final cameraCopy = File(p.join(cache.path, '${uuid}1234567890.jpg'))..writeAsStringSync('x');
    final iosCopy = File(p.join(cache.path, 'image_picker_ABC-DEF.jpg'))..writeAsStringSync('x');
    final unrelated = File(p.join(cache.path, 'keep.jpg'))..writeAsStringSync('x');

    await storage.cleanupLeftovers();

    expect(storage.pdfPageDir.existsSync(), isFalse);
    expect(storage.pdfSourceDir.existsSync(), isFalse);
    expect(storage.shareDir.existsSync(), isFalse);
    expect(cameraCopy.existsSync(), isFalse);
    expect(iosCopy.existsSync(), isFalse);
    expect(unrelated.existsSync(), isTrue);
  });

  test('공유 파일은 지난 공유 파일을 지우고 새 이름으로 복사한다', () async {
    final a = File(p.join(cache.path, 'a.png'))..writeAsStringSync('first');
    final b = File(p.join(cache.path, 'b.png'))..writeAsStringSync('second');

    final first = await storage.prepareShareFile(a.path, '1.png');
    final second = await storage.prepareShareFile(b.path, '2.png');

    expect(File(first).existsSync(), isFalse);
    expect(File(second).readAsStringSync(), 'second');
    expect(a.existsSync(), isTrue, reason: '원본은 호출한 쪽이 지운다');
  });
}
