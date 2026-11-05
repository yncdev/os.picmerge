import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_merger/core/app_info.dart';
import 'package:image_merger/core/crop_rect.dart';
import 'package:image_merger/core/platform/native_bridge.dart';

/// 네이티브 대신 Dart로 같은 계약(파일 형식, 오류 코드)을 흉내 낸다.
class FakeNativeBridge implements NativeBridge {
  FakeNativeBridge({this.cacheDirPath = ''});

  final String cacheDirPath;

  /// path → 오류 코드. scan·decodeRaw·encodeJpeg에서 던진다.
  final failures = <String, String>{};

  /// path → 오류 코드. encodeJpeg에서만 던진다 (헤더는 읽히는데 디코딩이 안 되는 파일).
  final failJpeg = <String, String>{};

  /// encodeJpeg가 돌려줄 크기를 바꾼다 (예산 초과 흉내). null이면 실제 파일 크기.
  int? Function(int width, int height, int quality)? reportedJpegBytes;

  /// decodeRaw를 부를 때마다 실행한다 (취소 시점 흉내).
  void Function(String path)? onDecode;

  final decodeCalls =
      <({String path, int width, int height, int channels, CropRect? crop, bool grayscale})>[];
  final jpegCalls =
      <({String path, int width, int height, int quality, CropRect? crop, bool grayscale})>[];

  /// pickPdfs가 돌려줄 URI.
  List<String> pickedPdfUris = const [];

  /// URI → 페이지 수. 없으면 pdfPageCount가 암호 PDF처럼 실패한다.
  final pdfPages = <String, int>{};

  /// 렌더링에 실패할 페이지 번호(0부터).
  final failPdfPages = <int>{};
  final _importedUris = <String, String>{};
  final renderCalls = <({int pageIndex, int dpi, int maxLongSide, int quality})>[];

  final shareCalls = <({String path, String mimeType, String name, bool fileExisted})>[];
  String? shareError;

  final folders = <String, List<String>>{};
  final copied = <String, Uint8List>{};
  bool folderOk = true;

  /// 접근할 수 없게 된 폴더.
  final inaccessibleUris = <String>{};

  /// null이면 기본 폴더가 없는 기기(Android 9 이하)다.
  FolderRef? defaultFolderRef = const FolderRef(uri: 'default', name: 'Download');

  /// 폴더 선택기가 돌려줄 값. null이면 사용자가 닫은 것이다.
  FolderRef? pickedFolder = const FolderRef(uri: 'content://tree/picked', name: 'Picked');

  /// 시스템이 저장하며 이름을 바꾸는 경우를 흉내 낸다 (MediaStore).
  String Function(String name)? renameOnCopy;

  /// 복사에서 던질 오류 코드.
  String? copyError;

  AppInfo appInfoResult = const AppInfo(
    versionName: '1.0.0',
    buildNumber: '1',
    manufacturer: 'samsung',
    model: 'SM-S938N',
    osName: 'Android',
    osVersion: '17',
  );

  /// composeEmail이 돌려줄 값. false면 메일 앱이 없는 것이다. 실제 메일 앱은 열지 않는다.
  bool composeEmailResult = true;

  /// composeEmail에서 던질 오류 코드.
  String? composeEmailError;
  final composeCalls = <({String to, String subject})>[];

  @override
  Future<String> cacheDir() async => cacheDirPath;

  @override
  Future<ImageHeader> scan(String path) async {
    final code = failures[path];
    if (code != null) throw PlatformException(code: code);
    return const ImageHeader(width: 100, height: 100, bytes: 1000, mime: 'image/jpeg');
  }

  @override
  Future<void> decodeRaw({
    required String path,
    required int width,
    required int height,
    required int channels,
    required String outPath,
    CropRect? crop,
    bool grayscale = false,
  }) async {
    decodeCalls.add(
      (path: path, width: width, height: height, channels: channels, crop: crop, grayscale: grayscale),
    );
    onDecode?.call(path);
    final code = failures[path];
    if (code != null) throw PlatformException(code: code);
    final value = path.codeUnits.fold<int>(0, (a, b) => a + b) % 256;
    File(outPath).writeAsBytesSync(Uint8List(width * height * channels)..fillRange(0, width * height * channels, value));
  }

  @override
  Future<int> encodeJpeg({
    required String path,
    required int width,
    required int height,
    required int quality,
    required String outPath,
    CropRect? crop,
    bool grayscale = false,
  }) async {
    jpegCalls.add(
      (path: path, width: width, height: height, quality: quality, crop: crop, grayscale: grayscale),
    );
    final code = failures[path] ?? failJpeg[path];
    if (code != null) throw PlatformException(code: code);
    final bytes = img.encodeJpg(img.Image(width: width, height: height), quality: quality);
    File(outPath).writeAsBytesSync(bytes);
    return reportedJpegBytes?.call(width, height, quality) ?? bytes.length;
  }

  @override
  Future<List<String>> pickPdfs() async => pickedPdfUris;

  @override
  Future<ImportedDocument> importDocument({required String uri, required String outPath}) async {
    File(outPath).writeAsStringSync('%PDF-fake');
    _importedUris[outPath] = uri;
    return ImportedDocument(name: uri.split('/').last, path: outPath);
  }

  @override
  Future<int> pdfPageCount(String path) async {
    final pages = pdfPages[_importedUris[path]];
    if (pages == null) throw PlatformException(code: 'unsupported_format', message: 'password');
    return pages;
  }

  @override
  Future<void> renderPdfPage({
    required String path,
    required int pageIndex,
    required int dpi,
    required int maxLongSide,
    required int quality,
    required String outPath,
  }) async {
    renderCalls.add((pageIndex: pageIndex, dpi: dpi, maxLongSide: maxLongSide, quality: quality));
    if (failPdfPages.contains(pageIndex)) throw PlatformException(code: 'corrupt_file');
    File(outPath).writeAsBytesSync(img.encodeJpg(img.Image(width: 20, height: 30)));
  }

  @override
  Future<void> shareFile({required String path, required String mimeType, required String name}) async {
    shareCalls.add((path: path, mimeType: mimeType, name: name, fileExisted: File(path).existsSync()));
    final code = shareError;
    if (code != null) throw PlatformException(code: code);
  }

  @override
  Future<FolderRef?> pickFolder() async => pickedFolder;

  @override
  Future<FolderRef?> defaultFolder() async => defaultFolderRef;

  @override
  Future<AppInfo> appInfo() async => appInfoResult;

  @override
  Future<bool> composeEmail({required String to, required String subject}) async {
    composeCalls.add((to: to, subject: subject));
    final code = composeEmailError;
    if (code != null) throw PlatformException(code: code);
    return composeEmailResult;
  }

  @override
  Future<({bool ok, String name})> checkFolder(String uri) async => (
        ok: folderOk && !inaccessibleUris.contains(uri),
        name: uri == defaultFolderRef?.uri ? defaultFolderRef!.name : 'Folder',
      );

  @override
  Future<List<String>> listNames(String uri, String prefix) async =>
      [for (final n in folders[uri] ?? const <String>[]) if (n.startsWith(prefix)) n];

  @override
  Future<SavedDocument> copyToFolder({
    required String uri,
    required String sourcePath,
    required String name,
    required String mimeType,
  }) async {
    if (!folderOk || inaccessibleUris.contains(uri)) throw PlatformException(code: 'folder_unavailable');
    final code = copyError;
    if (code != null) throw PlatformException(code: code);
    final actual = renameOnCopy?.call(name) ?? name;
    (folders[uri] ??= []).add(actual);
    copied[actual] = File(sourcePath).readAsBytesSync();
    return SavedDocument(name: actual, uri: '$uri/$actual');
  }
}
