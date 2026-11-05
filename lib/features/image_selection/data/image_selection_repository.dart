import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/limits.dart';
import '../../../core/crop_rect.dart';
import '../../../core/image_size.dart';
import '../../../core/platform/native_bridge.dart';
import '../../../core/storage/temp_storage.dart';
import '../domain/selected_image.dart';

class PickResult {
  const PickResult({required this.images, required this.unsupported, required this.overLimit});

  final List<SelectedImage> images;

  /// 헤더를 읽지 못했거나 디코딩할 수 없어 뺀 파일 수.
  final int unsupported;

  /// 상한을 넘어 뺀 항목 수 (picker가 상한을 무시했거나 PDF 페이지가 많은 경우).
  final int overLimit;
}

/// 입력을 고르고 헤더를 스캔한 뒤 썸네일을 만든다 (DESIGN §2.1.1).
class ImageSelectionRepository {
  ImageSelectionRepository({
    required this._bridge,
    required this._tempStorage,
    ImagePicker? picker,
    DateTime Function()? clock,
  })  : _picker = picker ?? ImagePicker(),
        _clock = clock ?? DateTime.now;

  final NativeBridge _bridge;
  final TempStorage _tempStorage;
  final ImagePicker _picker;
  final DateTime Function() _clock;

  /// Photo Picker로 여러 장을 고른다.
  Future<PickResult> pick({required int remaining}) async {
    final files = await _picker.pickMultiImage(limit: remaining, requestFullMetadata: false);
    final images = <SelectedImage>[];
    var unsupported = 0;
    var overLimit = 0;
    for (final file in files) {
      if (images.length >= remaining) {
        overLimit++;
        await _tempStorage.deletePickerCopy(file.path);
        continue;
      }
      final image = await _load(file.path, file.name);
      if (image == null) {
        // 고를 때 읽지 못한 파일은 목록에 넣지 않고, 세션 기록도 남기지 않는다.
        unsupported++;
        await _tempStorage.deletePickerCopy(file.path);
      } else {
        images.add(image);
      }
    }
    return PickResult(images: images, unsupported: unsupported, overLimit: overLimit);
  }

  /// 시스템 카메라로 찍어 1장을 추가한다. 찍지 않고 돌아오면 빈 결과다.
  /// 카메라를 쓸 수 없으면 [PlatformException]을 그대로 던진다.
  Future<PickResult> takePhoto() async {
    final file = await _picker.pickImage(source: ImageSource.camera, requestFullMetadata: false);
    if (file == null) return const PickResult(images: [], unsupported: 0, overLimit: 0);
    final image = await _load(file.path, _cameraName(_clock()));
    if (image == null) {
      await _tempStorage.deletePickerCopy(file.path);
      return const PickResult(images: [], unsupported: 1, overLimit: 0);
    }
    return PickResult(images: [image], unsupported: 0, overLimit: 0);
  }

  /// 문서 선택기로 PDF를 고르고 페이지마다 이미지 항목으로 펼친다 (DESIGN §2.1.1).
  /// [onProgress]는 만든 페이지 수와 만들 페이지 수를 알린다.
  Future<PickResult> pickPdfs({
    required int remaining,
    void Function(int done, int total)? onProgress,
  }) async {
    final uris = await _bridge.pickPdfs();
    final sources = <({ImportedDocument document, int pageCount})>[];
    var unsupported = 0;
    try {
      for (final uri in uris) {
        final sourcePath = await _tempStorage.newPdfSourcePath();
        try {
          final document = await _bridge.importDocument(uri: uri, outPath: sourcePath);
          sources.add((document: document, pageCount: await _bridge.pdfPageCount(sourcePath)));
        } on PlatformException {
          // 암호가 걸렸거나 열 수 없는 PDF.
          unsupported++;
          await _tempStorage.deleteQuietly(File(sourcePath));
        }
      }

      final totalPages = sources.fold(0, (sum, s) => sum + s.pageCount);
      final total = totalPages < remaining ? totalPages : remaining;
      final images = <SelectedImage>[];
      var done = 0;
      for (final source in sources) {
        for (var i = 0; i < source.pageCount && images.length < remaining; i++) {
          onProgress?.call(done, total);
          final image = await _loadPdfPage(source.document, i, source.pageCount);
          if (image == null) {
            unsupported++;
          } else {
            images.add(image);
          }
          done++;
        }
      }
      onProgress?.call(total, total);
      return PickResult(
        images: images,
        unsupported: unsupported,
        overLimit: totalPages > remaining ? totalPages - remaining : 0,
      );
    } finally {
      for (final source in sources) {
        await _tempStorage.deleteQuietly(File(source.document.path));
      }
    }
  }

  Future<SelectedImage?> _loadPdfPage(ImportedDocument document, int index, int pageCount) async {
    final pagePath = await _tempStorage.newPdfPagePath();
    try {
      await _bridge.renderPdfPage(
        path: document.path,
        pageIndex: index,
        dpi: kPdfRenderDpi,
        maxLongSide: kMaxInputLongSide,
        quality: kPdfRenderQuality,
        outPath: pagePath,
      );
    } on PlatformException {
      await _tempStorage.deleteQuietly(File(pagePath));
      return null;
    }
    final image = await _load(pagePath, '${document.name} (${index + 1}/$pageCount)');
    if (image == null) await _tempStorage.deleteQuietly(File(pagePath));
    return image;
  }

  Future<SelectedImage?> _load(String path, String displayName) async {
    String? thumbnailPath;
    try {
      final header = await _bridge.scan(path);
      final thumb = ImageSize(header.width, header.height).capLongSide(kThumbnailLongSide);
      thumbnailPath = await _tempStorage.newThumbnailPath();
      // 썸네일을 만들 수 없으면 합성 때도 디코딩할 수 없으므로 고를 때 뺀다.
      await _bridge.encodeJpeg(
        path: path,
        width: thumb.width,
        height: thumb.height,
        quality: kThumbnailQuality,
        outPath: thumbnailPath,
      );
      return SelectedImage(
        path: path,
        thumbnailPath: thumbnailPath,
        displayName: displayName,
        width: header.width,
        height: header.height,
        bytes: header.bytes,
        mime: header.mime,
      );
    } on PlatformException {
      if (thumbnailPath != null) await _tempStorage.deleteQuietly(File(thumbnailPath));
      return null;
    }
  }

  /// 영역 편집기에 쓸 임시 미리보기(긴 변 1600px, 전체 영역)를 만든다. 쓴 뒤 [discardPreview]로 지운다.
  Future<String> createCropPreview(SelectedImage image) async {
    final size = image.sourceSize.capLongSide(kCropPreviewLongSide);
    final path = await _tempStorage.newThumbnailPath();
    await _bridge.encodeJpeg(
      path: image.path,
      width: size.width,
      height: size.height,
      quality: kCropPreviewQuality,
      outPath: path,
    );
    return path;
  }

  Future<void> discardPreview(String path) => _tempStorage.deleteQuietly(File(path));

  /// 영역을 적용한 항목을 돌려준다. 썸네일을 새로 만들고 이전 썸네일은 지운다.
  /// 전체 영역이면 [SelectedImage.crop]을 null로 둔다.
  Future<SelectedImage> applyCrop(SelectedImage image, CropRect crop) async {
    final effective = crop.isFull ? null : crop;
    final size = (effective?.applyTo(image.sourceSize) ?? image.sourceSize)
        .capLongSide(kThumbnailLongSide);
    final thumbnailPath = await _tempStorage.newThumbnailPath();
    await _bridge.encodeJpeg(
      path: image.path,
      width: size.width,
      height: size.height,
      quality: kThumbnailQuality,
      outPath: thumbnailPath,
      crop: effective,
    );
    await _tempStorage.deleteQuietly(File(image.thumbnailPath));
    return image.withCrop(effective, thumbnailPath: thumbnailPath);
  }

  /// 목록에서 빠진 항목의 임시 파일(picker·카메라 복사본, PDF 페이지)과 썸네일을 지운다 (DESIGN §3.4).
  Future<void> discard(SelectedImage image) async {
    await _tempStorage.deletePickerCopy(image.path);
    await _tempStorage.deleteQuietly(File(image.thumbnailPath));
  }

  String _cameraName(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return 'camera_${t.year}${two(t.month)}${two(t.day)}_${two(t.hour)}${two(t.minute)}${two(t.second)}.jpg';
  }
}
