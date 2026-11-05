import 'package:flutter_test/flutter_test.dart';
import 'package:image_merger/core/database/app_database.dart';
import 'package:image_merger/core/errors/merge_exception.dart';
import 'package:image_merger/features/image_merger/domain/layout_direction.dart';
import 'package:image_merger/features/image_merger/domain/output_format.dart';
import 'package:image_merger/features/session_history/data/session_repository.dart';
import 'package:image_merger/features/session_history/domain/session_record.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase database;
  late DateTime now;
  late SessionRepository repo;

  setUp(() async {
    sqfliteFfiInit();
    database = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    now = DateTime(2026, 10, 30, 12);
    repo = SessionRepository(database, clock: () => now);
  });
  tearDown(() => database.close());

  const images = [
    SessionImageInput(displayName: 'a.jpg', width: 4000, height: 3000, bytes: 100),
    SessionImageInput(displayName: 'b.jpg', width: 2000, height: 1500, bytes: 50),
  ];

  test('시작하면 running 세션과 이미지 행이 생기고, 성공하면 결과가 기록된다', () async {
    final id = await repo.start(format: OutputFormat.png, direction: LayoutDirection.vertical, images: images);
    expect((await repo.recent()).single.status, SessionStatus.running);

    await repo.finishSuccess(
      id,
      outputBytes: 1234,
      outputWidth: 2000,
      outputHeight: 3000,
      outputName: '20261030_1200_2images.png',
      outputFolder: 'Documents',
      appliedScales: [0.5, 1.0],
    );

    final record = (await repo.recent()).single;
    expect(record.status, SessionStatus.success);
    expect(record.direction, LayoutDirection.vertical);
    expect(record.outputName, '20261030_1200_2images.png');
    expect(record.imageCount, 2);
    final rows = await database.db.query('session_images', orderBy: 'position');
    expect([for (final r in rows) r['display_name']], ['a.jpg', 'b.jpg']);
    expect([for (final r in rows) r['applied_scale']], [0.5, 1.0]);
  });

  test('실패·취소는 상태와 오류 코드를 남긴다', () async {
    final failed = await repo.start(format: OutputFormat.pdf, direction: null, images: images);
    await repo.finishFailure(failed, MergeErrorCode.outOfSpace);
    final cancelled = await repo.start(format: OutputFormat.pdf, direction: null, images: images);
    await repo.finishCancelled(cancelled);

    final records = await repo.recent();
    final byId = {for (final r in records) r.id: r};
    expect(byId[failed]!.status, SessionStatus.failed);
    expect(byId[failed]!.errorCode, MergeErrorCode.outOfSpace);
    expect(byId[cancelled]!.status, SessionStatus.cancelled);
    expect(byId[cancelled]!.errorCode, isNull);
  });

  test('앱 시작 때 running으로 남은 세션을 crashed로 바꾼다', () async {
    await repo.start(format: OutputFormat.png, direction: LayoutDirection.horizontal, images: images);
    expect(await repo.markRunningAsCrashed(), 1);
    expect((await repo.recent()).single.status, SessionStatus.crashed);
    expect(await repo.markRunningAsCrashed(), 0);
  });

  test('성공률은 최근 30일, 진행 중은 빼고 취소·비정상 종료는 넣어 센다', () async {
    now = DateTime(2026, 9, 1); // 30일보다 오래된 기록
    await repo.finishFailure(await repo.start(format: OutputFormat.png, direction: null, images: images), MergeErrorCode.unknown);

    now = DateTime(2026, 10, 30, 12);
    for (var i = 0; i < 3; i++) {
      final id = await repo.start(format: OutputFormat.png, direction: null, images: images);
      await repo.finishSuccess(id, outputBytes: 1, outputName: 'x$i.png', outputFolder: 'D', appliedScales: const []);
    }
    await repo.finishCancelled(await repo.start(format: OutputFormat.png, direction: null, images: images));
    await repo.start(format: OutputFormat.png, direction: null, images: images);
    await repo.markRunningAsCrashed();
    await repo.start(format: OutputFormat.png, direction: null, images: images); // 진행 중

    final rate = await repo.successRate();
    expect((rate.success, rate.total), (3, 5));
  });

  test('최근 기록은 최신순, 최대 50건', () async {
    for (var i = 0; i < 55; i++) {
      now = DateTime(2026, 10, 1).add(Duration(hours: i));
      await repo.start(format: OutputFormat.png, direction: null, images: images);
    }
    final records = await repo.recent();
    expect(records.length, 50);
    expect(records.first.startedAt, DateTime(2026, 10, 1).add(const Duration(hours: 54)));
  });

  test('설정 저장·조회', () async {
    expect(await database.getSetting(AppDatabase.settingSaveTreeUri), isNull);
    await database.setSetting(AppDatabase.settingSaveTreeUri, 'content://a');
    await database.setSetting(AppDatabase.settingSaveTreeUri, 'content://b');
    expect(await database.getSetting(AppDatabase.settingSaveTreeUri), 'content://b');
  });
}
