import 'package:flutter/services.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/merge_exception.dart';
import '../../../core/platform/native_bridge.dart';
import '../domain/file_naming.dart';
import '../domain/output_format.dart';

/// 저장 폴더 (DESIGN §2.1.4). 고른 폴더가 있으면 그 폴더를, 없으면 기본 폴더를 쓴다.
class SaveFolderRepository {
  SaveFolderRepository({required this._bridge, required this._database});

  final NativeBridge _bridge;
  final AppDatabase _database;

  Future<FolderRef?> loadSaved() async {
    final uri = await _database.getSetting(AppDatabase.settingSaveTreeUri);
    if (uri == null) return null;
    final name = await _database.getSetting(AppDatabase.settingSaveFolderName) ?? '';
    return FolderRef(uri: uri, name: name);
  }

  /// 앱을 시작할 때의 저장 폴더. 고른 폴더도 기본 폴더도 없으면(Android 9 이하) null이다.
  Future<FolderRef?> loadCurrent() async => await loadSaved() ?? await _bridge.defaultFolder();

  Future<FolderRef?> defaultFolder() => _bridge.defaultFolder();

  /// 고른 폴더를 잊고 기본 폴더로 돌아간다.
  Future<FolderRef?> useDefault() async {
    await _database.deleteSetting(AppDatabase.settingSaveTreeUri);
    await _database.deleteSetting(AppDatabase.settingSaveFolderName);
    return _bridge.defaultFolder();
  }

  /// 접근할 수 있으면 최신 이름을 담아 돌려주고, 아니면 null.
  Future<FolderRef?> checkAccessible(FolderRef folder) async {
    final result = await _bridge.checkFolder(folder.uri);
    if (!result.ok) return null;
    return FolderRef(uri: folder.uri, name: result.name.isEmpty ? folder.name : result.name);
  }

  /// 폴더 선택기를 띄우고, 고른 폴더를 저장해 계속 쓴다.
  Future<FolderRef?> pick() async {
    final folder = await _bridge.pickFolder();
    if (folder == null) return null;
    await _database.setSetting(AppDatabase.settingSaveTreeUri, folder.uri);
    await _database.setSetting(AppDatabase.settingSaveFolderName, folder.name);
    return folder;
  }

  /// [sourcePath]를 폴더로 복사한다. 연번은 폴더에 있는 같은 시각의 파일을 피해 정한다.
  /// 돌려주는 이름은 실제 이름이다. Android 기본 폴더는 다른 앱의 파일이 보이지 않아 시스템이 바꿀 수 있다.
  Future<SavedDocument> save({
    required FolderRef folder,
    required String sourcePath,
    required String baseName,
    required OutputFormat format,
  }) async {
    try {
      final existing = await _bridge.listNames(folder.uri, baseName);
      final name = resolveFileName(baseName, format.extension, existing);
      return await _bridge.copyToFolder(
        uri: folder.uri,
        sourcePath: sourcePath,
        name: name,
        mimeType: format.mimeType,
      );
    } on PlatformException catch (e) {
      throw MergeException.fromPlatform(e);
    }
  }
}
