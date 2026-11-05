import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/native_bridge.dart';
import '../../../core/providers.dart';

/// 현재 저장 폴더. 고른 폴더가 없으면 기본 폴더이고, 기본 폴더도 없는 기기(Android 9 이하)면 null이라
/// 저장할 때 폴더를 고른다 (DESIGN §2.1.4).
class SaveFolderController extends Notifier<FolderRef?> {
  @override
  FolderRef? build() => ref.read(appServicesProvider).initialFolder;

  /// 저장 버튼을 누를 때, 합성을 시작하기 전에 부른다. 접근할 수 없으면 null이고 현재 폴더는 그대로 둔다.
  Future<FolderRef?> ensureAccessible() async {
    final current = state;
    if (current == null) return null;
    final checked = await ref.read(saveFolderRepositoryProvider).checkAccessible(current);
    if (checked != null) state = checked;
    return checked;
  }

  Future<FolderRef?> pick() async {
    final folder = await ref.read(saveFolderRepositoryProvider).pick();
    if (folder != null) state = folder;
    return folder;
  }

  Future<FolderRef?> defaultFolder() => ref.read(saveFolderRepositoryProvider).defaultFolder();

  /// 고른 폴더를 잊고 기본 폴더로 돌아간다.
  Future<FolderRef?> useDefault() async {
    final folder = await ref.read(saveFolderRepositoryProvider).useDefault();
    state = folder;
    return folder;
  }
}

final saveFolderProvider =
    NotifierProvider<SaveFolderController, FolderRef?>(SaveFolderController.new);
