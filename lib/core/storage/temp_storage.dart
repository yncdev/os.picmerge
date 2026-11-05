import 'dart:io';

import 'package:path/path.dart' as p;

/// 앱 캐시 안의 임시 파일 관리 (DESIGN §3.4).
class TempStorage {
  TempStorage(this.cacheDirPath);

  final String cacheDirPath;

  /// image_picker_android는 고른 파일을 `cacheDir/<UUID>/원본이름`에 복사한다.
  static final _pickerDirName = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  );

  /// 폴더 없이 캐시에 바로 생기는 파일. Android 카메라는 `cacheDir/<UUID><난수>.jpg`,
  /// iOS image_picker는 임시 폴더의 `image_picker_<GUID>…`다.
  static final _pickerFileName = RegExp(
    r'^(image_picker_.*|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}.*\.jpg)$',
  );

  Directory get workDir => Directory(p.join(cacheDirPath, 'merge_tmp'));

  /// 선택 목록 썸네일. 목록에서 빠질 때 지운다.
  Directory get thumbnailDir => Directory(p.join(cacheDirPath, 'thumbs'));

  /// PDF 페이지를 이미지로 만든 파일. 항목이 목록에서 빠질 때 지운다.
  Directory get pdfPageDir => Directory(p.join(cacheDirPath, 'pdf_pages'));

  /// 고른 PDF의 복사본. 페이지를 다 만들면 지운다.
  Directory get pdfSourceDir => Directory(p.join(cacheDirPath, 'pdf_src'));

  /// 공유 시트에 넘긴 결과 파일. 받는 앱이 나중에 읽을 수 있어 다음 공유나 앱 시작 때 지운다.
  Directory get shareDir => Directory(p.join(cacheDirPath, 'share'));

  var _thumbnailSeq = 0;
  var _pdfSeq = 0;

  Future<String> newThumbnailPath() async {
    await thumbnailDir.create(recursive: true);
    return p.join(
      thumbnailDir.path,
      'thumb_${DateTime.now().microsecondsSinceEpoch}_${_thumbnailSeq++}.jpg',
    );
  }

  Future<String> newPdfPagePath() async {
    await pdfPageDir.create(recursive: true);
    return p.join(
      pdfPageDir.path,
      'page_${DateTime.now().microsecondsSinceEpoch}_${_pdfSeq++}.jpg',
    );
  }

  Future<String> newPdfSourcePath() async {
    await pdfSourceDir.create(recursive: true);
    return p.join(
      pdfSourceDir.path,
      'src_${DateTime.now().microsecondsSinceEpoch}_${_pdfSeq++}.pdf',
    );
  }

  /// [sourcePath]를 공유 폴더의 [name]으로 옮긴다. 지난 공유 파일은 지운다.
  Future<String> prepareShareFile(String sourcePath, String name) async {
    await deleteQuietly(shareDir);
    await shareDir.create(recursive: true);
    final target = p.join(shareDir.path, name);
    try {
      await File(sourcePath).copy(target);
    } on FileSystemException {
      await deleteQuietly(shareDir); // 쓰다 만 파일을 남기지 않는다 (DESIGN §3.4).
      rethrow;
    }
    return target;
  }

  /// 저장 1회(세션)용 작업 폴더. 끝나면 [deleteQuietly]로 통째로 지운다.
  Future<Directory> createJobDir() async {
    final dir = Directory(
      p.join(workDir.path, DateTime.now().microsecondsSinceEpoch.toString()),
    );
    return dir.create(recursive: true);
  }

  /// 앱 시작 때 호출한다. 강제 종료로 남은 작업 폴더, 썸네일, PDF 페이지, 공유 파일,
  /// picker·카메라 복사본을 지운다.
  Future<void> cleanupLeftovers() async {
    await deleteQuietly(workDir);
    await deleteQuietly(thumbnailDir);
    await deleteQuietly(pdfPageDir);
    await deleteQuietly(pdfSourceDir);
    await deleteQuietly(shareDir);
    final cache = Directory(cacheDirPath);
    if (!await cache.exists()) return;
    await for (final entity in cache.list(followLinks: false)) {
      final name = p.basename(entity.path);
      // `-Inbox`는 iOS 문서 선택기가 복사본을 두는 임시 폴더다. 가져오기 전에 앱이 꺼지면 남는다.
      final leftover = entity is Directory
          ? _pickerDirName.hasMatch(name) || name.endsWith('-Inbox')
          : entity is File && _pickerFileName.hasMatch(name);
      if (leftover) await deleteQuietly(entity);
    }
  }

  /// picker 복사본과, 비었으면 그 UUID 폴더를 지운다.
  Future<void> deletePickerCopy(String path) async {
    final file = File(path);
    await deleteQuietly(file);
    final parent = file.parent;
    if (_pickerDirName.hasMatch(p.basename(parent.path)) &&
        p.equals(parent.parent.path, cacheDirPath)) {
      try {
        await parent.delete(); // 비어 있지 않으면 실패하고 그대로 둔다.
      } on FileSystemException {
        // 무시
      }
    }
  }

  Future<void> deleteQuietly(FileSystemEntity entity) async {
    try {
      if (await entity.exists()) await entity.delete(recursive: true);
    } on FileSystemException {
      // 정리 실패는 다음 시작 때 다시 시도한다.
    }
  }
}
