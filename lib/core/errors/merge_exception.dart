import 'package:flutter/services.dart';

/// DESIGN §3.4 오류 코드 표. [code]는 네이티브와 DB에 쓰는 문자열이다.
enum MergeErrorCode {
  unsupportedFormat('unsupported_format'),
  corruptFile('corrupt_file'),
  sourceUnavailable('source_unavailable'),
  outOfSpace('out_of_space'),
  folderUnavailable('folder_unavailable'),
  outputTooLarge('output_too_large'),
  outOfMemory('out_of_memory'),
  unknown('unknown');

  const MergeErrorCode(this.code);

  final String code;

  static MergeErrorCode fromCode(String? code) =>
      values.firstWhere((e) => e.code == code, orElse: () => unknown);
}

class MergeException implements Exception {
  const MergeException(this.code, {this.imageNumber, this.detail});

  /// 네이티브 오류를 앱 오류로 바꾼다. [imageNumber]는 1부터 센다.
  factory MergeException.fromPlatform(PlatformException e, {int? imageNumber}) =>
      MergeException(
        MergeErrorCode.fromCode(e.code),
        imageNumber: imageNumber,
        detail: e.message,
      );

  final MergeErrorCode code;
  final int? imageNumber;
  final String? detail;

  @override
  String toString() => 'MergeException(${code.code}, image: $imageNumber, $detail)';
}

/// 사용자가 취소함. 오류가 아니다 (DESIGN §3.4).
class MergeCancelled implements Exception {
  const MergeCancelled();
}
