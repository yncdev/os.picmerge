import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_merger/core/database/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('iOS 데이터베이스 폴더는 Documents와 같은 앱 폴더의 Library/Application Support다', () {
    final directory = AppDatabase.iosDatabaseDirectory('/var/mobile/Containers/Data/Application/ABC/Documents');

    expect(
      directory.replaceAll(r'\', '/'),
      '/var/mobile/Containers/Data/Application/ABC/Library/Application Support',
    );
  });

  group('실제 파일 위치', () {
    late Directory root;
    late Directory documents;
    late String previousPath;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('app_database_test');
      documents = Directory(p.join(root.path, 'Documents'))..createSync();
      previousPath = await databaseFactoryFfi.getDatabasesPath();
      await databaseFactoryFfi.setDatabasesPath(documents.path);
    });
    tearDown(() async {
      debugDefaultTargetPlatformOverride = null;
      await databaseFactoryFfi.setDatabasesPath(previousPath);
      await root.delete(recursive: true);
    });

    test('iOS: 파일 앱에 보이지 않게 Documents 밖에 만든다', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final database = await AppDatabase.open(factory: databaseFactoryFfi);
      await database.close();

      expect(File(p.join(root.path, 'Library', 'Application Support', 'image_merger.db')).existsSync(), isTrue);
      expect(documents.listSync(), isEmpty, reason: '파일 앱에 내부 파일이 보이면 안 된다');
    });

    test('Android: sqflite 기본 경로 그대로다', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final database = await AppDatabase.open(factory: databaseFactoryFfi);
      await database.close();

      expect(File(p.join(documents.path, 'image_merger.db')).existsSync(), isTrue);
      expect(Directory(p.join(root.path, 'Library')).existsSync(), isFalse);
    });
  });

  test('deleteSetting은 그 설정만 지운다', () async {
    final database = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    addTearDown(database.close);
    await database.setSetting('a', '1');
    await database.setSetting('b', '2');

    await database.deleteSetting('a');

    expect(await database.getSetting('a'), isNull);
    expect(await database.getSetting('b'), '2');
  });
}
