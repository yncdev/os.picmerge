import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/format.dart';
import '../../domain/selected_image.dart';
import '../crop_page.dart';
import '../selection_controller.dart';

/// 선택 목록. 순서는 드래그 앤 드롭으로만 바꾼다 (DESIGN §2.1.1).
class SelectionList extends ConsumerWidget {
  const SelectionList({super.key, required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = ref.watch(selectionProvider);
    final controller = ref.read(selectionProvider.notifier);
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: images.length,
      onReorderItem: (oldIndex, newIndex) {
        if (enabled) controller.reorder(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final image = images[index];
        return _SelectionTile(
          key: ValueKey(image.path),
          index: index,
          image: image,
          enabled: enabled,
          onRemove: () => controller.remove(image),
          onCrop: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => CropPage(image: image)),
          ),
        );
      },
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    super.key,
    required this.index,
    required this.image,
    required this.enabled,
    required this.onRemove,
    required this.onCrop,
  });

  final int index;
  final SelectedImage image;
  final bool enabled;
  final VoidCallback onRemove;
  final VoidCallback onCrop;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final l = AppLocalizations.of(context);
    return Material(
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 12, right: 4),
        leading: SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                // cover로 그리면 PDF 페이지는 가운데만 보여 빈 페이지처럼 보인다. 전체가 보이게 넣는다.
                child: ColoredBox(
                  color: Colors.black12,
                  child: Image.file(
                    File(image.thumbnailPath),
                    fit: BoxFit.contain,
                    cacheWidth: (56 * dpr).round(),
                    errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
              Positioned(
                left: 2,
                top: 2,
                child: _IndexBadge(number: index + 1),
              ),
            ],
          ),
        ),
        title: Text(image.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          image.crop == null
              ? '${image.width}×${image.height} · ${formatBytes(image.bytes)}'
              : l.croppedSize(image.size.width, image.size.height),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l.cropTitle,
              icon: Icon(
                Icons.crop,
                color: image.crop == null ? null : Theme.of(context).colorScheme.primary,
              ),
              onPressed: enabled ? onCrop : null,
            ),
            IconButton(
              tooltip: l.removeFromList,
              icon: const Icon(Icons.close),
              onPressed: enabled ? onRemove : null,
            ),
            if (enabled)
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.drag_handle),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.drag_handle, color: Colors.black26),
              ),
          ],
        ),
      ),
    );
  }
}

class _IndexBadge extends StatelessWidget {
  const _IndexBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$number',
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
