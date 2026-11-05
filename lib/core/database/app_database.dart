import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// 로컬 SQLite (DESIGN §3.2).
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const settingSaveTreeUri = 'save_tree_uri';
  static const settingSaveFolderName = 'save_folder_name';

  /// [factory]와 [path]는 테스트에서 sqflite_common_ffi와 메모리 DB를 넣을 때 쓴다.
  static Future<AppDatabase> open({DatabaseFactory? factory, String? path}) async {
    final f = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await _databaseDirectory(f), 'image_merger.db');
    final db = await f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _create,
      ),
    );
    return AppDatabase._(db);
  }

  /// iOS의 sqflite 기본 경로는 Documents라 파일 앱에 그대로 보인다 (DESIGN §2.1.4).
  /// 같은 앱 폴더 안의 Library/Application Support에 둔다.
  @visibleForTesting
  static String iosDatabaseDirectory(String documentsPath) =>
      p.join(p.dirname(documentsPath), 'Library', 'Application Support');

  static Future<String> _databaseDirectory(DatabaseFactory factory) async {
    final defaultPath = await factory.getDatabasesPath();
    if (defaultTargetPlatform != TargetPlatform.iOS) return defaultPath;
    final directory = iosDatabaseDirectory(defaultPath);
    await Directory(directory).create(recursive: true);
    return directory;
  }

  static Future<void> _create(Database db, int version) async {
    final batch = db.batch()
      ..execute('''
        CREATE TABLE sessions (
          id             INTEGER PRIMARY KEY,
          started_at     TEXT    NOT NULL,
          finished_at    TEXT,
          status         TEXT    NOT NULL,
          error_code     TEXT,
          output_format  TEXT    NOT NULL,
          direction      TEXT,
          image_count    INTEGER NOT NULL,
          output_width   INTEGER,
          output_height  INTEGER,
          output_bytes   INTEGER,
          output_name    TEXT,
          output_folder  TEXT
        )''')
      ..execute('CREATE INDEX idx_sessions_started_at ON sessions(started_at)')
      ..execute('''
        CREATE TABLE session_images (
          session_id     INTEGER NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
          position       INTEGER NOT NULL,
          display_name   TEXT    NOT NULL,
          src_width      INTEGER NOT NULL,
          src_height     INTEGER NOT NULL,
          src_bytes      INTEGER NOT NULL,
          applied_scale  REAL,
          PRIMARY KEY (session_id, position)
        )''')
      ..execute('''
        CREATE TABLE app_settings (
          key    TEXT PRIMARY KEY,
          value  TEXT NOT NULL
        )''');
    await batch.commit(noResult: true);
  }

  Future<String?> getSetting(String key) async {
    final rows = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) => db.insert(
        'app_settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<void> deleteSetting(String key) =>
      db.delete('app_settings', where: 'key = ?', whereArgs: [key]);

  Future<void> close() => db.close();
}
