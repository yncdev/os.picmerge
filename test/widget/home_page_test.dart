import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart' show CupertinoLocalizations;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_merger/app.dart';
import 'package:image_merger/core/database/app_database.dart';
import 'package:image_merger/core/providers.dart';
import 'package:image_merger/core/storage/temp_storage.dart';
import 'package:image_merger/core/errors/merge_exception.dart';
import 'package:image_merger/core/platform/native_bridge.dart';
import 'package:image_merger/features/image_merger/domain/output_format.dart';
import 'package:image_merger/features/image_merger/domain/output_settings.dart';
import 'package:image_merger/features/image_merger/presentation/output_settings_controller.dart';
import 'package:image_merger/features/image_selection/domain/selected_image.dart';
import 'package:image_merger/features/image_selection/presentation/selection_controller.dart';
import 'package:image_merger/features/session_history/data/session_repository.dart';
import 'package:image_merger/features/session_history/domain/session_record.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/fake_native_bridge.dart';
import '../support/test_helpers.dart';

class _PresetSelection extends SelectionController {
  _PresetSelection(this.preset);

  final List<SelectedImage> preset;

  @override
  List<SelectedImage> build() => preset;
}

/// 문서 선택기가 열린 채로 멈춘다. 진행 막대가 보이는 동안을 시험한다.
class _WaitingPdfPicker extends FakeNativeBridge {
  _WaitingPdfPicker({super.cacheDirPath});

  final gate = Completer<List<String>>();

  @override
  Future<List<String>> pickPdfs() => gate.future;
}

class _PresetSettings extends OutputSettingsController {
  _PresetSettings(this.preset);

  final OutputSettings preset;

  @override
  OutputSettings build() => preset;
}

SelectedImage screenshot(int i) => SelectedImage(
      path: '/nonexistent/shot_$i.png',
      thumbnailPath: '/nonexistent/thumb_$i.jpg',
      displayName: 'shot_$i.png',
      width: 1080,
      height: 2340,
      bytes: 800000,
      mime: 'image/png',
    );

void main() {
  late AppDatabase database;
  late Directory cache;

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    database = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    cache = await Directory.systemTemp.createTemp('home_page_test');
  });
  tearDown(() async {
    await database.close();
    await deleteTempDir(cache);
  });

  /// 한국어 문구로 찾는 시험이 많아 언어를 고정한다.
  Widget app({
    List<SelectedImage>? preset,
    int crashed = 0,
    Locale? locale = const Locale('ko'),
    FakeNativeBridge? bridge,
    FolderRef? initialFolder,
    OutputSettings? settings,
  }) =>
      ProviderScope(
        overrides: [
          appServicesProvider.overrideWithValue(AppServices(
            bridge: bridge ?? FakeNativeBridge(cacheDirPath: cache.path),
            database: database,
            tempStorage: TempStorage(cache.path),
            crashedSessions: crashed,
            initialFolder: initialFolder,
          )),
          if (preset != null) selectionProvider.overrideWith(() => _PresetSelection(preset)),
          if (settings != null) outputSettingsProvider.overrideWith(() => _PresetSettings(settings)),
        ],
        child: ImageMergerApp(locale: locale),
      );

  FilledButton filledButtonWith(WidgetTester tester, String label) => tester.widget<FilledButton>(
        find.ancestor(of: find.text(label), matching: find.byWidgetPredicate((w) => w is FilledButton)),
      );

  testWidgets('빈 목록: 이미지 선택 안내, 저장 버튼 비활성', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();

    expect(find.text('이미지 선택'), findsOneWidget);
    expect(find.text('저장 폴더: 처음 저장할 때 고릅니다'), findsOneWidget);
    expect(filledButtonWith(tester, 'PNG 저장').onPressed, isNull);
    expect(filledButtonWith(tester, 'PDF 저장').onPressed, isNull);
  });

  testWidgets('세로형 3장: 페이지 수 안내, 목록, 저장 버튼 활성', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(preset: [screenshot(1), screenshot(2), screenshot(3)]));
    await tester.pump();

    expect(find.text('총 3페이지 · 용지당 1개'), findsOneWidget);
    expect(find.textContaining('PNG는 페이지를 옆으로'), findsOneWidget);
    expect(find.textContaining('PDF는 페이지별로 저장되고 선이 없습니다.'), findsOneWidget);
    expect(find.text('선택 3/30'), findsOneWidget);
    expect(find.text('shot_1.png'), findsOneWidget);
    expect(find.text('1080×2340 · 800KB'), findsNWidgets(3));
    expect(filledButtonWith(tester, 'PNG 저장').onPressed, isNotNull);
    expect(filledButtonWith(tester, 'PDF 저장').onPressed, isNotNull);
    // 방향을 바꾸는 컨트롤은 없다 (DESIGN §1.3)
    expect(find.byType(Switch), findsNothing);
    expect(find.byType(ToggleButtons), findsNothing);
  });

  testWidgets('1장만 있으면 저장 버튼 비활성과 안내', (tester) async {
    await tester.pumpWidget(app(preset: [screenshot(1)]));
    await tester.pump();

    expect(find.text('2장 이상 골라야 저장할 수 있습니다.'), findsOneWidget);
    expect(filledButtonWith(tester, 'PNG 저장').onPressed, isNull);
  });

  testWidgets('지난 저장이 비정상 종료됐으면 시작할 때 한 번 안내', (tester) async {
    await tester.pumpWidget(app(crashed: 1));
    await tester.pumpAndSettle();

    expect(find.text('이전 저장이 끝나지 않았습니다'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('이전 저장이 끝나지 않았습니다'), findsNothing);
  });

  group('2차 범위', () {
    testWidgets('앱 제목은 Pic Merge와 작은 부제이고 빈 화면에 사진·PDF·카메라가 있다', (tester) async {
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.text('Pic Merge 이미지 합치기'), findsOneWidget);
      expect(find.text('이미지 선택'), findsOneWidget);
      expect(find.text('PDF 선택'), findsOneWidget);
      expect(find.text('카메라로 찍기'), findsOneWidget);
    });

    testWidgets('출력 설정 기본값은 A4·세로·컬러이고, 추가 옆에 카메라, 저장 옆에 공유가 있다', (tester) async {
      await tester.pumpWidget(app(preset: [screenshot(1), screenshot(2)]));
      await tester.pump();

      expect(find.text('A4'), findsOneWidget);
      final orientation = tester.widget<SegmentedButton<PaperOrientation>>(
        find.byType(SegmentedButton<PaperOrientation>),
      );
      expect(orientation.selected, {PaperOrientation.portrait});
      final color = tester.widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>));
      expect(color.selected, {false});
      expect(find.text('추가'), findsOneWidget);
      expect(find.text('카메라'), findsOneWidget);
      expect(filledButtonWith(tester, '공유').onPressed, isNotNull);
    });

    testWidgets('추가 메뉴에 사진 선택과 PDF 파일 선택이 있다', (tester) async {
      await tester.pumpWidget(app(preset: [screenshot(1), screenshot(2)]));
      await tester.pump();

      await tester.tap(find.text('추가'));
      await tester.pumpAndSettle();

      expect(find.text('사진 선택'), findsOneWidget);
      expect(find.text('PDF 파일 선택'), findsOneWidget);
    });

    testWidgets('원본 크기를 고르면 용지 방향을 고를 수 없다', (tester) async {
      await tester.pumpWidget(app(preset: [screenshot(1), screenshot(2)]));
      await tester.pump();

      await tester.tap(find.text('A4'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('원본 크기').last);
      await tester.pumpAndSettle();

      final orientation = tester.widget<SegmentedButton<PaperOrientation>>(
        find.byType(SegmentedButton<PaperOrientation>),
      );
      expect(orientation.segments.every((s) => !s.enabled), isTrue);
    });

    testWidgets('공유 버튼은 PNG·PDF 형식을 묻는다', (tester) async {
      await tester.pumpWidget(app(preset: [screenshot(1), screenshot(2)]));
      await tester.pump();

      await tester.tap(find.text('공유'));
      await tester.pumpAndSettle();

      expect(find.text('PNG로 공유'), findsOneWidget);
      expect(find.text('PDF로 공유'), findsOneWidget);
    });

    testWidgets('1장뿐이면 공유도 비활성', (tester) async {
      await tester.pumpWidget(app(preset: [screenshot(1)]));
      await tester.pump();

      expect(filledButtonWith(tester, '공유').onPressed, isNull);
    });

    for (final (name, size) in [
      ('좁은 폰 세로', const Size(360, 640)),
      ('폰 가로', const Size(740, 360)),
    ]) {
      testWidgets('$name 화면에서 넘침 오류가 없다', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(app(preset: [screenshot(1), screenshot(2), screenshot(3)]));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('공유'), findsOneWidget);
      });
    }

    for (final (name, inset, margin) in [
      // Flutter가 제스처 구역을 0으로 보고해도(에뮬레이터에서 실제로 그랬다) 48dp는 띄운다.
      ('보고값이 0이어도', 0.0, 48.0),
      ('보고값이 크면 그 바깥으로', 40.0, 64.0),
    ]) {
      testWidgets('영역 편집 손잡이는 뒤로 가기 제스처 구역 바깥에 있다: $name', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1;
        tester.view.systemGestureInsets = FakeViewPadding(left: inset, right: inset);
        addTearDown(tester.view.reset);
        final image = SelectedImage(
          path: '${cache.path}/a.jpg',
          thumbnailPath: '${cache.path}/a_thumb.jpg',
          displayName: 'a.jpg',
          width: 1000,
          height: 2000,
          bytes: 1000,
          mime: 'image/jpeg',
        );
        await tester.pumpWidget(app(preset: [image, screenshot(2)]));
        await tester.pump();

        await tester.tap(find.byTooltip('영역 편집').first);
        await pumpUntil(tester, () => find.byKey(const ValueKey('crop-area')).evaluate().isNotEmpty);

        final area = tester.getRect(find.byKey(const ValueKey('crop-area')));
        expect(area.left, greaterThanOrEqualTo(margin));
        expect(area.right, lessThanOrEqualTo(400 - margin));
      });
    }

    testWidgets('항목의 영역 편집 버튼으로 편집 화면을 열고, 끌어서 적용하면 항목에 반영된다', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final bridge = FakeNativeBridge(cacheDirPath: cache.path);
      final container = ProviderContainer(
        overrides: [
          appServicesProvider.overrideWithValue(AppServices(
            bridge: bridge,
            database: database,
            tempStorage: TempStorage(cache.path),
          )),
          selectionProvider.overrideWith(() => _PresetSelection([
                SelectedImage(
                  path: '${cache.path}/a.jpg',
                  thumbnailPath: '${cache.path}/a_thumb.jpg',
                  displayName: 'a.jpg',
                  width: 1000,
                  height: 1000,
                  bytes: 1000,
                  mime: 'image/jpeg',
                ),
                screenshot(2),
              ])),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const ImageMergerApp(locale: Locale('ko')),
      ));
      await tester.pump();

      await tester.tap(find.byTooltip('영역 편집').first);
      await pumpUntil(tester, () => find.byKey(const ValueKey('crop-area')).evaluate().isNotEmpty);

      expect(find.text('영역 편집'), findsOneWidget);
      expect(bridge.jpegCalls.last.width, 1000, reason: '1000×1000은 1600 이하라 그대로');

      // 편집 영역(1:1)의 오른쪽 아래 모서리를 안쪽으로 끈다.
      final area = tester.getRect(find.byKey(const ValueKey('crop-area')));
      // 손잡이는 이미지 경계 밖까지 그려진다. 경계 밖을 눌러도 잡혀야 한다.
      final gesture = await tester.startGesture(area.bottomRight + const Offset(10, 10));
      await gesture.moveBy(const Offset(-20, -20));
      await gesture.moveBy(Offset(-area.width / 2 + 20, -area.height / 2 + 20));
      await gesture.up();
      await tester.pump();

      await tester.tap(find.text('적용'));
      await pumpUntil(tester, () => find.textContaining('영역 편집됨').evaluate().isNotEmpty);

      final crop = container.read(selectionProvider).first.crop!;
      expect(crop.left, 0);
      expect(crop.top, 0);
      expect(crop.right, closeTo(0.5, 0.02));
      expect(crop.bottom, closeTo(0.5, 0.02));
      expect(find.textContaining('영역 편집됨'), findsOneWidget);
    });
  });

  group('제목과 언어', () {
    testWidgets('English는 부제 없이 Pic Merge', (tester) async {
      await tester.pumpWidget(app(locale: const Locale('en')));
      await tester.pump();

      expect(find.text('Pic Merge'), findsOneWidget);
      expect(find.text('Choose images'), findsOneWidget);
    });

    testWidgets('부제는 프로그램 이름보다 작다', (tester) async {
      await tester.pumpWidget(app(locale: const Locale('ja')));
      await tester.pump();

      final title = tester.widget<Text>(find.text('Pic Merge 画像結合'));
      final subtitle = (title.textSpan! as TextSpan).children!.single as TextSpan;
      final titleSize = DefaultTextStyle.of(tester.element(find.text('Pic Merge 画像結合'))).style.fontSize!;
      expect(subtitle.style!.fontSize, lessThan(titleSize));
    });

    testWidgets('앱 창 제목은 언어와 상관없이 Pic Merge', (tester) async {
      for (final locale in const [Locale('ko'), Locale('en'), Locale('de')]) {
        await tester.pumpWidget(app(locale: locale));
        await tester.pump();
        final title = tester.widget<Title>(find.byType(Title));
        expect(title.title, 'Pic Merge');
      }
    });

    testWidgets('기기 언어를 따른다: 지원하지 않으면 English, 대만 중국어는 번체', (tester) async {
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      tester.platformDispatcher.localesTestValue = const [Locale('sw')];
      await tester.pumpWidget(app(locale: null));
      await tester.pump();
      expect(find.text('Choose images'), findsOneWidget);

      tester.platformDispatcher.localesTestValue = const [Locale('zh', 'TW')];
      await tester.pumpAndSettle();
      expect(find.text('Pic Merge 圖片合併'), findsOneWidget);

      tester.platformDispatcher.localesTestValue = const [Locale('in', 'ID')];
      await tester.pumpAndSettle();
      expect(find.text('Pic Merge Gabung Gambar'), findsOneWidget);
    });

    testWidgets('머티리얼 기본 문구도 기기 언어다', (tester) async {
      await tester.pumpWidget(app(locale: const Locale('fr')));
      await tester.pump();

      final context = tester.element(find.byType(Scaffold));
      expect(Localizations.of<MaterialLocalizations>(context, MaterialLocalizations), isA<MaterialLocalizationFr>());
      expect(Localizations.of<CupertinoLocalizations>(context, CupertinoLocalizations), isA<CupertinoLocalizationFr>());
    });
  });

  group('용지당 이미지 수와 이미지 크기', () {
    void tallScreen(WidgetTester tester) {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    DropdownButton<int> dropdown(WidgetTester tester, String key) => tester.widget<DropdownButton<int>>(
          find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(DropdownButton<int>)),
        );

    Future<void> choose(WidgetTester tester, String key, String value) async {
      await tester.tap(find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(DropdownButton<int>)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(value).last);
      await tester.pumpAndSettle();
    }

    testWidgets('선택지와 기본값', (tester) async {
      tallScreen(tester);
      await tester.pumpWidget(app(preset: [screenshot(1), screenshot(2)]));
      await tester.pump();

      expect(find.text('용지당 이미지 수'), findsOneWidget);
      expect(find.text('이미지 크기'), findsOneWidget);
      final perPaper = dropdown(tester, 'images-per-paper');
      expect(perPaper.value, 1);
      expect(perPaper.items!.map((i) => i.value).toList(), [1, 2, 3, 4, 6, 8, 9]);
      final size = dropdown(tester, 'image-size');
      expect(size.value, 100);
      expect(size.items!.map((i) => i.value).toList(), [100, 50, 30]);
      expect(perPaper.onChanged, isNotNull);
      expect(size.onChanged, isNotNull);
    });

    testWidgets('원본 크기를 고르면 둘 다 비활성화된다', (tester) async {
      tallScreen(tester);
      await tester.pumpWidget(app(preset: [screenshot(1), screenshot(2)]));
      await tester.pump();

      await tester.tap(find.text('A4'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('원본 크기').last);
      await tester.pumpAndSettle();

      expect(dropdown(tester, 'images-per-paper').onChanged, isNull);
      expect(dropdown(tester, 'image-size').onChanged, isNull);
    });

    testWidgets('미리보기: 페이지마다 번호, 칸에 N개, 페이지 수 안내', (tester) async {
      tallScreen(tester);
      await tester.pumpWidget(app(preset: [screenshot(1), screenshot(2), screenshot(3)]));
      await tester.pump();

      expect(find.byKey(const ValueKey('preview-page-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('preview-page-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('preview-page-3')), findsNothing);

      await choose(tester, 'images-per-paper', '2');

      expect(find.text('총 2페이지 · 용지당 2개'), findsOneWidget);
      expect(find.byKey(const ValueKey('preview-page-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('preview-page-2')), findsNothing);
      // 앞의 두 장은 같은 페이지 안에 위아래로 있다.
      final page = tester.getRect(find.byKey(const ValueKey('preview-page-0')));
      final first = tester.getRect(find.byKey(const ValueKey('preview-image-0')));
      final second = tester.getRect(find.byKey(const ValueKey('preview-image-1')));
      expect(page.contains(first.center), isTrue);
      expect(page.contains(second.center), isTrue);
      expect(second.top, greaterThan(first.bottom));
    });

    testWidgets('미리보기: 이미지 크기를 반영하고 구분선은 그리지 않는다', (tester) async {
      tallScreen(tester);
      final square = SelectedImage(
        path: '/nonexistent/square.png',
        thumbnailPath: '/nonexistent/square_thumb.jpg',
        displayName: 'square.png',
        width: 1000,
        height: 1000,
        bytes: 1000,
        mime: 'image/png',
      );
      await tester.pumpWidget(app(preset: [square, screenshot(2)]));
      await tester.pump();

      final page = tester.getRect(find.byKey(const ValueKey('preview-page-0')));
      // 기본 여백이 짧은 변(폭)의 5%라 정사각형은 폭의 90%를 채우고 왼쪽에 5%가 남는다.
      final full = tester.getRect(find.byKey(const ValueKey('preview-image-0')));
      expect(full.width, closeTo(page.width * 0.9, 0.01));
      expect(full.left - page.left, closeTo(page.width * 0.05, 0.01));

      await choose(tester, 'image-size', '50%');

      final half = tester.getRect(find.byKey(const ValueKey('preview-image-0')));
      expect(half.width, closeTo(page.width * 0.45, 0.01));
      expect(half.center.dx, closeTo(page.center.dx, 0.01));
      expect(half.center.dy, closeTo(page.center.dy, 0.01));
    });

    testWidgets('미리보기: 원본 크기는 자동 방향 안내와 한 묶음이다', (tester) async {
      tallScreen(tester);
      await tester.pumpWidget(app(preset: [screenshot(1), screenshot(2)]));
      await tester.pump();

      await tester.tap(find.text('A4'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('원본 크기').last);
      await tester.pumpAndSettle();

      expect(find.text('자동: 가로 배치 (왼쪽 → 오른쪽)'), findsOneWidget);
      expect(find.textContaining('PDF는 항목마다 한 페이지로 저장되고 선이 없습니다.'), findsOneWidget);
      expect(find.byKey(const ValueKey('preview-page-0')), findsNothing);
      // PNG 계산대로 그린다: 이미지마다 공통 변(높이)의 5% 여백이 네 변에 있다.
      final frame = tester.getRect(find.byKey(const ValueKey('preview-original')));
      final first = tester.getRect(find.byKey(const ValueKey('preview-image-0')));
      final second = tester.getRect(find.byKey(const ValueKey('preview-image-1')));
      expect(first.top - frame.top, closeTo(first.height * 0.05, 0.5));
      expect(first.left - frame.left, closeTo(first.height * 0.05, 0.5));
      expect(frame.right - second.right, closeTo(second.height * 0.05, 0.5));
      // 둘 사이에는 여백 둘과 구분선 자리가 있고 구분선은 그리지 않는다.
      expect(second.left - first.right, greaterThan(first.height * 0.1));
    });

    testWidgets('여백: 기본 5%, 선택지 0·3·5·10이고 미리보기에 반영된다', (tester) async {
      tallScreen(tester);
      final square = SelectedImage(
        path: '/nonexistent/square.png',
        thumbnailPath: '/nonexistent/square_thumb.jpg',
        displayName: 'square.png',
        width: 1000,
        height: 1000,
        bytes: 1000,
        mime: 'image/png',
      );
      await tester.pumpWidget(app(preset: [square, screenshot(2)]));
      await tester.pump();

      expect(find.text('여백'), findsOneWidget);
      SegmentedButton<int> control() => tester.widget<SegmentedButton<int>>(find.byType(SegmentedButton<int>));
      expect(control().selected, {5});
      expect(control().segments.map((s) => s.value).toList(), [0, 3, 5, 10]);

      final page = tester.getRect(find.byKey(const ValueKey('preview-page-0')));
      Rect image() => tester.getRect(find.byKey(const ValueKey('preview-image-0')));
      expect(image().width, closeTo(page.width * 0.9, 0.01));

      await tester.tap(find.text('10%'));
      await tester.pumpAndSettle();
      expect(control().selected, {10});
      expect(image().width, closeTo(page.width * 0.8, 0.01));
      expect(image().left - page.left, closeTo(page.width * 0.1, 0.01));

      await tester.tap(find.text('0%'));
      await tester.pumpAndSettle();
      expect(image().width, closeTo(page.width, 0.01));
      expect(image().left, closeTo(page.left, 0.01));

      await tester.tap(find.text('3%'));
      await tester.pumpAndSettle();
      expect(image().width, closeTo(page.width * 0.94, 0.01));
    });

    testWidgets('여백은 원본 크기에서도 켜져 있고 미리보기에 반영된다', (tester) async {
      tallScreen(tester);
      await tester.pumpWidget(app(preset: [screenshot(1), screenshot(2)]));
      await tester.pump();

      await tester.tap(find.text('A4'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('원본 크기').last);
      await tester.pumpAndSettle();

      final control = tester.widget<SegmentedButton<int>>(find.byType(SegmentedButton<int>));
      expect(control.segments.every((s) => s.enabled), isTrue);

      await tester.tap(find.text('0%'));
      await tester.pumpAndSettle();
      final frame = tester.getRect(find.byKey(const ValueKey('preview-original')));
      final first = tester.getRect(find.byKey(const ValueKey('preview-image-0')));
      expect(first.left, closeTo(frame.left, 0.01), reason: '여백이 없다');
      expect(first.top, closeTo(frame.top, 0.01));
    });

    testWidgets('미리보기: 흑백이면 회색조 필터가 있다', (tester) async {
      tallScreen(tester);
      await tester.pumpWidget(app(preset: [screenshot(1), screenshot(2)]));
      await tester.pump();
      expect(find.byType(ColorFiltered), findsNothing);

      await tester.tap(find.text('흑백'));
      await tester.pumpAndSettle();

      expect(find.byType(ColorFiltered), findsWidgets);
    });
  });

  group('상단·하단 색과 내비게이션 바', () {
    testWidgets('앱바와 하단 영역은 같은 주 색상이다', (tester) async {
      await tester.pumpWidget(app(preset: [screenshot(1), screenshot(2)]));
      await tester.pump();

      final colors = Theme.of(tester.element(find.byType(Scaffold))).colorScheme;
      expect(tester.widget<AppBar>(find.byType(AppBar)).backgroundColor, colors.primary);
      expect(tester.widget<AppBar>(find.byType(AppBar)).foregroundColor, colors.onPrimary);
      expect(tester.widget<Material>(find.byKey(const ValueKey('save-bar'))).color, colors.primary);
    });

    testWidgets('하단 배경은 내비게이션 바 뒤까지 이어지고 버튼은 그 위에 있다', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.viewPadding = const FakeViewPadding(bottom: 48);
      tester.view.padding = const FakeViewPadding(bottom: 48);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(preset: [screenshot(1), screenshot(2)]));
      await tester.pump();

      expect(tester.getRect(find.byKey(const ValueKey('save-bar'))).bottom, 800);
      final button = find.ancestor(of: find.text('공유'), matching: find.byWidgetPredicate((w) => w is FilledButton));
      expect(tester.getRect(button).bottom, lessThanOrEqualTo(800 - 48));
    });

    testWidgets('메인 화면: 투명한 바에 밝은 아이콘, 대비 강제 끔. 영역 편집과 시트에서는 아이콘이 보이게 바뀐다', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.viewPadding = const FakeViewPadding(bottom: 48);
      tester.view.padding = const FakeViewPadding(bottom: 48);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(preset: [screenshot(1), screenshot(2)]));
      await tester.pumpAndSettle();

      final home = SystemChrome.latestStyle!;
      expect(home.systemNavigationBarColor, Colors.transparent);
      expect(home.systemNavigationBarIconBrightness, Brightness.light);
      expect(home.systemNavigationBarContrastEnforced, isFalse);
      expect(home.statusBarIconBrightness, Brightness.light, reason: '앱바도 주 색상이다');

      // 공유 형식 시트는 밝은 바탕이다.
      await tester.tap(find.text('공유'));
      await tester.pumpAndSettle();
      expect(SystemChrome.latestStyle!.systemNavigationBarIconBrightness, Brightness.dark);
      await tester.tapAt(const Offset(200, 100));
      await tester.pumpAndSettle();
      expect(SystemChrome.latestStyle!.systemNavigationBarIconBrightness, Brightness.light);

      // 최근 기록 시트도 밝은 바탕이다.
      await tester.tap(find.byTooltip('최근 기록'));
      await tester.pump();
      await pumpUntil(tester, () => find.text('아직 저장한 적이 없습니다.').evaluate().isNotEmpty);
      expect(SystemChrome.latestStyle!.systemNavigationBarIconBrightness, Brightness.dark);
      await tester.tapAt(const Offset(200, 50));
      await tester.pumpAndSettle();

      // 영역 편집 화면은 검은 바탕이라 밝은 아이콘이고, 상태 표시줄은 그 화면의 앱바를 따른다.
      await tester.tap(find.byTooltip('영역 편집').first);
      await pumpUntil(tester, () => find.byKey(const ValueKey('crop-area')).evaluate().isNotEmpty);
      final crop = SystemChrome.latestStyle!;
      expect(crop.systemNavigationBarIconBrightness, Brightness.light);
      expect(crop.systemNavigationBarContrastEnforced, isFalse);
      expect(crop.statusBarIconBrightness, Brightness.dark);
    });

    testWidgets('사진을 불러올 때 앱바의 진행 막대가 주 색상 위에서 보인다', (tester) async {
      final bridge = _WaitingPdfPicker(cacheDirPath: cache.path);
      await tester.pumpWidget(app(preset: [screenshot(1), screenshot(2)], bridge: bridge));
      await tester.pump();
      final colors = Theme.of(tester.element(find.byType(Scaffold))).colorScheme;

      await tester.tap(find.text('추가'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PDF 파일 선택'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final bar = tester.widget<LinearProgressIndicator>(
        find.descendant(of: find.byType(AppBar), matching: find.byType(LinearProgressIndicator)),
      );
      expect(bar.color, colors.onPrimary);
      expect(bar.backgroundColor, colors.onPrimary.withValues(alpha: 0.3));

      bridge.gate.complete(const []);
      await tester.pump();
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });

  group('좁은 화면과 옆쪽 내비게이션 바', () {
    testWidgets('미리보기는 낮은 세로 화면에서도 보이고, 가로 모드처럼 아주 낮을 때만 접는다', (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Future<bool> previewAt(Size size) async {
        tester.view.physicalSize = size;
        await tester.pumpWidget(app(preset: [screenshot(1), screenshot(2), screenshot(3)]));
        await tester.pump();
        expect(tester.takeException(), isNull);
        return find.byKey(const ValueKey('preview-page-0')).evaluate().isNotEmpty;
      }

      expect(await previewAt(const Size(360, 640)), isTrue);
      expect(await previewAt(const Size(360, 568)), isTrue);
      expect(await previewAt(const Size(740, 360)), isFalse);
      expect(await previewAt(const Size(600, 400)), isFalse);
    });

    testWidgets('360×640: 미리보기·페이지 수·안내와 설정이 모두 보인다', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(preset: [screenshot(1), screenshot(2), screenshot(3)]));
      await tester.pump();

      expect(find.text('총 3페이지 · 용지당 1개'), findsOneWidget);
      expect(find.textContaining('PNG는 페이지를 옆으로'), findsOneWidget);
      final list = tester.getRect(find.byType(ReorderableListView));
      expect(list.height, greaterThanOrEqualTo(72), reason: '목록이 한 줄은 보인다');
    });

    testWidgets('상태·내비게이션 바가 있는 360×640: 잘린 설정까지 스크롤로 닿고 스크롤바가 있다', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      const insets = FakeViewPadding(top: 24, bottom: 48);
      tester.view.viewPadding = insets;
      tester.view.padding = insets;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(preset: [screenshot(1), screenshot(2), screenshot(3)]));
      await tester.pump();

      expect(find.byKey(const ValueKey('preview-page-0')), findsOneWidget);
      expect(find.byType(Scrollbar), findsOneWidget);

      final margin = find.byKey(const ValueKey('margin'));
      await tester.ensureVisible(margin);
      await tester.pumpAndSettle();

      final header = tester.getRect(find.text('비우기'));
      expect(tester.getRect(margin).bottom, lessThanOrEqualTo(header.top + 8));
      expect(tester.takeException(), isNull);
    });

    for (final (name, insets, limit) in const [
      ('오른쪽', FakeViewPadding(right: 48), 692.0),
      ('왼쪽', FakeViewPadding(left: 48), 740.0),
    ]) {
      testWidgets('가로 모드 $name 3버튼 바: 본문이 바 아래로 들어가지 않는다', (tester) async {
        tester.view.physicalSize = const Size(740, 360);
        tester.view.devicePixelRatio = 1;
        tester.view.viewPadding = insets;
        tester.view.padding = insets;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(app(preset: [screenshot(1), screenshot(2)]));
        await tester.pump();

        expect(tester.takeException(), isNull);
        final clear = tester.getRect(find.text('비우기'));
        expect(clear.right, lessThanOrEqualTo(limit));
        final title = tester.getRect(find.text('shot_1.png'));
        expect(title.left, greaterThanOrEqualTo(740 - limit == 0 ? 48 : 0));
        final handle = tester.getRect(find.byIcon(Icons.drag_handle).first);
        expect(handle.right, lessThanOrEqualTo(limit));
      });
    }

    testWidgets('가로 모드 빈 화면도 바 아래로 들어가지 않는다', (tester) async {
      tester.view.physicalSize = const Size(740, 360);
      tester.view.devicePixelRatio = 1;
      const insets = FakeViewPadding(right: 48);
      tester.view.viewPadding = insets;
      tester.view.padding = insets;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(tester.takeException(), isNull);
      final button = find.ancestor(of: find.text('이미지 선택'), matching: find.byWidgetPredicate((w) => w is FilledButton));
      expect(tester.getCenter(button).dx, closeTo(692 / 2, 1), reason: '바를 뺀 영역의 가운데');
    });

    testWidgets('가로 모드 3버튼 바의 아이콘은 밝은 본문 위라 어둡다', (tester) async {
      tester.view.physicalSize = const Size(740, 360);
      tester.view.devicePixelRatio = 1;
      const insets = FakeViewPadding(right: 48);
      tester.view.viewPadding = insets;
      tester.view.padding = insets;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(preset: [screenshot(1), screenshot(2)]));
      await tester.pumpAndSettle();

      final style = SystemChrome.latestStyle!;
      expect(style.systemNavigationBarIconBrightness, Brightness.dark);
      expect(style.systemNavigationBarColor, Colors.transparent);
      expect(style.systemNavigationBarContrastEnforced, isFalse);
    });
  });

  group('저장 폴더', () {
    const download = FolderRef(uri: 'default', name: 'Download');
    const documents = FolderRef(uri: 'content://tree/docs', name: 'Docs');
    const original = OutputSettings(paper: PaperSize.original);

    // 작은 이미지와 '원본 크기'로 실제 합성을 빠르게 끝낸다.
    SelectedImage small(int i) => SelectedImage(
          path: '/nonexistent/small_$i.jpg',
          thumbnailPath: '/nonexistent/small_${i}_thumb.jpg',
          displayName: 'small_$i.jpg',
          width: 20,
          height: 40,
          bytes: 10,
          mime: 'image/jpeg',
        );

    Future<FakeNativeBridge> pumpHome(
      WidgetTester tester, {
      FolderRef? initialFolder,
      FakeNativeBridge? bridge,
    }) async {
      final fake = bridge ?? FakeNativeBridge(cacheDirPath: cache.path);
      await tester.pumpWidget(app(
        preset: [small(1), small(2)],
        settings: original,
        bridge: fake,
        initialFolder: initialFolder,
      ));
      await tester.pump();
      return fake;
    }

    Future<void> saveUntilSnack(WidgetTester tester) async {
      await tester.tap(find.text('PNG 저장'));
      await pumpUntil(tester, () => find.byType(SnackBar).evaluate().isNotEmpty);
    }

    bool shows(Finder finder) => finder.evaluate().isNotEmpty;

    testWidgets('기본 폴더가 있으면 첫 저장에서 아무것도 묻지 않고 저장한다', (tester) async {
      final bridge = await pumpHome(tester, initialFolder: download);
      expect(find.text('저장 폴더: Download'), findsOneWidget);

      await saveUntilSnack(tester);

      final name = bridge.folders['default']!.single;
      expect(name, matches(RegExp(r'^\d{12}_1\.png$')));
      expect(find.text('저장했습니다: Download/$name'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('시스템이 이름을 바꾸면 안내와 기록에 실제 이름을 쓴다', (tester) async {
      final fake = FakeNativeBridge(cacheDirPath: cache.path)
        ..renameOnCopy = ((name) => name.replaceFirst('.png', ' (1).png'));
      await pumpHome(tester, initialFolder: download, bridge: fake);

      await saveUntilSnack(tester);

      final name = fake.folders['default']!.single;
      expect(name, endsWith(' (1).png'));
      expect(find.text('저장했습니다: Download/$name'), findsOneWidget);
      final session = await tester.runAsync(() => SessionRepository(database).recent());
      expect(session!.first.outputName, name);
    });

    testWidgets('고른 폴더를 쓰는 중이면 창에 기본 폴더 쓰기가 있고, 누르면 저장된 설정을 지운다', (tester) async {
      await tester.runAsync(() async {
        await database.setSetting(AppDatabase.settingSaveTreeUri, documents.uri);
        await database.setSetting(AppDatabase.settingSaveFolderName, documents.name);
      });
      await pumpHome(tester, initialFolder: documents);

      await tester.tap(find.text('변경'));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('저장 폴더: Docs')), findsOneWidget);
      expect(find.textContaining('Documents 같은 폴더'), findsOneWidget, reason: 'Android 안내');
      expect(find.text('기본 폴더 쓰기 (Download)'), findsOneWidget);
      expect(find.text('다른 폴더 고르기'), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);

      await tester.tap(find.text('기본 폴더 쓰기 (Download)'));
      await pumpUntil(tester, () => shows(find.text('저장 폴더: Download')));

      expect(find.byType(AlertDialog), findsNothing);
      final saved = await tester.runAsync(() => database.getSetting(AppDatabase.settingSaveTreeUri));
      expect(saved, isNull);
    });

    testWidgets('기본 폴더를 쓰는 중이면 기본 폴더 쓰기가 없고, 다른 폴더를 고르면 저장한다', (tester) async {
      await pumpHome(tester, initialFolder: download);

      await tester.tap(find.text('변경'));
      await tester.pumpAndSettle();

      expect(find.textContaining('기본 폴더 쓰기'), findsNothing);

      await tester.tap(find.text('다른 폴더 고르기'));
      await pumpUntil(tester, () => shows(find.text('저장 폴더: Picked')));

      final saved = await tester.runAsync(() => database.getSetting(AppDatabase.settingSaveTreeUri));
      expect(saved, 'content://tree/picked');
    });

    testWidgets('창에서 취소하면 폴더가 그대로다', (tester) async {
      await pumpHome(tester, initialFolder: documents);

      await tester.tap(find.text('변경'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(find.text('저장 폴더: Docs'), findsOneWidget);
    });

    testWidgets('고른 폴더에 접근할 수 없으면 창을 띄우고, 취소하면 저장하지 않는다', (tester) async {
      final fake = FakeNativeBridge(cacheDirPath: cache.path)..inaccessibleUris.add(documents.uri);
      await pumpHome(tester, initialFolder: documents, bridge: fake);

      await tester.tap(find.text('PNG 저장'));
      await tester.pumpAndSettle();

      expect(find.text('저장 폴더에 접근할 수 없습니다. 폴더를 다시 골라 주세요.'), findsOneWidget);
      expect(find.text('기본 폴더 쓰기 (Download)'), findsOneWidget);

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(fake.decodeCalls, isEmpty, reason: '합성을 시작하지 않는다');
      expect(fake.folders, isEmpty);
      final sessions = await tester.runAsync(() => SessionRepository(database).recent());
      expect(sessions, isEmpty, reason: '저장을 시도하지 않았다');
    });

    testWidgets('접근할 수 없을 때 기본 폴더를 고르면 그대로 저장을 이어 간다', (tester) async {
      final fake = FakeNativeBridge(cacheDirPath: cache.path)..inaccessibleUris.add(documents.uri);
      await pumpHome(tester, initialFolder: documents, bridge: fake);

      await tester.tap(find.text('PNG 저장'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('기본 폴더 쓰기 (Download)'));
      await pumpUntil(tester, () => shows(find.byType(SnackBar)));

      expect(fake.folders['default'], hasLength(1));
      expect(find.text('저장 폴더: Download'), findsOneWidget);
    });

    testWidgets('기본 폴더가 없는 기기: 첫 저장 때 폴더를 고르고 이어서 저장한다', (tester) async {
      final fake = FakeNativeBridge(cacheDirPath: cache.path)..defaultFolderRef = null;
      await pumpHome(tester, bridge: fake);
      expect(find.text('저장 폴더: 처음 저장할 때 고릅니다'), findsOneWidget);

      await tester.tap(find.text('PNG 저장'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Documents 같은 폴더'), findsOneWidget);
      expect(find.textContaining('기본 폴더 쓰기'), findsNothing);
      expect(find.text('저장 폴더에 접근할 수 없습니다. 폴더를 다시 골라 주세요.'), findsNothing, reason: '잃은 폴더가 없다');

      await tester.tap(find.text('폴더 고르기'));
      await pumpUntil(tester, () => shows(find.byType(SnackBar)));

      expect(fake.folders['content://tree/picked'], hasLength(1));
      expect(find.text('저장 폴더: Picked'), findsOneWidget);
    });

    testWidgets('기본 폴더가 없는 기기: 첫 저장에서 취소하면 저장하지 않는다', (tester) async {
      final fake = FakeNativeBridge(cacheDirPath: cache.path)..defaultFolderRef = null;
      await pumpHome(tester, bridge: fake);

      await tester.tap(find.text('PNG 저장'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(fake.decodeCalls, isEmpty);
    });

    testWidgets('복사 단계에서 폴더를 잃으면 오류 안내 뒤 폴더 변경 창을 연다', (tester) async {
      final fake = FakeNativeBridge(cacheDirPath: cache.path)..copyError = 'folder_unavailable';
      await pumpHome(tester, initialFolder: documents, bridge: fake);

      await tester.tap(find.text('PNG 저장'));
      await pumpUntil(tester, () => shows(find.text('저장하지 못했습니다')));
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(find.text('다른 폴더 고르기'), findsOneWidget);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      // 저장 전 확인에서 네이티브가 알려 준 이름(Folder)으로 바뀌어 있다. 취소해도 폴더는 그대로다.
      expect(find.text('저장 폴더: Folder'), findsOneWidget);
    });

    testWidgets('iOS: 선택기 제한 안내가 없고 기본 폴더 이름은 Pic Merge다', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        final fake = FakeNativeBridge(cacheDirPath: cache.path)
          ..defaultFolderRef = const FolderRef(uri: 'default', name: 'Pic Merge');
        await pumpHome(tester, initialFolder: documents, bridge: fake);

        await tester.tap(find.text('변경'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Documents 같은 폴더'), findsNothing);
        expect(find.text('기본 폴더 쓰기 (Pic Merge)'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });

  group('최근 기록', () {
    Future<void> openHistory(WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.tap(find.byIcon(Icons.history));
      await tester.pump();
      await pumpUntil(
        tester,
        () =>
            find.byType(BottomSheet).evaluate().isNotEmpty &&
            find.byType(CircularProgressIndicator).evaluate().isEmpty,
      );
    }

    testWidgets('이전에 기록된 공유 행과 폴더 행을 기기 언어로 보여 준다', (tester) async {
      final repo = SessionRepository(database);
      await tester.runAsync(() async {
        const images = [SessionImageInput(displayName: 'a.jpg', width: 100, height: 100, bytes: 10)];
        final shared = await repo.start(format: OutputFormat.pdf, direction: null, images: images);
        await repo.finishSuccess(
          shared,
          outputBytes: 2000,
          outputName: 'shared.pdf',
          outputFolder: '공유', // 예전 버전이 남긴 값과 같다.
          appliedScales: const [1.0],
        );
        final saved = await repo.start(format: OutputFormat.png, direction: null, images: images);
        await repo.finishSuccess(
          saved,
          outputBytes: 2000,
          outputName: 'saved.png',
          outputFolder: 'Documents',
          appliedScales: const [1.0],
        );
      });

      await tester.pumpWidget(app(locale: const Locale('en')));
      await tester.pump();
      await openHistory(tester);

      expect(find.text('shared.pdf'), findsOneWidget);
      expect(find.textContaining('· Share'), findsOneWidget);
      expect(find.textContaining('공유'), findsNothing);
      expect(find.textContaining('· Documents'), findsOneWidget);
      expect(find.textContaining('1 image'), findsNWidgets(2));
    });

    testWidgets('실패한 세션은 오류를 기기 언어로 보여 준다', (tester) async {
      final repo = SessionRepository(database);
      await tester.runAsync(() async {
        final failed = await repo.start(
          format: OutputFormat.png,
          direction: null,
          images: const [SessionImageInput(displayName: 'a.jpg', width: 100, height: 100, bytes: 10)],
        );
        await repo.finishFailure(failed, MergeErrorCode.outOfSpace);
      });

      await tester.pumpWidget(app(locale: const Locale('ko')));
      await tester.pump();
      await openHistory(tester);

      expect(find.text('실패'), findsOneWidget);
      expect(find.textContaining('저장 공간이 부족합니다.'), findsOneWidget);
    });
  });
}
