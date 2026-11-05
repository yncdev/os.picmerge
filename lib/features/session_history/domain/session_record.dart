import '../../../core/errors/merge_exception.dart';
import '../../image_merger/domain/layout_direction.dart';
import '../../image_merger/domain/output_format.dart';

/// 공유한 세션의 `output_folder` 값 (DESIGN §2.1.7). 언어와 무관한 DB 표식이라 바꾸지 않는다.
/// 이미 기록된 행과 맞아야 하고, 화면에는 기기 언어로 옮겨 보여준다.
const kShareFolderSentinel = '공유';

/// DESIGN §3.2 sessions.status
enum SessionStatus {
  running,
  success,
  failed,
  cancelled,
  crashed;

  static SessionStatus fromCode(String code) =>
      values.firstWhere((s) => s.name == code, orElse: () => failed);
}

/// 세션 = 저장 버튼을 한 번 누른 저장 시도 1회 (DESIGN §3.2).
class SessionRecord {
  const SessionRecord({
    required this.id,
    required this.startedAt,
    required this.status,
    required this.format,
    required this.imageCount,
    this.finishedAt,
    this.errorCode,
    this.direction,
    this.outputWidth,
    this.outputHeight,
    this.outputBytes,
    this.outputName,
    this.outputFolder,
  });

  factory SessionRecord.fromRow(Map<String, Object?> row) => SessionRecord(
        id: row['id']! as int,
        startedAt: DateTime.parse(row['started_at']! as String),
        finishedAt: switch (row['finished_at']) {
          final String s => DateTime.parse(s),
          _ => null,
        },
        status: SessionStatus.fromCode(row['status']! as String),
        errorCode: switch (row['error_code']) {
          final String c => MergeErrorCode.fromCode(c),
          _ => null,
        },
        format: OutputFormat.fromCode(row['output_format']! as String),
        direction: LayoutDirection.fromCode(row['direction'] as String?),
        imageCount: row['image_count']! as int,
        outputWidth: row['output_width'] as int?,
        outputHeight: row['output_height'] as int?,
        outputBytes: row['output_bytes'] as int?,
        outputName: row['output_name'] as String?,
        outputFolder: row['output_folder'] as String?,
      );

  final int id;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final SessionStatus status;
  final MergeErrorCode? errorCode;
  final OutputFormat format;
  final LayoutDirection? direction;
  final int imageCount;
  final int? outputWidth;
  final int? outputHeight;
  final int? outputBytes;
  final String? outputName;
  final String? outputFolder;
}

class SessionImageInput {
  const SessionImageInput({
    required this.displayName,
    required this.width,
    required this.height,
    required this.bytes,
  });

  final String displayName;
  final int width;
  final int height;
  final int bytes;
}

/// 최근 기록 시트 맨 위의 성공률 (DESIGN §2.2). 진행 중인 세션은 세지 않는다.
class SuccessRate {
  const SuccessRate({required this.success, required this.total});

  final int success;
  final int total;

  double? get ratio => total == 0 ? null : success / total;
}
