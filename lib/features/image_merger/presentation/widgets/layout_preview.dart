import 'dart:io';

import 'package:flutter/material.dart';

import '../../../image_selection/domain/selected_image.dart';
import '../../domain/output_settings.dart';
import '../../domain/page_layout.dart';
import '../../domain/png_plan.dart';

/// 흑백 미리보기. Android 네이티브 회색조(saturation 0)와 같은 가중치다.
const _grayscale = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
]);

/// 썸네일로 그린 가벼운 미리보기. 실제 합성은 하지 않는다 (DESIGN §2.2).
/// 여백은 그리고 구분선은 그리지 않는다.
/// 용지를 고르면 페이지를 옆으로 넘겨 보고, '원본 크기'면 자동 결정된 방향으로 늘어놓는다.
class LayoutPreview extends StatelessWidget {
  const LayoutPreview({super.key, required this.images, required this.settings});

  final List<SelectedImage> images;
  final OutputSettings settings;

  @override
  Widget build(BuildContext context) {
    final paper = settings.paperDimensions;
    return paper == null
        ? _OriginalPreview(images: images, settings: settings)
        : _PagedPreview(images: images, paper: paper, settings: settings);
  }
}

Widget _thumbnail(SelectedImage image, {Key? key}) => Image.file(
      File(image.thumbnailPath),
      key: key,
      fit: BoxFit.fill,
      width: double.infinity,
      height: double.infinity,
      // 썸네일은 이미 작다(긴 변 512px). cacheWidth를 주면 목록이 바뀔 때마다 다시 디코딩한다.
      errorBuilder: (_, _, _) => const ColoredBox(color: Colors.black12),
    );

class _PagedPreview extends StatelessWidget {
  const _PagedPreview({required this.images, required this.paper, required this.settings});

  final List<SelectedImage> images;
  final PaperDimensions paper;
  final OutputSettings settings;

  static const _pageNumberHeight = 18.0;

  @override
  Widget build(BuildContext context) {
    final numberStyle = Theme.of(context).textTheme.labelSmall;
    return LayoutBuilder(
      builder: (context, constraints) {
        final pageHeight = constraints.maxHeight - _pageNumberHeight;
        final pageWidth = pageHeight * paper.aspectRatio;
        final sheets = layoutSheets(
          [for (final i in images) i.size],
          pageWidth: pageWidth,
          pageHeight: pageHeight,
          settings: settings,
        );
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: sheets.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final page = DecoratedBox(
              key: ValueKey('preview-page-$index'),
              // 테두리를 앞에 그려야 칸을 꽉 채운 이미지가 테두리를 덮지 않는다.
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(border: Border.all(color: Colors.black26)),
              child: ColoredBox(
                color: Colors.white,
                child: SizedBox(
                  width: pageWidth,
                  height: pageHeight,
                  child: Stack(
                    children: [
                      for (final placed in sheets[index])
                        Positioned(
                          left: placed.rect.left,
                          top: placed.rect.top,
                          width: placed.rect.width,
                          height: placed.rect.height,
                          child: _thumbnail(
                            images[placed.imageIndex],
                            key: ValueKey('preview-image-${placed.imageIndex}'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
            return Column(
              children: [
                if (settings.grayscale) ColorFiltered(colorFilter: _grayscale, child: page) else page,
                SizedBox(
                  height: _pageNumberHeight,
                  child: Center(child: Text('${index + 1}', style: numberStyle)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _OriginalPreview extends StatelessWidget {
  const _OriginalPreview({required this.images, required this.settings});

  final List<SelectedImage> images;
  final OutputSettings settings;

  @override
  Widget build(BuildContext context) {
    // 실제 PNG와 같은 계산을 줄여 그린다. 구분선 자리는 비워 둔다.
    final plan = planPng([for (final i in images) i.size], settings);
    return LayoutBuilder(
      builder: (context, constraints) {
        final frame = _fit(plan.canvasWidth / plan.canvasHeight, constraints.biggest);
        final scale = frame.width / plan.canvasWidth;
        final Widget arranged = ColoredBox(
          color: Colors.white,
          child: SizedBox(
            width: frame.width,
            height: frame.height,
            child: Stack(
              children: [
                for (var i = 0; i < images.length; i++)
                  Positioned(
                    left: plan.placements[i].x * scale,
                    top: plan.placements[i].y * scale,
                    width: plan.placements[i].width * scale,
                    height: plan.placements[i].height * scale,
                    child: _thumbnail(images[i], key: ValueKey('preview-image-$i')),
                  ),
              ],
            ),
          ),
        );
        return Center(
          child: DecoratedBox(
            key: const ValueKey('preview-original'),
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(border: Border.all(color: Colors.black26)),
            child: settings.grayscale
                ? ColorFiltered(colorFilter: _grayscale, child: arranged)
                : arranged,
          ),
        );
      },
    );
  }

  Size _fit(double aspect, Size box) {
    var width = box.width;
    var height = width / aspect;
    if (height > box.height) {
      height = box.height;
      width = height * aspect;
    }
    return Size(width, height);
  }
}
