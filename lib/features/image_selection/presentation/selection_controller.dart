import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/limits.dart';
import '../../../core/crop_rect.dart';
import '../../../core/providers.dart';
import '../data/image_selection_repository.dart';
import '../domain/selected_image.dart';

class AddImagesResult {
  const AddImagesResult({required this.added, required this.unsupported, required this.overLimit});

  final int added;
  final int unsupported;
  final int overLimit;
}

/// 선택 목록 (DESIGN §2.1.1). 저장에 성공해도 비우지 않는다.
class SelectionController extends Notifier<List<SelectedImage>> {
  @override
  List<SelectedImage> build() => const [];

  int get remaining => kMaxImages - state.length;

  ImageSelectionRepository get _repo => ref.read(imageSelectionRepositoryProvider);

  /// Photo Picker로 사진을 고른다.
  Future<AddImagesResult> addImages() async {
    if (remaining <= 0) return const AddImagesResult(added: 0, unsupported: 0, overLimit: 0);
    return _accept(await _repo.pick(remaining: remaining));
  }

  /// 시스템 카메라로 찍어 추가한다.
  Future<AddImagesResult> addFromCamera() async {
    if (remaining <= 0) return const AddImagesResult(added: 0, unsupported: 0, overLimit: 0);
    return _accept(await _repo.takePhoto());
  }

  /// PDF를 고르고 페이지마다 항목으로 펼친다.
  Future<AddImagesResult> addPdfs({void Function(int done, int total)? onProgress}) async {
    if (remaining <= 0) return const AddImagesResult(added: 0, unsupported: 0, overLimit: 0);
    return _accept(await _repo.pickPdfs(remaining: remaining, onProgress: onProgress));
  }

  Future<AddImagesResult> _accept(PickResult result) async {
    // picker가 열린 사이에 목록이 바뀌었을 수 있으니 다시 자른다.
    final room = remaining;
    final accepted = result.images.take(room).toList();
    final dropped = result.images.skip(room).toList();
    for (final image in dropped) {
      await _repo.discard(image);
    }
    state = [...state, ...accepted];
    return AddImagesResult(
      added: accepted.length,
      unsupported: result.unsupported,
      overLimit: result.overLimit + dropped.length,
    );
  }

  /// 영역 편집 결과를 항목에 반영한다 (DESIGN §2.1.6).
  Future<void> applyCrop(SelectedImage image, CropRect crop) async {
    final updated = await _repo.applyCrop(image, crop);
    state = [
      for (final i in state)
        if (i.path == image.path) updated else i,
    ];
  }

  /// ReorderableListView.onReorderItem: [newIndex]는 이미 보정된 값이다.
  void reorder(int oldIndex, int newIndex) {
    final list = [...state];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
  }

  Future<void> remove(SelectedImage image) async {
    state = [
      for (final i in state)
        if (i.path != image.path) i,
    ];
    await _repo.discard(image);
  }

  Future<void> clear() async {
    final removed = state;
    state = const [];
    final repo = _repo;
    for (final image in removed) {
      await repo.discard(image);
    }
  }
}

final selectionProvider =
    NotifierProvider<SelectionController, List<SelectedImage>>(SelectionController.new);
