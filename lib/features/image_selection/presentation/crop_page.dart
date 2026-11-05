import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/crop_rect.dart';
import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme.dart';
import '../data/image_selection_repository.dart';
import '../domain/selected_image.dart';
import 'selection_controller.dart';

/// 항목별 영역 편집 화면 (DESIGN §2.1.6). 사각형 자르기만 한다.
class CropPage extends ConsumerStatefulWidget {
  const CropPage({super.key, required this.image});

  final SelectedImage image;

  @override
  ConsumerState<CropPage> createState() => _CropPageState();
}

class _CropPageState extends ConsumerState<CropPage> {
  /// dispose에서는 ref를 쓸 수 없어 미리 잡아 둔다.
  late final ImageSelectionRepository _repo = ref.read(imageSelectionRepositoryProvider);
  late CropRect _crop = widget.image.crop ?? CropRect.full;
  String? _previewPath;
  var _failed = false;
  var _applying = false;

  /// 끄는 중인 부위. null이면 사각형 밖을 끌고 있어 무시한다.
  CropHandle? _handle;

  /// 손가락에서 이만큼 안이면 모서리·변을 잡은 것으로 본다.
  static const _touchTolerance = 28.0;

  /// 편집 영역 위아래 여백.
  static const _verticalMargin = 20.0;

  /// 좌우 여백의 최솟값. Android 뒤로 가기 제스처 구역은 설정에 따라 최대 48dp이고,
  /// Flutter가 이 구역을 0으로 보고하는 기기가 있어(에뮬레이터 Android 14에서 확인) 보고값만 믿지 않는다.
  static const _minSideMargin = 48.0;

  /// 시스템이 제스처 구역을 알려 줄 때 그 바깥으로 더 두는 여유.
  static const _gestureClearance = 24.0;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    try {
      final path = await _repo.createCropPreview(widget.image);
      if (!mounted) {
        await _repo.discardPreview(path);
        return;
      }
      setState(() => _previewPath = path);
    } on PlatformException {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    final path = _previewPath;
    if (path != null) _repo.discardPreview(path);
    super.dispose();
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context);
    try {
      await ref.read(selectionProvider.notifier).applyCrop(widget.image, _crop);
      if (mounted) Navigator.of(context).pop();
    } on PlatformException {
      messenger.showSnackBar(SnackBar(content: Text(l.errorApplyCrop)));
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = _previewPath;
    final ready = path != null && !_applying;
    final l = AppLocalizations.of(context);
    // 적용 중에 뒤로 가면 끝난 뒤 메인 화면까지 닫혀 빈 화면이 된다.
    return PopScope(
      canPop: !_applying,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: navBarOverlayStyle(context, background: Colors.black),
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: Text(l.cropTitle),
            leading: IconButton(
              tooltip: l.cancel,
              icon: const Icon(Icons.close),
              onPressed: _applying ? null : () => Navigator.pop(context),
            ),
            actions: [TextButton(onPressed: ready ? _apply : null, child: Text(l.cropApply))],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(child: _buildEditor(path)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: ready ? () => setState(() => _crop = CropRect.full) : null,
                    icon: const Icon(Icons.fullscreen),
                    label: Text(l.cropSelectAll),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 편집 영역 바깥 여백. 손잡이가 화면 끝의 뒤로 가기 제스처 구역에 있으면 끌기가 앱까지 오지 않는다.
  EdgeInsets _editorMargin(BuildContext context) {
    final gestures = MediaQuery.systemGestureInsetsOf(context);
    return EdgeInsets.fromLTRB(
      math.max(_minSideMargin, gestures.left + _gestureClearance),
      _verticalMargin,
      math.max(_minSideMargin, gestures.right + _gestureClearance),
      _verticalMargin,
    );
  }

  Widget _buildEditor(String? path) {
    if (_failed) {
      return Center(
        child: Text(
          AppLocalizations.of(context).errorOpenImage,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }
    if (path == null) return const Center(child: CircularProgressIndicator());
    final aspect = widget.image.sourceSize.aspectRatio;
    final margin = _editorMargin(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = margin.deflateSize(constraints.biggest);
        var width = available.width;
        var height = width / aspect;
        if (height > available.height) {
          height = available.height;
          width = height * aspect;
        }
        final origin = Offset(
          margin.left + (available.width - width) / 2,
          margin.top + (available.height - height) / 2,
        );
        // 손잡이는 이미지 경계 밖까지 그려진다. 감지 영역을 이미지 크기로 두면 경계 밖을 누를 때 잡히지 않아
        // 편집 화면 전체에서 받고 이미지 기준 좌표로 바꾼다.
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) {
            final p = d.localPosition - origin;
            _handle = cropHandleAt(
              _crop,
              p.dx / width,
              p.dy / height,
              _touchTolerance / width,
              _touchTolerance / height,
            );
          },
          onPanUpdate: (d) {
            final handle = _handle;
            if (handle == null) return;
            setState(() {
              _crop = _crop.drag(handle, d.delta.dx / width, d.delta.dy / height);
            });
          },
          onPanEnd: (_) => _handle = null,
          child: Stack(
            children: [
              Positioned(
                key: const ValueKey('crop-area'),
                left: origin.dx,
                top: origin.dy,
                width: width,
                height: height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(path), fit: BoxFit.fill),
                    CustomPaint(painter: _CropPainter(_crop)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CropPainter extends CustomPainter {
  const _CropPainter(this.crop);

  final CropRect crop;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(
      crop.left * size.width,
      crop.top * size.height,
      crop.right * size.width,
      crop.bottom * size.height,
    );
    final shade = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRect(rect),
    );
    canvas.drawPath(shade, Paint()..color = Colors.black54);
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
    final grip = Paint()..color = Colors.white;
    const r = 7.0;
    for (final p in [
      rect.topLeft,
      rect.topCenter,
      rect.topRight,
      rect.centerRight,
      rect.bottomRight,
      rect.bottomCenter,
      rect.bottomLeft,
      rect.centerLeft,
    ]) {
      canvas.drawCircle(p, r, grip);
    }
  }

  @override
  bool shouldRepaint(_CropPainter oldDelegate) => oldDelegate.crop != crop;
}
