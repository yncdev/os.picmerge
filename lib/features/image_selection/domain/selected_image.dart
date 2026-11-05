import '../../../core/crop_rect.dart';
import '../../../core/image_size.dart';

/// 선택 목록의 항목 하나. [path]는 앱 캐시의 임시 파일이다:
/// picker·카메라 복사본이거나, PDF 페이지를 이미지로 만든 JPEG다 (DESIGN §2.1.1).
class SelectedImage {
  const SelectedImage({
    required this.path,
    required this.thumbnailPath,
    required this.displayName,
    required this.width,
    required this.height,
    required this.bytes,
    required this.mime,
    this.crop,
  });

  final String path;

  /// 긴 변 512px JPEG (EXIF 회전 반영). 화면에는 원본 대신 이것만 그린다.
  final String thumbnailPath;
  final String displayName;

  /// EXIF 회전을 반영한 원본 크기.
  final int width;
  final int height;
  final int bytes;
  final String mime;

  /// 영역 편집 결과. null이면 전체를 쓴다 (DESIGN §2.1.6).
  final CropRect? crop;

  ImageSize get sourceSize => ImageSize(width, height);

  /// 영역 편집을 반영한 크기. 방향·레이아웃 계산은 모두 이 값으로 한다.
  ImageSize get size => crop?.applyTo(sourceSize) ?? sourceSize;

  /// [crop]은 null도 뜻이 있어(전체 선택) 일반 copyWith로 받지 않는다.
  SelectedImage withCrop(CropRect? crop, {required String thumbnailPath}) => SelectedImage(
        path: path,
        thumbnailPath: thumbnailPath,
        displayName: displayName,
        width: width,
        height: height,
        bytes: bytes,
        mime: mime,
        crop: crop,
      );

  /// PNG·WebP만 투명 픽셀을 가질 수 있다고 본다 (DESIGN §3.1 캔버스 채널 수).
  bool get mayHaveAlpha => mime == 'image/png' || mime == 'image/webp';
}
