import '../core/errors/merge_exception.dart';
import '../features/image_merger/domain/layout_direction.dart';
import '../features/image_merger/domain/output_settings.dart';
import '../features/session_history/domain/session_record.dart';
import 'app_localizations.dart';

/// Domain·Data의 코드를 화면 문구로 옮긴다. 그쪽에는 화면 문구를 두지 않는다 (DESIGN §3.1).
extension AppMessages on AppLocalizations {
  /// 오류 안내 (DESIGN §3.4). [imageNumber]는 1부터 센다.
  String mergeError(MergeErrorCode code, {int? imageNumber}) {
    final n = imageNumber;
    return switch (code) {
      MergeErrorCode.unsupportedFormat =>
        n == null ? errorUnsupportedFormat : errorUnsupportedFormatAt(n),
      MergeErrorCode.corruptFile => n == null ? errorCorruptFile : errorCorruptFileAt(n),
      MergeErrorCode.sourceUnavailable =>
        n == null ? errorSourceUnavailable : errorSourceUnavailableAt(n),
      MergeErrorCode.outOfSpace => errorOutOfSpace,
      MergeErrorCode.folderUnavailable => errorFolderUnavailable,
      MergeErrorCode.outputTooLarge => errorOutputTooLarge,
      MergeErrorCode.outOfMemory => errorOutOfMemory,
      MergeErrorCode.unknown => errorUnknown,
    };
  }

  String paperName(PaperSize paper) => paper.standardName ?? paperOriginal;

  String orientationName(PaperOrientation orientation) => switch (orientation) {
        PaperOrientation.portrait => orientationPortrait,
        PaperOrientation.landscape => orientationLandscape,
      };

  String autoDirection(LayoutDirection direction) => switch (direction) {
        LayoutDirection.vertical => autoDirectionVertical,
        LayoutDirection.horizontal => autoDirectionHorizontal,
      };

  String previewNote(LayoutDirection direction) => switch (direction) {
        LayoutDirection.vertical => previewNoteVertical,
        LayoutDirection.horizontal => previewNoteHorizontal,
      };

  String sessionStatus(SessionStatus status) => switch (status) {
        SessionStatus.running => statusRunning,
        SessionStatus.success => statusSuccess,
        SessionStatus.failed => statusFailed,
        SessionStatus.cancelled => statusCancelled,
        SessionStatus.crashed => statusCrashed,
      };

  /// DB의 `output_folder` 값을 화면 이름으로 옮긴다. 공유 표식만 번역하고 폴더 이름은 그대로다.
  String outputFolderName(String stored) => stored == kShareFolderSentinel ? share : stored;
}
