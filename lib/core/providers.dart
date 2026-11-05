import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/image_merger/data/merge_service.dart';
import '../features/image_merger/data/save_folder_repository.dart';
import '../features/image_selection/data/image_selection_repository.dart';
import '../features/session_history/data/session_repository.dart';
import 'database/app_database.dart';
import 'platform/native_bridge.dart';
import 'storage/temp_storage.dart';

/// main()에서 시작 작업을 마친 뒤 만든다.
class AppServices {
  const AppServices({
    required this.bridge,
    required this.database,
    required this.tempStorage,
    this.initialFolder,
    this.crashedSessions = 0,
  });

  final NativeBridge bridge;
  final AppDatabase database;
  final TempStorage tempStorage;

  /// 고른 폴더, 없으면 기본 폴더. 둘 다 없으면 null이다. 접근 가능 여부는 저장 버튼을 누를 때 확인한다.
  final FolderRef? initialFolder;

  /// 이번 시작 때 `crashed`로 바꾼 세션 수 (DESIGN §3.4).
  final int crashedSessions;
}

final appServicesProvider = Provider<AppServices>(
  (ref) => throw UnimplementedError('main()에서 overrideWithValue로 넣는다'),
);

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepository(ref.watch(appServicesProvider).database),
);

final saveFolderRepositoryProvider = Provider<SaveFolderRepository>((ref) {
  final services = ref.watch(appServicesProvider);
  return SaveFolderRepository(bridge: services.bridge, database: services.database);
});

final imageSelectionRepositoryProvider = Provider<ImageSelectionRepository>((ref) {
  final services = ref.watch(appServicesProvider);
  return ImageSelectionRepository(bridge: services.bridge, tempStorage: services.tempStorage);
});

final mergeServiceProvider = Provider<MergeService>(
  (ref) => MergeService(bridge: ref.watch(appServicesProvider).bridge),
);
