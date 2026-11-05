import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/merge_exception.dart';
import '../../../core/platform/native_bridge.dart';
import '../../../core/providers.dart';
import '../../image_selection/presentation/selection_controller.dart';
import '../../session_history/domain/session_record.dart';
import '../data/merge_service.dart';
import '../domain/file_naming.dart';
import '../domain/layout_direction.dart';
import '../domain/output_format.dart';
import 'output_settings_controller.dart';

enum MergePhase { images, building, saving }

sealed class MergeState {
  const MergeState();
}

class MergeIdle extends MergeState {
  const MergeIdle();
}

class MergeRunning extends MergeState {
  const MergeRunning({
    required this.format,
    required this.phase,
    required this.total,
    this.isShare = false,
    this.completed = 0,
    this.cancelling = false,
  });

  final OutputFormat format;
  final MergePhase phase;
  final int completed;
  final int total;
  final bool isShare;
  final bool cancelling;

  /// '저장하는 중'에는 취소할 수 없다 (DESIGN §2.2).
  bool get canCancel => phase != MergePhase.saving && !cancelling;

  MergeRunning copyWith({MergePhase? phase, int? completed, bool? cancelling}) => MergeRunning(
        format: format,
        phase: phase ?? this.phase,
        total: total,
        isShare: isShare,
        completed: completed ?? this.completed,
        cancelling: cancelling ?? this.cancelling,
      );
}

sealed class MergeOutcome {
  const MergeOutcome();
}

class MergeSucceeded extends MergeOutcome {
  const MergeSucceeded({required this.fileName, required this.folderName, this.shared = false});

  final String fileName;
  final String folderName;
  final bool shared;
}

class MergeFailed extends MergeOutcome {
  const MergeFailed(this.error);

  final MergeException error;
}

class MergeWasCancelled extends MergeOutcome {
  const MergeWasCancelled();
}

/// 저장이나 공유 1회 = 세션 1개 (DESIGN §3.2). 합성 → 내보내기 → 기록까지 한다.
class MergeController extends Notifier<MergeState> {
  CancelToken? _token;

  @override
  MergeState build() => const MergeIdle();

  /// 합성해 [folder]로 복사한다.
  Future<MergeOutcome> save(OutputFormat format, FolderRef folder) => _run(
        format,
        isShare: false,
        deliver: (result, baseName) async {
          final saved = await ref.read(saveFolderRepositoryProvider).save(
                folder: folder,
                sourcePath: result.tempPath,
                baseName: baseName,
                format: format,
              );
          return MergeSucceeded(fileName: saved.name, folderName: folder.name);
        },
      );

  /// 합성해 OS 공유 시트를 연다 (DESIGN §2.1.7).
  Future<MergeOutcome> share(OutputFormat format) => _run(
        format,
        isShare: true,
        deliver: (result, baseName) async {
          final services = ref.read(appServicesProvider);
          // 공유 폴더는 공유할 때마다 비우므로 겹칠 이름이 없다.
          final name = resolveFileName(baseName, format.extension, const []);
          try {
            final path = await services.tempStorage.prepareShareFile(result.tempPath, name);
            try {
              await services.bridge.shareFile(path: path, mimeType: format.mimeType, name: name);
            } catch (_) {
              // 시트를 열지 못하면 받을 앱이 없으니 지운다 (DESIGN §3.4).
              await services.tempStorage.deleteQuietly(services.tempStorage.shareDir);
              rethrow;
            }
          } on PlatformException catch (e) {
            throw MergeException.fromPlatform(e);
          } on FileSystemException catch (e) {
            final noSpace = e.osError?.errorCode == 28; // ENOSPC
            throw MergeException(
              noSpace ? MergeErrorCode.outOfSpace : MergeErrorCode.unknown,
              detail: '$e',
            );
          }
          return MergeSucceeded(fileName: name, folderName: kShareFolderSentinel, shared: true);
        },
      );

  Future<MergeOutcome> _run(
    OutputFormat format, {
    required bool isShare,
    required Future<MergeSucceeded> Function(MergeResult result, String baseName) deliver,
  }) async {
    if (state is MergeRunning) throw StateError('already running');
    final images = List.of(ref.read(selectionProvider));
    final settings = ref.read(outputSettingsProvider);
    final services = ref.read(appServicesProvider);
    final sessions = ref.read(sessionRepositoryProvider);
    final token = _token = CancelToken();
    state = MergeRunning(
      format: format,
      phase: MergePhase.images,
      total: images.length,
      isShare: isShare,
    );

    int? sessionId;
    Directory? jobDir;
    try {
      final direction = format == OutputFormat.png
          ? pngDirection([for (final i in images) i.size], settings.paperDimensions)
          : null;
      sessionId = await sessions.start(
        format: format,
        direction: direction,
        images: [
          for (final i in images)
            SessionImageInput(
              displayName: i.displayName,
              width: i.width,
              height: i.height,
              bytes: i.bytes,
            ),
        ],
      );
      jobDir = await services.tempStorage.createJobDir();
      final result = await ref.read(mergeServiceProvider).merge(
            images: images,
            format: format,
            settings: settings,
            jobDir: jobDir,
            token: token,
            onProgress: (progress) => _onProgress(token, progress),
          );
      token.throwIfCancelled();

      // 여기부터는 취소할 수 없다.
      _token = null;
      state = (state as MergeRunning).copyWith(phase: MergePhase.saving);
      final outcome = await deliver(result, baseFileName(DateTime.now()));
      await _record(() => sessions.finishSuccess(
            sessionId!,
            outputBytes: result.bytes,
            outputWidth: result.width,
            outputHeight: result.height,
            outputName: outcome.fileName,
            outputFolder: outcome.folderName,
            appliedScales: result.appliedScales,
          ));
      return outcome;
    } on MergeCancelled {
      if (sessionId != null) await _record(() => sessions.finishCancelled(sessionId!));
      return const MergeWasCancelled();
    } on MergeException catch (e) {
      if (sessionId != null) await _record(() => sessions.finishFailure(sessionId!, e.code));
      return MergeFailed(e);
    } catch (e, stack) {
      debugPrint('merge failed: $e\n$stack');
      if (sessionId != null) {
        await _record(() => sessions.finishFailure(sessionId!, MergeErrorCode.unknown));
      }
      return MergeFailed(MergeException(MergeErrorCode.unknown, detail: '$e'));
    } finally {
      _token = null;
      // 오류·취소·성공 모두 작업 폴더(raw, JPEG, 결과 임시 파일)를 통째로 지운다.
      if (jobDir != null) await services.tempStorage.deleteQuietly(jobDir);
      state = const MergeIdle();
    }
  }

  void cancel() {
    final token = _token;
    final current = state;
    if (token == null || current is! MergeRunning || !current.canCancel) return;
    state = current.copyWith(cancelling: true);
    token.cancel();
  }

  void _onProgress(CancelToken token, MergeProgress progress) {
    final current = state;
    if (token.isCancelled || current is! MergeRunning) return;
    state = switch (progress) {
      ProcessingImages(:final completed) =>
        current.copyWith(phase: MergePhase.images, completed: completed),
      BuildingFile() => current.copyWith(phase: MergePhase.building),
    };
  }

  /// 기록 실패가 저장 결과를 가리지 않게 한다.
  Future<void> _record(Future<void> Function() write) async {
    try {
      await write();
    } catch (e) {
      debugPrint('session record failed: $e');
    }
  }
}

final mergeControllerProvider =
    NotifierProvider<MergeController, MergeState>(MergeController.new);
