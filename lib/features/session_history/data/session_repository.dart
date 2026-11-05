import '../../../core/config/limits.dart';
import '../../../core/database/app_database.dart';
import '../../../core/errors/merge_exception.dart';
import '../../image_merger/domain/layout_direction.dart';
import '../../image_merger/domain/output_format.dart';
import '../domain/session_record.dart';

/// sessions, session_images 테이블 (DESIGN §3.2).
class SessionRepository {
  SessionRepository(this._database, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final DateTime Function() _clock;

  String _now() => _clock().toIso8601String();

  /// 저장을 시작할 때 `running` 세션과 이미지 행을 함께 만든다.
  Future<int> start({
    required OutputFormat format,
    required LayoutDirection? direction,
    required List<SessionImageInput> images,
  }) =>
      _database.db.transaction((txn) async {
        final id = await txn.insert('sessions', {
          'started_at': _now(),
          'status': SessionStatus.running.name,
          'output_format': format.extension,
          'direction': direction?.code,
          'image_count': images.length,
        });
        final batch = txn.batch();
        for (var i = 0; i < images.length; i++) {
          final image = images[i];
          batch.insert('session_images', {
            'session_id': id,
            'position': i,
            'display_name': image.displayName,
            'src_width': image.width,
            'src_height': image.height,
            'src_bytes': image.bytes,
          });
        }
        await batch.commit(noResult: true);
        return id;
      });

  Future<void> finishSuccess(
    int id, {
    required int outputBytes,
    required String outputName,
    required String outputFolder,
    required List<double> appliedScales,
    int? outputWidth,
    int? outputHeight,
  }) =>
      _database.db.transaction((txn) async {
        await txn.update(
          'sessions',
          {
            'finished_at': _now(),
            'status': SessionStatus.success.name,
            'output_width': outputWidth,
            'output_height': outputHeight,
            'output_bytes': outputBytes,
            'output_name': outputName,
            'output_folder': outputFolder,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        final batch = txn.batch();
        for (var i = 0; i < appliedScales.length; i++) {
          batch.update(
            'session_images',
            {'applied_scale': appliedScales[i]},
            where: 'session_id = ? AND position = ?',
            whereArgs: [id, i],
          );
        }
        await batch.commit(noResult: true);
      });

  Future<void> finishFailure(int id, MergeErrorCode code) => _finish(id, SessionStatus.failed, code);

  Future<void> finishCancelled(int id) => _finish(id, SessionStatus.cancelled, null);

  Future<void> _finish(int id, SessionStatus status, MergeErrorCode? code) => _database.db.update(
        'sessions',
        {'finished_at': _now(), 'status': status.name, 'error_code': code?.code},
        where: 'id = ?',
        whereArgs: [id],
      );

  /// 앱 시작 때 부른다. 강제 종료로 `running`에 남은 세션 수를 돌려준다 (DESIGN §3.4).
  Future<int> markRunningAsCrashed() => _database.db.update(
        'sessions',
        {'status': SessionStatus.crashed.name},
        where: 'status = ?',
        whereArgs: [SessionStatus.running.name],
      );

  Future<List<SessionRecord>> recent({int limit = kHistoryLimit}) async {
    final rows = await _database.db.query(
      'sessions',
      orderBy: 'started_at DESC, id DESC',
      limit: limit,
    );
    return [for (final row in rows) SessionRecord.fromRow(row)];
  }

  Future<SuccessRate> successRate({int days = kHistoryRateDays}) async {
    final since = _clock().subtract(Duration(days: days)).toIso8601String();
    final rows = await _database.db.rawQuery(
      '''SELECT
           SUM(CASE WHEN status = ? THEN 1 ELSE 0 END) AS success,
           COUNT(*) AS total
         FROM sessions
         WHERE started_at >= ? AND status != ?''',
      [SessionStatus.success.name, since, SessionStatus.running.name],
    );
    final row = rows.first;
    return SuccessRate(
      success: (row['success'] as int?) ?? 0,
      total: (row['total'] as int?) ?? 0,
    );
  }
}
