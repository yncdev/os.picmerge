import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/limits.dart';
import '../../../core/errors/merge_exception.dart';
import '../../../core/platform/native_bridge.dart';
import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_messages.dart';
import '../../../shared/theme.dart';
import '../../about/presentation/about_page.dart';
import '../../about/presentation/app_drawer.dart';
import '../../about/presentation/send_feedback.dart';
import '../../image_selection/domain/selected_image.dart';
import '../../image_selection/presentation/selection_controller.dart';
import '../../image_selection/presentation/widgets/selection_list.dart';
import '../../session_history/presentation/history_sheet.dart';
import '../domain/layout_direction.dart';
import '../domain/output_format.dart';
import '../domain/output_settings.dart';
import '../domain/page_layout.dart';
import 'merge_controller.dart';
import 'output_settings_controller.dart';
import 'save_folder_controller.dart';
import 'widgets/layout_preview.dart';
import 'widgets/progress_overlay.dart';

/// 메인 화면 (DESIGN §2.2).
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  /// 저장 버튼은 MergeRunning이 된 뒤에야 비활성화된다. 그 전(폴더 확인·선택 중)의 두 번 탭을 막는다.
  var _saving = false;

  /// 고른 뒤 헤더 스캔·썸네일·PDF 페이지 생성 중.
  var _adding = false;

  /// PDF 페이지를 만드는 진행률. 페이지 수를 모르면 null.
  double? _addProgress;

  /// 이 높이보다 본문이 낮으면 미리보기를 접어 목록 자리를 지킨다. 가로로 든 폰(본문 약 260dp 이하)만 해당하고,
  /// 세로로 든 작은 폰(360×640, 상태·내비게이션 바 포함 약 410dp)에는 미리보기가 그대로 있다.
  static const _minBodyHeightForPreview = 340.0;

  /// 목록 머리글(48)과 목록 한 줄(72)과 목록 아래 여백(8)의 높이. 설정이 여러 줄로 접히는 긴 언어에서도
  /// 이만큼은 남기고, 넘치는 미리보기와 설정은 그 안에서 스크롤한다.
  /// 낮은 화면에서는 본문의 40%까지는 위쪽에 준다.
  static const _minListHeight = 128.0;
  static const _minTopShareOfBody = 0.4;

  /// 작은 폰에서 설정의 끝이 잘릴 때 더 있다는 것을 스크롤바로 보여 준다.
  final _topScroll = ScrollController();

  @override
  void dispose() {
    _topScroll.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (ref.read(appServicesProvider).crashedSessions > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showCrashNotice());
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = ref.watch(selectionProvider);
    final merge = ref.watch(mergeControllerProvider);
    final folder = ref.watch(saveFolderProvider);
    final running = merge is MergeRunning || _saving || _adding;
    final colors = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);

    return PopScope(
      canPop: !running,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              scrolledUnderElevation: 0,
              leading: Builder(
                builder: (context) => IconButton(
                  tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
                  icon: const Icon(Icons.menu),
                  color: colors.onPrimary,
                  disabledColor: colors.onPrimary.withValues(alpha: 0.5),
                  onPressed: running ? null : Scaffold.of(context).openDrawer,
                ),
              ),
              title: const _AppTitle(),
              bottom: _adding
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(4),
                      child: LinearProgressIndicator(
                        value: _addProgress,
                        color: colors.onPrimary,
                        backgroundColor: colors.onPrimary.withValues(alpha: 0.3),
                      ),
                    )
                  : null,
              actions: [
                IconButton(
                  tooltip: l.recentHistory,
                  icon: const Icon(Icons.history),
                  color: colors.onPrimary,
                  disabledColor: colors.onPrimary.withValues(alpha: 0.5),
                  onPressed: running ? null : () => showHistorySheet(context),
                ),
              ],
            ),
            // 저장 중에는 메뉴를 열지 못한다 (DESIGN §2.2).
            drawerEnableOpenDragGesture: !running,
            drawer: AppDrawer(
              onAbout: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AboutPage()),
              ),
              onFeedback: () => sendFeedback(context, ref.read(appServicesProvider).bridge),
            ),
            // 가로 모드의 3버튼 바는 옆에 있어 본문이 그 아래로 들어가지 않게 한다.
            body: SafeArea(
              top: false,
              bottom: false,
              child: images.isEmpty
                  ? _EmptyState(
                      onPickPhotos: running ? null : _addPhotos,
                      onPickPdfs: running ? null : _addPdfs,
                      onCamera: running ? null : _addFromCamera,
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: math.max(
                                constraints.maxHeight * _minTopShareOfBody,
                                constraints.maxHeight - _minListHeight,
                              ),
                            ),
                            child: Scrollbar(
                              controller: _topScroll,
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                controller: _topScroll,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (constraints.maxHeight >= _minBodyHeightForPreview)
                                      _PreviewCard(images: images),
                                    _OutputSettingsBar(enabled: !running),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          _ListHeader(
                            count: images.length,
                            onPickPhotos: running || images.length >= kMaxImages ? null : _addPhotos,
                            onPickPdfs: running || images.length >= kMaxImages ? null : _addPdfs,
                            onCamera: running || images.length >= kMaxImages ? null : _addFromCamera,
                            onClear: running ? null : _confirmClear,
                          ),
                          const Divider(height: 1),
                          Expanded(child: SelectionList(enabled: !running)),
                        ],
                      ),
                    ),
            ),
            bottomNavigationBar: _SaveBar(
              folder: folder,
              imageCount: images.length,
              enabled: !running,
              onChangeFolder: _changeFolder,
              onSave: _save,
              onShare: _chooseShareFormat,
            ),
          ),
          if (merge is MergeRunning)
            ProgressOverlay(
              state: merge,
              onCancel: () => ref.read(mergeControllerProvider.notifier).cancel(),
            ),
        ],
      ),
    );
  }

  Future<void> _addPhotos() => _add(
        (controller) => controller.addImages(),
        failureMessage: AppLocalizations.of(context).errorLoadPhotos,
      );

  Future<void> _addFromCamera() => _add(
        (controller) => controller.addFromCamera(),
        failureMessage: AppLocalizations.of(context).errorCameraUnavailable,
      );

  Future<void> _addPdfs() => _add(
        (controller) => controller.addPdfs(
          onProgress: (done, total) {
            if (mounted && total > 0) setState(() => _addProgress = done / total);
          },
        ),
        failureMessage: AppLocalizations.of(context).errorLoadPdfs,
      );

  Future<void> _add(
    Future<AddImagesResult> Function(SelectionController controller) add, {
    required String failureMessage,
  }) async {
    final controller = ref.read(selectionProvider.notifier);
    final l = AppLocalizations.of(context);
    if (controller.remaining <= 0) {
      _snack(l.maxImagesReached(kMaxImages));
      return;
    }
    setState(() {
      _adding = true;
      _addProgress = null;
    });
    try {
      final result = await add(controller);
      if (result.unsupported > 0) {
        _snack(l.unsupportedFilesExcluded(result.unsupported));
      }
      if (result.overLimit > 0) {
        _snack(l.overLimitAdded(kMaxImages, result.added));
      }
    } on PlatformException {
      _snack(failureMessage);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _confirmClear() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l.clearConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l.clearList)),
        ],
      ),
    );
    if (ok == true) await ref.read(selectionProvider.notifier).clear();
  }

  /// 폴더 변경 창 (DESIGN §2.1.4). 바꾼 폴더를 돌려주고, 취소하면 null이다.
  /// [inaccessible]이면 고른 폴더에 접근할 수 없게 되었다고 함께 알린다.
  Future<FolderRef?> _changeFolder({bool inaccessible = false}) async {
    final controller = ref.read(saveFolderProvider.notifier);
    final l = AppLocalizations.of(context);
    FolderRef? defaultFolder;
    try {
      defaultFolder = await controller.defaultFolder();
    } on PlatformException {
      defaultFolder = null;
    }
    if (!mounted) return null;
    final current = ref.read(saveFolderProvider);
    final action = await showDialog<_FolderAction>(
      context: context,
      builder: (context) => _FolderDialog(
        current: current,
        offeredDefault: defaultFolder?.uri == current?.uri ? null : defaultFolder,
        inaccessible: inaccessible,
      ),
    );
    if (!mounted) return null;
    try {
      return switch (action) {
        _FolderAction.useDefault => await controller.useDefault(),
        _FolderAction.pick => await controller.pick(),
        null => null,
      };
    } on PlatformException {
      _snack(l.errorPickFolder);
      return null;
    }
  }

  Future<void> _save(OutputFormat format) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _saveOnce(format);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveOnce(OutputFormat format) async {
    final folderController = ref.read(saveFolderProvider.notifier);
    final l = AppLocalizations.of(context);
    FolderRef? folder;
    try {
      // 합성을 시작하기 전에 폴더 접근을 확인한다 (DESIGN §2.1.4).
      folder = await folderController.ensureAccessible();
    } on PlatformException {
      folder = null;
    }
    if (!mounted) return;
    // 폴더가 아예 없으면(Android 9 이하의 첫 저장) 고르게 하고, 고른 폴더를 잃었으면 그렇다고 알린다.
    // 취소하면 저장도 멈춘다.
    folder ??= await _changeFolder(inaccessible: ref.read(saveFolderProvider) != null);
    if (folder == null || !mounted) return;

    final outcome = await ref.read(mergeControllerProvider.notifier).save(format, folder);
    if (!mounted) return;
    switch (outcome) {
      case MergeSucceeded(:final fileName, :final folderName):
        _snack(l.savedTo(folderName, fileName));
      case MergeWasCancelled():
        _snack(l.saveCancelled);
      case MergeFailed(:final error):
        await _showError(error, title: l.saveFailedTitle);
        // 복사 단계에서 폴더를 잃었으면 바로 폴더 변경 창을 연다 (DESIGN §3.4).
        if (error.code == MergeErrorCode.folderUnavailable && mounted) await _changeFolder();
    }
  }

  /// PNG·PDF를 고른 뒤 공유한다 (DESIGN §2.1.7).
  Future<void> _chooseShareFormat() async {
    if (_saving) return;
    final l = AppLocalizations.of(context);
    final format = await showModalBottomSheet<OutputFormat>(
      context: context,
      showDragHandle: true,
      // 메인 화면의 밝은 아이콘은 시트의 밝은 바탕에서 보이지 않는다.
      builder: (context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: navBarOverlayStyle(context, background: Theme.of(context).colorScheme.surface),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(l.shareFormatPrompt, textAlign: TextAlign.center),
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: Text(l.shareAs(OutputFormat.png.label)),
                onTap: () => Navigator.pop(context, OutputFormat.png),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: Text(l.shareAs(OutputFormat.pdf.label)),
                onTap: () => Navigator.pop(context, OutputFormat.pdf),
              ),
            ],
          ),
        ),
      ),
    );
    if (format == null || !mounted) return;
    setState(() => _saving = true);
    try {
      final outcome = await ref.read(mergeControllerProvider.notifier).share(format);
      if (!mounted) return;
      switch (outcome) {
        case MergeSucceeded():
          break; // 공유 시트가 떠 있다.
        case MergeWasCancelled():
          _snack(l.shareCancelled);
        case MergeFailed(:final error):
          await _showError(error, title: l.shareFailedTitle);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showError(MergeException error, {required String title}) {
    final l = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(l.mergeError(error.code, imageNumber: error.imageNumber)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.ok)),
        ],
      ),
    );
  }

  Future<void> _showCrashNotice() {
    if (!mounted) return Future.value();
    final l = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.crashTitle),
        content: Text(l.crashBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.ok)),
        ],
      ),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _FolderAction { useDefault, pick }

/// 현재 폴더, Android 안내, 세로로 쌓은 버튼. 긴 언어에서는 창 전체가 스크롤된다 (DESIGN §2.1.4).
class _FolderDialog extends StatelessWidget {
  const _FolderDialog({
    required this.current,
    required this.offeredDefault,
    required this.inaccessible,
  });

  final FolderRef? current;

  /// 기본 폴더가 있고 지금 쓰는 폴더가 아닐 때만 준다.
  final FolderRef? offeredDefault;
  final bool inaccessible;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final current = this.current;
    final offeredDefault = this.offeredDefault;
    void choose(_FolderAction? action) => Navigator.pop(context, action);
    Widget label(String text) => Text(text, textAlign: TextAlign.center);
    return AlertDialog(
      scrollable: true,
      title: Text(l.folderDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          if (inaccessible)
            Text(l.errorFolderUnavailable, style: TextStyle(color: theme.colorScheme.error)),
          if (current != null) Text(l.folderCurrent(current.name)),
          // Android 11부터 고를 수 없는 폴더가 있어 먼저 안내한다. iOS에는 그런 제한이 없다.
          if (defaultTargetPlatform == TargetPlatform.android) Text(l.folderDialogBodyAndroid),
          if (offeredDefault != null)
            FilledButton(
              onPressed: () => choose(_FolderAction.useDefault),
              child: label(l.useDefaultFolder(offeredDefault.name)),
            ),
          FilledButton.tonal(
            onPressed: () => choose(_FolderAction.pick),
            child: label(current == null ? l.pickFolder : l.pickOtherFolder),
          ),
          TextButton(onPressed: () => choose(null), child: label(l.cancel)),
        ],
      ),
    );
  }
}

/// 프로그램 이름과 작은 부제 (DESIGN §2.2). 부제가 없는 언어는 이름만 쓴다.
class _AppTitle extends StatelessWidget {
  const _AppTitle();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // 긴 언어에서는 잘라내지 않고 제목 전체를 조금 줄인다.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          text: l.appName,
          children: [
            if (l.appSubtitle.isNotEmpty)
              TextSpan(
                text: ' ${l.appSubtitle}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
              ),
          ],
        ),
        maxLines: 1,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onPickPhotos,
    required this.onPickPdfs,
    required this.onCamera,
  });

  final VoidCallback? onPickPhotos;
  final VoidCallback? onPickPdfs;
  final VoidCallback? onCamera;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    // 긴 언어나 낮은 화면에서 넘치지 않게 스크롤을 허용하고, 남으면 가운데에 놓는다.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.collections_outlined, size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    l.emptyTitle(kMinImages),
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.emptyHint,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: onPickPhotos,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(l.pickImages),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onPickPdfs,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(l.pickPdf),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onCamera,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(l.takePhoto),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends ConsumerWidget {
  const _PreviewCard({required this.images});

  final List<SelectedImage> images;

  /// 페이지 번호까지 포함한 높이.
  static const _previewHeight = 124.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final settings = ref.watch(outputSettingsProvider);
    final paper = settings.paperDimensions;
    final direction = pngDirection([for (final i in images) i.size], paper);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                direction == LayoutDirection.vertical ? Icons.view_agenda_outlined : Icons.view_week_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  paper == null
                      ? l.autoDirection(direction)
                      : l.previewSummary(
                          sheetCount(images.length, settings.imagesPerPaper),
                          settings.imagesPerPaper,
                        ),
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            paper == null ? l.previewNoteOriginal : l.previewNote(direction),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: _previewHeight,
            child: LayoutPreview(images: images, settings: settings),
          ),
        ],
      ),
    );
  }
}

/// 용지, 용지 방향, 용지당 이미지 수, 이미지 크기, 여백, 컬러/흑백 (DESIGN §2.1.5).
/// 배치 방향을 바꾸는 컨트롤은 없다. 긴 언어에서는 다음 줄로 넘어간다.
class _OutputSettingsBar extends ConsumerWidget {
  const _OutputSettingsBar({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(outputSettingsProvider);
    final controller = ref.read(outputSettingsProvider.notifier);
    // 칸의 최소 폭은 밀도로만 줄일 수 있다. 여백 네 칸과 컬러/흑백이 한 줄에 들어가게 가장 좁게 둔다.
    final compact = ButtonStyle(
      visualDensity: const VisualDensity(horizontal: VisualDensity.minimumDensity, vertical: -2),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 6)),
    );
    final hasPaper = settings.paper != PaperSize.original;
    Widget segmentLabel(String text) => Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          DropdownButton<PaperSize>(
            isDense: true,
            value: settings.paper,
            underline: const SizedBox.shrink(),
            onChanged: enabled ? (paper) => controller.setPaper(paper!) : null,
            items: [
              for (final paper in PaperSize.values)
                DropdownMenuItem(value: paper, child: Text(l.paperName(paper))),
            ],
          ),
          SegmentedButton<PaperOrientation>(
            style: compact,
            showSelectedIcon: false,
            segments: [
              for (final o in PaperOrientation.values)
                ButtonSegment(
                  value: o,
                  label: segmentLabel(l.orientationName(o)),
                  enabled: enabled && hasPaper,
                ),
            ],
            selected: {settings.orientation},
            onSelectionChanged: (s) => controller.setOrientation(s.first),
          ),
          _LabeledDropdown(
            key: const ValueKey('images-per-paper'),
            label: l.imagesPerPaper,
            value: settings.imagesPerPaper,
            choices: kImagesPerPaperChoices,
            choiceLabel: (n) => '$n',
            onChanged: enabled && hasPaper ? controller.setImagesPerPaper : null,
          ),
          _LabeledDropdown(
            key: const ValueKey('image-size'),
            label: l.imageSize,
            value: settings.imageSizePercent,
            choices: kImageSizePercentChoices,
            choiceLabel: (percent) => '$percent%',
            onChanged: enabled && hasPaper ? controller.setImageSizePercent : null,
          ),
          // 용지당 이미지 수·이미지 크기와 달리 '원본 크기'에도 쓴다.
          _LabeledSetting(
            key: const ValueKey('margin'),
            label: l.margin,
            enabled: enabled,
            child: SegmentedButton<int>(
              style: compact,
              showSelectedIcon: false,
              segments: [
                for (final percent in kMarginPercentChoices)
                  ButtonSegment(value: percent, label: segmentLabel('$percent%'), enabled: enabled),
              ],
              selected: {settings.marginPercent},
              onSelectionChanged: (s) => controller.setMarginPercent(s.first),
            ),
          ),
          SegmentedButton<bool>(
            style: compact,
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: false, label: segmentLabel(l.colorMode), enabled: enabled),
              ButtonSegment(value: true, label: segmentLabel(l.grayscaleMode), enabled: enabled),
            ],
            selected: {settings.grayscale},
            onSelectionChanged: (s) => controller.setGrayscale(s.first),
          ),
        ],
      ),
    );
  }
}

class _LabeledDropdown extends StatelessWidget {
  const _LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.choices,
    required this.choiceLabel,
    required this.onChanged,
  });

  final String label;
  final int value;
  final List<int> choices;
  final String Function(int) choiceLabel;

  /// null이면 비활성화한다.
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return _LabeledSetting(
      label: label,
      enabled: onChanged != null,
      child: DropdownButton<int>(
        isDense: true,
        value: value,
        underline: const SizedBox.shrink(),
        onChanged: onChanged == null ? null : (v) => onChanged(v!),
        items: [
          for (final choice in choices)
            DropdownMenuItem(value: choice, child: Text(choiceLabel(choice))),
        ],
      ),
    );
  }
}

class _LabeledSetting extends StatelessWidget {
  const _LabeledSetting({
    super.key,
    required this.label,
    required this.enabled,
    required this.child,
  });

  final String label;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: enabled ? null : theme.disabledColor),
          ),
        ),
        const SizedBox(width: 6),
        child,
      ],
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({
    required this.count,
    required this.onPickPhotos,
    required this.onPickPdfs,
    required this.onCamera,
    required this.onClear,
  });

  final int count;
  final VoidCallback? onPickPhotos;
  final VoidCallback? onPickPdfs;
  final VoidCallback? onCamera;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              l.selectedCount(count, kMaxImages),
              style: Theme.of(context).textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 긴 언어에서는 버튼 묶음 전체를 조금 줄여 한 줄을 지킨다.
          Expanded(
            flex: 5,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MenuAnchor(
                    builder: (context, menu, _) => TextButton.icon(
                      onPressed: onPickPhotos == null
                          ? null
                          : () => menu.isOpen ? menu.close() : menu.open(),
                      icon: const Icon(Icons.add),
                      label: Text(l.addItems),
                    ),
                    menuChildren: [
                      MenuItemButton(
                        leadingIcon: const Icon(Icons.add_photo_alternate_outlined),
                        onPressed: onPickPhotos,
                        child: Text(l.pickPhotos),
                      ),
                      MenuItemButton(
                        leadingIcon: const Icon(Icons.picture_as_pdf_outlined),
                        onPressed: onPickPdfs,
                        child: Text(l.pickPdfFiles),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: onCamera,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(l.camera),
                  ),
                  TextButton(onPressed: onClear, child: Text(l.clearList)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 타이틀바처럼 진한 주 색상 배경의 하단 저장 영역 (DESIGN §2.2). 배경은 내비게이션 바 뒤까지 이어지고,
/// 버튼은 SafeArea로 바 위에 둔다. 바의 아이콘 모양은 이 영역이 있는 동안만 적용된다.
class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.folder,
    required this.imageCount,
    required this.enabled,
    required this.onChangeFolder,
    required this.onSave,
    required this.onShare,
  });

  final FolderRef? folder;
  final int imageCount;
  final bool enabled;
  final Future<FolderRef?> Function() onChangeFolder;
  final void Function(OutputFormat format) onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l = AppLocalizations.of(context);
    final canSave = enabled && imageCount >= kMinImages;
    final style = saveBarButtonStyle(colors);
    final folderColor = enabled ? colors.onPrimary : colors.onPrimary.withValues(alpha: 0.7);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // 바가 아래에 있으면 이 영역이 비치고, 가로 모드에서 옆에 있으면 밝은 본문이 비친다.
      value: navBarOverlayStyle(context, background: colors.primary, sideBackground: colors.surface),
      child: Material(
        key: const ValueKey('save-bar'),
        color: colors.primary,
        textStyle: theme.textTheme.bodyMedium?.copyWith(color: colors.onPrimary),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: enabled ? onChangeFolder : null,
                  borderRadius: BorderRadius.circular(8),
                  splashColor: colors.onPrimary.withValues(alpha: 0.2),
                  highlightColor: colors.onPrimary.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.folder_outlined, size: 20, color: folderColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            folder == null ? l.folderNotChosen : l.folderCurrent(folder!.name),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: folderColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l.changeFolder,
                          style: TextStyle(
                            color: folderColor,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: folderColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (imageCount == 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      l.needMinImages(kMinImages),
                      style: theme.textTheme.bodySmall?.copyWith(color: colors.onPrimary),
                    ),
                  ),
                // 긴 언어에서 글자가 두 줄이 되어도 세 버튼의 높이를 같게 둔다.
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _SaveBarButton(
                          style: style,
                          onPressed: canSave ? () => onSave(OutputFormat.png) : null,
                          icon: Icons.image_outlined,
                          label: l.saveAs(OutputFormat.png.label),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SaveBarButton(
                          style: style,
                          onPressed: canSave ? () => onSave(OutputFormat.pdf) : null,
                          icon: Icons.picture_as_pdf_outlined,
                          label: l.saveAs(OutputFormat.pdf.label),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SaveBarButton(
                          style: style,
                          onPressed: canSave ? onShare : null,
                          icon: Icons.share_outlined,
                          label: l.share,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 아이콘을 글자 위에 둔다. 폭이 좁은 버튼 세 개라 옆에 두면 긴 언어의 글자 자리가 모자란다.
class _SaveBarButton extends StatelessWidget {
  const _SaveBarButton({
    required this.style,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final ButtonStyle style;
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: style,
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 2),
          Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
