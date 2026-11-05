import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import 'app.dart';
import 'core/database/app_database.dart';
import 'core/platform/native_bridge.dart';
import 'core/providers.dart';
import 'core/storage/temp_storage.dart';
import 'features/image_merger/data/save_folder_repository.dart';
import 'features/session_history/data/session_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 하단 배경색이 내비게이션 바 뒤까지 이어지게 한다 (DESIGN §2.2). 대비 강제를 끄지 않으면
  // 3버튼 내비게이션에서 시스템이 어두운 막을 깐다. 화면별 아이콘 색은 navBarOverlayStyle이 정한다.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
  ));
  // Android 15 이하는 기본값이 ACTION_GET_CONTENT 선택기이고, 그러면 장수 상한(limit)도 무시된다.
  // 시스템 Photo Picker를 쓰도록 켠다 (DESIGN §2.1.1). Android 16 이상은 항상 Photo Picker다.
  final picker = ImagePickerPlatform.instance;
  if (picker is ImagePickerAndroid) picker.useAndroidPhotoPicker = true;

  const bridge = NativeBridge();
  final database = await AppDatabase.open();

  // 강제 종료로 남은 임시 파일과 picker 복사본, 끝나지 않은 세션을 정리한다 (DESIGN §3.4).
  final tempStorage = TempStorage(await bridge.cacheDir());
  await tempStorage.cleanupLeftovers();
  final crashed = await SessionRepository(database).markRunningAsCrashed();
  final folder = await SaveFolderRepository(bridge: bridge, database: database).loadCurrent();

  runApp(ProviderScope(
    overrides: [
      appServicesProvider.overrideWithValue(AppServices(
        bridge: bridge,
        database: database,
        tempStorage: tempStorage,
        initialFolder: folder,
        crashedSessions: crashed,
      )),
    ],
    child: const ImageMergerApp(),
  ));
}
