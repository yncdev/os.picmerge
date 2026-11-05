import 'package:flutter/services.dart';

import '../app_info.dart';
import '../crop_rect.dart';

/// 네이티브 헤더 스캔 결과. 크기는 EXIF 회전을 반영한 값이다.
class ImageHeader {
  const ImageHeader({
    required this.width,
    required this.height,
    required this.bytes,
    required this.mime,
  });

  final int width;
  final int height;
  final int bytes;
  final String mime;
}

/// 저장 폴더. [uri]는 앱에 불투명한 문자열이다: 고른 폴더는 영구 권한을 받은 위치이고,
/// 기본 폴더는 표식 `default`다 (DESIGN §2.1.4).
class FolderRef {
  const FolderRef({required this.uri, required this.name});

  final String uri;
  final String name;
}

class SavedDocument {
  const SavedDocument({required this.name, required this.uri});

  /// 실제로 저장된 이름. 시스템이 이름을 바꿀 수 있어 요청한 이름과 다를 수 있다.
  final String name;
  final String uri;
}

/// 앱 캐시로 복사한 문서.
class ImportedDocument {
  const ImportedDocument({required this.name, required this.path});

  final String name;
  final String path;
}

/// 플랫폼 채널. Android는 android/.../NativeImageBridge.kt·MainActivity.kt,
/// iOS는 ios/Runner/NativeImageBridge.swift·AppDelegate.swift가 같은 계약을 구현한다.
/// 메인 isolate에서만 호출한다. 네이티브 쪽은 백그라운드 스레드에서 실행된다 (DESIGN §3.1).
/// 실패하면 [PlatformException]을 던지고, 그 code는 DESIGN §3.4 오류 코드다.
class NativeBridge {
  const NativeBridge();

  static const _work = MethodChannel('image_merger/work');
  static const _ui = MethodChannel('image_merger/ui');

  Future<String> cacheDir() async => (await _work.invokeMethod<String>('cacheDir'))!;

  Future<ImageHeader> scan(String path) async {
    final m = (await _work.invokeMapMethod<String, Object?>('scan', {'path': path}))!;
    return ImageHeader(
      width: m['width']! as int,
      height: m['height']! as int,
      bytes: m['bytes']! as int,
      mime: m['mime']! as String,
    );
  }

  /// [path]의 [crop] 영역을 [width]×[height]로 축소·회전해 [outPath]에 raw 픽셀(행 단위, [channels]채널)로 쓴다.
  /// [channels]가 3이면 투명 영역을 흰색 위에 합친다.
  Future<void> decodeRaw({
    required String path,
    required int width,
    required int height,
    required int channels,
    required String outPath,
    CropRect? crop,
    bool grayscale = false,
  }) =>
      _work.invokeMethod<void>('decodeRaw', {
        'path': path,
        'width': width,
        'height': height,
        'channels': channels,
        'outPath': outPath,
        'crop': crop?.toChannelValue(),
        'grayscale': grayscale,
      });

  /// [path]의 [crop] 영역을 [width]×[height] JPEG로 [outPath]에 쓰고 파일 크기를 돌려준다.
  /// 투명 영역은 흰색으로 채운다.
  Future<int> encodeJpeg({
    required String path,
    required int width,
    required int height,
    required int quality,
    required String outPath,
    CropRect? crop,
    bool grayscale = false,
  }) async {
    final m = (await _work.invokeMapMethod<String, Object?>('encodeJpeg', {
      'path': path,
      'width': width,
      'height': height,
      'quality': quality,
      'outPath': outPath,
      'crop': crop?.toChannelValue(),
      'grayscale': grayscale,
    }))!;
    return m['bytes']! as int;
  }

  /// 문서 선택기로 PDF를 고른다. 고른 문서의 URI 목록을 돌려주고, 닫으면 빈 목록이다.
  Future<List<String>> pickPdfs() async =>
      await _ui.invokeListMethod<String>('pickPdfs') ?? const [];

  /// [uri] 문서를 [outPath]로 복사하고 표시 이름을 함께 돌려준다.
  Future<ImportedDocument> importDocument({required String uri, required String outPath}) async {
    final m = (await _work.invokeMapMethod<String, Object?>(
      'importDocument',
      {'uri': uri, 'outPath': outPath},
    ))!;
    return ImportedDocument(name: m['name']! as String, path: outPath);
  }

  /// 암호가 걸렸으면 unsupported_format, 손상됐으면 corrupt_file.
  Future<int> pdfPageCount(String path) async =>
      (await _work.invokeMethod<int>('pdfPageCount', {'path': path}))!;

  /// PDF 한 페이지를 [dpi] 기준(긴 변 [maxLongSide] 이하, 흰 배경) JPEG로 [outPath]에 쓴다.
  Future<void> renderPdfPage({
    required String path,
    required int pageIndex,
    required int dpi,
    required int maxLongSide,
    required int quality,
    required String outPath,
  }) =>
      _work.invokeMethod<void>('renderPdfPage', {
        'path': path,
        'pageIndex': pageIndex,
        'dpi': dpi,
        'maxLongSide': maxLongSide,
        'quality': quality,
        'outPath': outPath,
      });

  /// OS 공유 시트를 연다. 시트를 연 시점에 끝난다 (DESIGN §2.1.7).
  Future<void> shareFile({
    required String path,
    required String mimeType,
    required String name,
  }) =>
      _ui.invokeMethod<void>('shareFile', {'path': path, 'mimeType': mimeType, 'name': name});

  /// 설치된 앱과 기기 정보. iOS의 UIDevice는 메인 스레드에서 읽어야 해 화면 채널로 부른다.
  Future<AppInfo> appInfo() async {
    final m = (await _ui.invokeMapMethod<String, Object?>('appInfo'))!;
    return AppInfo(
      versionName: m['versionName']! as String,
      buildNumber: m['buildNumber']! as String,
      manufacturer: m['manufacturer']! as String,
      model: m['model']! as String,
      osName: m['osName']! as String,
      osVersion: m['osVersion']! as String,
    );
  }

  /// 기기의 메일 앱을 받는 사람과 제목만 채워 연다. 처리할 메일 앱이 없으면 false다.
  /// 내용은 사용자가 메일 앱에서 쓴다 (DESIGN §2.2).
  Future<bool> composeEmail({required String to, required String subject}) async =>
      await _ui.invokeMethod<bool>('composeEmail', {'to': to, 'subject': subject}) ?? false;

  /// 폴더 선택기를 띄운다. 사용자가 닫으면 null.
  Future<FolderRef?> pickFolder() async {
    final m = await _ui.invokeMapMethod<String, Object?>('pickFolder');
    if (m == null) return null;
    return FolderRef(uri: m['uri']! as String, name: m['name']! as String);
  }

  /// 폴더를 고르지 않아도 쓸 수 있는 기본 폴더. Android 10 이상은 Download, iOS는 앱 Documents다.
  /// 권한 없이 쓸 수 없는 Android 9 이하는 null이다 (DESIGN §2.1.4).
  Future<FolderRef?> defaultFolder() async {
    final m = await _work.invokeMapMethod<String, Object?>('defaultFolder');
    if (m == null) return null;
    return FolderRef(uri: m['uri']! as String, name: m['name']! as String);
  }

  Future<({bool ok, String name})> checkFolder(String uri) async {
    final m = (await _work.invokeMapMethod<String, Object?>('checkFolder', {'uri': uri}))!;
    return (ok: m['ok']! as bool, name: m['name']! as String);
  }

  Future<List<String>> listNames(String uri, String prefix) async =>
      await _work.invokeListMethod<String>('listNames', {'uri': uri, 'prefix': prefix}) ??
      const [];

  Future<SavedDocument> copyToFolder({
    required String uri,
    required String sourcePath,
    required String name,
    required String mimeType,
  }) async {
    final m = (await _work.invokeMapMethod<String, Object?>('copyToFolder', {
      'uri': uri,
      'sourcePath': sourcePath,
      'name': name,
      'mimeType': mimeType,
    }))!;
    return SavedDocument(name: m['name']! as String, uri: m['uri']! as String);
  }
}
