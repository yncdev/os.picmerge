import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_merger/core/database/app_database.dart';
import 'package:image_merger/core/errors/merge_exception.dart';
import 'package:image_merger/core/platform/native_bridge.dart';
import 'package:image_merger/features/image_merger/data/save_folder_repository.dart';
import 'package:image_merger/features/image_merger/domain/output_format.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/fake_native_bridge.dart';

void main() {
  late AppDatabase database;
  late FakeNativeBridge bridge;
  late SaveFolderRepository repo;
  late Directory dir;
  late File source;

  const documents = FolderRef(uri: 'content://tree/docs', name: 'Docs');
  const download = FolderRef(uri: 'default', name: 'Download');

  setUp(() async {
    sqfliteFfiInit();
    database = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    bridge = FakeNativeBridge();
    repo = SaveFolderRepository(bridge: bridge, database: database);
    dir = await Directory.systemTemp.createTemp('save_folder_repository_test');
    source = File('${dir.path}/out.png')..writeAsBytesSync([1, 2, 3]);
  });
  tearDown(() async {
    await database.close();
    await dir.delete(recursive: true);
  });

  Future<void> rememberDocuments() async {
    await database.setSetting(AppDatabase.settingSaveTreeUri, documents.uri);
    await database.setSetting(AppDatabase.settingSaveFolderName, documents.name);
  }

  group('시작할 때의 폴더', () {
    test('고른 폴더가 있으면 그 폴더', () async {
      await rememberDocuments();

      final folder = await repo.loadCurrent();

      expect((folder!.uri, folder.name), (documents.uri, documents.name));
    });

    test('없으면 기본 폴더', () async {
      final folder = await repo.loadCurrent();

      expect((folder!.uri, folder.name), ('default', 'Download'));
    });

    test('기본 폴더도 없으면(Android 9 이하) null', () async {
      bridge.defaultFolderRef = null;

      expect(await repo.loadCurrent(), isNull);
    });
  });

  group('useDefault', () {
    test('저장된 폴더 설정을 지우고 기본 폴더를 돌려준다', () async {
      await rememberDocuments();

      final folder = await repo.useDefault();

      expect(folder!.uri, 'default');
      expect(await database.getSetting(AppDatabase.settingSaveTreeUri), isNull);
      expect(await database.getSetting(AppDatabase.settingSaveFolderName), isNull);
      expect(await repo.loadSaved(), isNull);
      expect((await repo.loadCurrent())!.uri, 'default');
    });
  });

  test('pick은 고른 폴더를 저장해 다음에도 쓴다', () async {
    final picked = await repo.pick();

    expect(picked!.name, 'Picked');
    expect((await repo.loadCurrent())!.uri, picked.uri);
  });

  group('save: 연번은 그 폴더의 같은 시각 파일을 피해 정한다', () {
    const base = '202610301536';

    Future<SavedDocument> save(FolderRef folder, OutputFormat format) => repo.save(
          folder: folder,
          sourcePath: source.path,
          baseName: base,
          format: format,
        );

    test('비어 있으면 _1', () async {
      expect((await save(download, OutputFormat.png)).name, '202610301536_1.png');
      expect(bridge.folders['default'], ['202610301536_1.png']);
    });

    test('다시 저장하면 _2, 형식이 다르면 _1부터', () async {
      expect((await save(download, OutputFormat.png)).name, '202610301536_1.png');
      expect((await save(download, OutputFormat.png)).name, '202610301536_2.png');
      expect((await save(download, OutputFormat.pdf)).name, '202610301536_1.pdf');
    });

    test('가장 작은 빈 번호를 쓴다', () async {
      bridge.folders['default'] = ['202610301536_1.png', '202610301536_3.png', '202610301535_2.png'];

      expect((await save(download, OutputFormat.png)).name, '202610301536_2.png');
    });

    test('폴더마다 따로 센다', () async {
      bridge.folders[documents.uri] = ['202610301536_1.png'];

      expect((await save(download, OutputFormat.png)).name, '202610301536_1.png');
      expect((await save(documents, OutputFormat.png)).name, '202610301536_2.png');
    });

    test('시스템이 이름을 바꾸면 실제 이름을 돌려준다', () async {
      bridge.renameOnCopy = (name) => name.replaceFirst('.png', ' (1).png');

      expect((await save(download, OutputFormat.png)).name, '202610301536_1 (1).png');
    });

    test('네이티브 오류는 MergeException으로', () async {
      bridge.copyError = 'out_of_space';

      await expectLater(
        save(download, OutputFormat.png),
        throwsA(isA<MergeException>().having((e) => e.code, 'code', MergeErrorCode.outOfSpace)),
      );
    });
  });

  group('checkAccessible', () {
    test('기본 폴더는 표식과 이름을 그대로 돌려준다', () async {
      final checked = await repo.checkAccessible(download);

      expect((checked!.uri, checked.name), ('default', 'Download'));
    });

    test('접근할 수 없으면 null', () async {
      bridge.inaccessibleUris.add(documents.uri);

      expect(await repo.checkAccessible(documents), isNull);
    });
  });
}
