import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_merger/core/database/app_database.dart';
import 'package:image_merger/core/errors/merge_exception.dart';
import 'package:image_merger/core/platform/native_bridge.dart';
import 'package:image_merger/core/providers.dart';
import 'package:image_merger/core/storage/temp_storage.dart';
import 'package:image_merger/features/image_merger/domain/layout_direction.dart';
import 'package:image_merger/features/image_merger/domain/output_format.dart';
import 'package:image_merger/features/image_merger/domain/output_settings.dart';
import 'package:image_merger/features/image_merger/presentation/merge_controller.dart';
import 'package:image_merger/features/image_merger/presentation/output_settings_controller.dart';
import 'package:image_merger/features/image_selection/domain/selected_image.dart';
import 'package:image_merger/features/image_selection/presentation/selection_controller.dart';
import 'package:image_merger/features/session_history/data/session_repository.dart';
import 'package:image_merger/features/session_history/domain/session_record.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/fake_native_bridge.dart';

class _Preset extends SelectionController {
  @override
  List<SelectedImage> build() => const [
        SelectedImage(
          path: '/picked/a.jpg',
          thumbnailPath: '/thumbs/a.jpg',
          displayName: 'a.jpg',
          width: 400,
          height: 200,
          bytes: 1000,
          mime: 'image/jpeg',
        ),
        SelectedImage(
          path: '/picked/b.jpg',
          thumbnailPath: '/thumbs/b.jpg',
          displayName: 'report.pdf (1/2)',
          width: 400,
          height: 200,
          bytes: 1000,
          mime: 'image/jpeg',
        ),
      ];
}

void main() {
  late AppDatabase database;
  late Directory cache;
  late FakeNativeBridge bridge;
  late TempStorage storage;
  late ProviderContainer container;

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    database = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    cache = await Directory.systemTemp.createTemp('merge_controller_test');
    bridge = FakeNativeBridge(cacheDirPath: cache.path);
    storage = TempStorage(cache.path);
    container = ProviderContainer(overrides: [
      appServicesProvider.overrideWithValue(
        AppServices(bridge: bridge, database: database, tempStorage: storage),
      ),
      selectionProvider.overrideWith(_Preset.new),
    ]);
  });
  tearDown(() async {
    container.dispose();
    await database.close();
    await cache.delete(recursive: true);
  });

  MergeController controller() => container.read(mergeControllerProvider.notifier);
  Future<SessionRecord> lastSession() async => (await SessionRepository(database).recent()).first;

  test('공유: 결과 파일을 공유 폴더에 두고 공유 시트를 열고, 세션을 공유로 기록한다', () async {
    final outcome = await controller().share(OutputFormat.pdf);

    expect(outcome, isA<MergeSucceeded>().having((o) => o.shared, 'shared', isTrue));
    final call = bridge.shareCalls.single;
    expect(call.mimeType, 'application/pdf');
    expect(call.name, matches(RegExp(r'^\d{12}_1\.pdf$')), reason: '공유도 같은 이름 규칙이다');
    expect(call.fileExisted, isTrue);
    expect(File(call.path).existsSync(), isTrue, reason: '받는 앱이 나중에 읽을 수 있어 남겨 둔다');
    expect(call.path, startsWith(storage.shareDir.path));
    expect(storage.workDir.listSync(), isEmpty, reason: '작업 폴더는 지운다');

    final session = await lastSession();
    expect(session.status, SessionStatus.success);
    expect(session.outputFolder, '공유', reason: '이미 기록된 행과 맞아야 하는 언어 무관 표식');
    expect(kShareFolderSentinel, '공유');
    expect(session.outputName, call.name);
    expect(container.read(mergeControllerProvider), isA<MergeIdle>());
  });

  test('공유 시트를 열지 못하면 실패로 기록하고 오류를 돌려준다', () async {
    bridge.shareError = 'unknown';

    final outcome = await controller().share(OutputFormat.png);

    expect(outcome, isA<MergeFailed>());
    expect((await lastSession()).status, SessionStatus.failed);
    expect(bridge.shareCalls.single.fileExisted, isTrue, reason: '공유 시트를 열기 전에는 파일이 있었다');
    final left = storage.shareDir.existsSync() ? storage.shareDir.listSync() : const <FileSystemEntity>[];
    expect(left, isEmpty, reason: '실패하면 공유 폴더에 파일을 남기지 않는다');
  });

  test('저장은 고른 폴더로 복사하고 폴더 이름을 기록한다', () async {
    const folder = FolderRef(uri: 'content://tree/x', name: 'Docs');

    final outcome = await controller().save(OutputFormat.png, folder);

    expect(outcome, isA<MergeSucceeded>().having((o) => o.shared, 'shared', isFalse));
    expect(bridge.shareCalls, isEmpty);
    expect((await lastSession()).outputFolder, 'Docs');
  });

  test('이름은 YYYYMMDDHHMI_연번이고 이미지 수는 들어가지 않는다', () async {
    const folder = FolderRef(uri: 'default', name: 'Download');

    final outcome = await controller().save(OutputFormat.png, folder);

    final name = (outcome as MergeSucceeded).fileName;
    expect(name, matches(RegExp(r'^\d{12}_1\.png$')));
    expect(bridge.folders['default'], [name]);
  });

  test('시스템이 이름을 바꾸면 결과와 기록에 실제 이름을 쓴다', () async {
    const folder = FolderRef(uri: 'default', name: 'Download');
    bridge.renameOnCopy = (name) => name.replaceFirst('.png', ' (1).png');

    final outcome = await controller().save(OutputFormat.png, folder);

    final name = (outcome as MergeSucceeded).fileName;
    expect(name, matches(RegExp(r'^\d{12}_1 \(1\)\.png$')));
    final session = await lastSession();
    expect(session.outputName, name);
    expect(session.outputFolder, 'Download');
  });

  test('출력 설정이 합성에 들어간다: 기본은 A4 흰 바탕, 흑백을 고르면 네이티브로 넘긴다', () async {
    const folder = FolderRef(uri: 'content://tree/x', name: 'Docs');
    await controller().save(OutputFormat.png, folder);
    final defaultSession = await lastSession();
    // A4 세로 2페이지를 옆으로: 2480 + 구분선 7 + 2480. 가로형 이미지여도 방향은 용지 비율로 기록한다.
    expect((defaultSession.outputWidth, defaultSession.outputHeight), (4967, 3508));
    expect(defaultSession.direction, LayoutDirection.horizontal);
    expect(bridge.decodeCalls.first.grayscale, isFalse);

    container.read(outputSettingsProvider.notifier)
      ..setGrayscale(true)
      ..setOrientation(PaperOrientation.landscape);
    await controller().save(OutputFormat.png, folder);

    final changed = await lastSession();
    expect((changed.outputWidth, changed.outputHeight), (3508, 4967));
    expect(changed.direction, LayoutDirection.vertical);
    expect(bridge.decodeCalls.last.grayscale, isTrue);
  });

  test('용지당 이미지 수와 이미지 크기가 합성에 들어간다', () async {
    const folder = FolderRef(uri: 'content://tree/x', name: 'Docs');
    container.read(outputSettingsProvider.notifier)
      ..setImagesPerPaper(2)
      ..setImageSizePercent(50);
    await controller().save(OutputFormat.png, folder);

    // 2장이 한 페이지. 여백 124 안쪽 칸 폭 2232에 맞춘 400×200 → 2232×1116, 절반 1116×558
    final session = await lastSession();
    expect((session.outputWidth, session.outputHeight), (2480, 3508));
    expect(bridge.decodeCalls.last.width, 1116);
    expect(bridge.decodeCalls.last.height, 558);
  });

  test('여백 설정이 합성에 들어간다', () async {
    const folder = FolderRef(uri: 'content://tree/x', name: 'Docs');
    container.read(outputSettingsProvider.notifier).setMarginPercent(10);
    await controller().save(OutputFormat.png, folder);

    // 여백 248 안쪽 폭 1984에 맞춘 400×200 → 1984×992
    expect(bridge.decodeCalls.last.width, 1984);
    expect(bridge.decodeCalls.last.height, 992);

    container.read(outputSettingsProvider.notifier).setMarginPercent(0);
    await controller().save(OutputFormat.png, folder);

    // 여백이 없어 페이지 폭 2480에 맞춘다 → 2480×1240
    expect(bridge.decodeCalls.last.width, 2480);
    expect(bridge.decodeCalls.last.height, 1240);
  });

  test('공유 세션의 output_folder는 표식이고 화면에서만 옮긴다', () async {
    await controller().share(OutputFormat.png);

    final stored = (await database.db.query('sessions')).single['output_folder'];
    expect(stored, '공유');
  });

  test('공유 중 폴더 오류 코드도 MergeException으로 바뀐다', () async {
    bridge.shareError = 'folder_unavailable';

    final outcome = await controller().share(OutputFormat.png);

    expect(
      outcome,
      isA<MergeFailed>().having((o) => o.error.code, 'code', MergeErrorCode.folderUnavailable),
    );
  });
}
