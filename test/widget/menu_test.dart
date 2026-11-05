import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_merger/app.dart';
import 'package:image_merger/core/database/app_database.dart';
import 'package:image_merger/core/providers.dart';
import 'package:image_merger/core/storage/temp_storage.dart';
import 'package:image_merger/features/about/presentation/legal_text_page.dart';
import 'package:image_merger/features/image_selection/domain/selected_image.dart';
import 'package:image_merger/features/image_selection/presentation/selection_controller.dart';
import 'package:image_merger/l10n/app_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/fake_native_bridge.dart';

// 메일 앱을 여는 코드는 가짜 브리지까지만 간다. 어떤 시험도 실제 메일 앱을 열지 않는다.

class _PresetSelection extends SelectionController {
  _PresetSelection(this.preset);

  final List<SelectedImage> preset;

  @override
  List<SelectedImage> build() => preset;
}

/// 문서 선택기가 열린 채로 멈춘다. 저장·추가 중(running)을 만든다.
class _WaitingPdfPicker extends FakeNativeBridge {
  _WaitingPdfPicker({super.cacheDirPath});

  final gate = Completer<List<String>>();

  @override
  Future<List<String>> pickPdfs() => gate.future;
}

SelectedImage item(int i) => SelectedImage(
      path: '/nonexistent/s$i.png',
      thumbnailPath: '/nonexistent/t$i.jpg',
      displayName: 's$i.png',
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
    cache = await Directory.systemTemp.createTemp('menu_test');
  });
  tearDown(() async {
    await database.close();
    await cache.delete(recursive: true);
  });

  Future<FakeNativeBridge> pumpHome(
    WidgetTester tester, {
    Locale locale = const Locale('ko'),
    FakeNativeBridge? bridge,
  }) async {
    final fake = bridge ?? FakeNativeBridge(cacheDirPath: cache.path);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appServicesProvider.overrideWithValue(AppServices(
          bridge: fake,
          database: database,
          tempStorage: TempStorage(cache.path),
        )),
        selectionProvider.overrideWith(() => _PresetSelection([item(1), item(2)])),
      ],
      child: ImageMergerApp(locale: locale),
    ));
    await tester.pump();
    return fake;
  }

  Future<void> openDrawer(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  /// 흰 바탕의 글자처럼 큰 면적이 아닌 본문 글자에 요구되는 대비 4.5:1 기준 (WCAG AA).
  double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
  }

  /// 글자의 실제 색과 그 뒤 Material 색의 대비.
  void expectLegible(WidgetTester tester, Finder text) {
    final color = tester.renderObject<RenderParagraph>(text).text.style!.color!;
    final material = find.ancestor(of: text, matching: find.byType(Material)).first;
    final background = tester.widget<Material>(material).color!;
    expect(contrast(color, background), greaterThanOrEqualTo(4.5), reason: '$color on $background');
  }

  group('메뉴', () {
    testWidgets('메뉴 버튼은 왼쪽, 최근 기록은 오른쪽에 있고 아이콘은 onPrimary다', (tester) async {
      await pumpHome(tester);

      final colors = Theme.of(tester.element(find.byType(Scaffold))).colorScheme;
      final menu = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.menu));
      expect(menu.color, colors.onPrimary);
      expect(tester.getCenter(find.byIcon(Icons.menu)).dx, lessThan(tester.getCenter(find.byIcon(Icons.history)).dx));
    });

    testWidgets('열면 프로그램 정보와 의견 보내기만 있다', (tester) async {
      await pumpHome(tester);

      await openDrawer(tester);

      expect(find.text('프로그램 정보'), findsOneWidget);
      expect(find.text('의견 보내기'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.byType(ListTile)),
        findsNWidgets(2),
      );
    });

    testWidgets('연 동안 시스템 아이콘이 밝은 서랍에서 보인다', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      const insets = FakeViewPadding(top: 24, bottom: 48);
      tester.view.viewPadding = insets;
      tester.view.padding = insets;
      addTearDown(tester.view.reset);
      await pumpHome(tester);

      await openDrawer(tester);

      final style = SystemChrome.latestStyle!;
      expect(style.systemNavigationBarIconBrightness, Brightness.dark);
      expect(style.statusBarIconBrightness, Brightness.dark);
    });

    testWidgets('작업 중에는 메뉴 버튼이 꺼지고 끌어서도 열지 못한다', (tester) async {
      final bridge = _WaitingPdfPicker(cacheDirPath: cache.path);
      await pumpHome(tester, bridge: bridge);

      await tapText(tester, '추가');
      await tester.tap(find.text('PDF 파일 선택'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final menu = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.menu));
      expect(menu.onPressed, isNull);
      expect(menu.disabledColor, isNotNull);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.drawerEnableOpenDragGesture, isFalse);

      bridge.gate.complete(const []);
      await tester.pump();
      await tester.pump();
      expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.menu)).onPressed, isNotNull);
    });
  });

  group('프로그램 정보와 이용약관', () {
    testWidgets('프로그램 이름과 설치된 앱의 버전을 보여 준다', (tester) async {
      final bridge = FakeNativeBridge(cacheDirPath: cache.path);
      await pumpHome(tester, bridge: bridge);

      await openDrawer(tester);
      await tapText(tester, '프로그램 정보');

      expect(find.text('Pic Merge'), findsOneWidget);
      expect(find.text('1.0.0 (1)'), findsOneWidget);
      expect(find.byType(Drawer), findsNothing, reason: '서랍은 닫힌다');
      expect(bridge.composeCalls, isEmpty);
    });

    testWidgets('이용약관, 개인정보 처리방침, 오픈소스 라이선스 세 항목이 차례로 있다', (tester) async {
      await pumpHome(tester);

      await openDrawer(tester);
      await tapText(tester, '프로그램 정보');

      final tiles = find.byWidgetPredicate((w) => w is ListTile && w.onTap != null);
      expect(
        [for (final tile in tester.widgetList<ListTile>(tiles)) (tile.title! as Text).data],
        ['이용약관', '개인정보 처리방침', '오픈소스 라이선스'],
      );
    });

    testWidgets('개인정보 처리방침을 앱 안에서 연다', (tester) async {
      await pumpHome(tester);

      await openDrawer(tester);
      await tapText(tester, '프로그램 정보');
      await tapText(tester, '개인정보 처리방침');

      final l = lookupAppLocalizations(const Locale('ko'));
      expect(find.text(l.privacyBody), findsOneWidget);
      expect(find.widgetWithText(AppBar, l.privacyTitle), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('오픈소스 라이선스'), findsOneWidget);
    });

    testWidgets('오픈소스 라이선스는 앱 이름과 버전을 보여 주고 글자가 읽힌다', (tester) async {
      LicenseRegistry.addLicense(
        () => Stream.value(const LicenseEntryWithLineBreaks(['example_package'], 'Example license text')),
      );
      addTearDown(LicenseRegistry.reset);
      await pumpHome(tester);

      await openDrawer(tester);
      await tapText(tester, '프로그램 정보');
      await tapText(tester, '오픈소스 라이선스');

      expect(find.byType(LicensePage), findsOneWidget);
      expect(find.text('Pic Merge'), findsOneWidget);
      expect(find.text('1.0.0 (1)'), findsOneWidget);
      expect(find.text('Powered by Flutter'), findsOneWidget);
      expectLegible(tester, find.text('example_package'));
      final style = SystemChrome.latestStyle!;
      expect(style.statusBarIconBrightness, Brightness.dark);
      // 라이선스 화면은 내비게이션 바 모양을 정하지 않아 프로그램 정보의 어두운 아이콘이 유지된다.
      expect(style.systemNavigationBarIconBrightness, isNot(Brightness.light));

      await tapText(tester, 'example_package');

      expectLegible(tester, find.text('Example license text'));
      expectLegible(tester, find.text('example_package'));
    });

    testWidgets('이용약관을 열어 끝까지 스크롤할 수 있다', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpHome(tester);

      await openDrawer(tester);
      await tapText(tester, '프로그램 정보');
      await tapText(tester, '이용약관');

      final body = lookupAppLocalizations(const Locale('ko')).termsBody;
      expect(find.byType(LegalTextPage), findsOneWidget);
      expect(find.text(body), findsOneWidget);
      expect(find.byType(Scrollable), findsOneWidget);
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -200000));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text(body)).bottom, lessThanOrEqualTo(640));
    });

    testWidgets('두 화면 모두 내비게이션 바 아이콘이 보인다', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      const insets = FakeViewPadding(top: 24, bottom: 48);
      tester.view.viewPadding = insets;
      tester.view.padding = insets;
      addTearDown(tester.view.reset);
      await pumpHome(tester);

      await openDrawer(tester);
      await tapText(tester, '프로그램 정보');
      final about = SystemChrome.latestStyle!;
      expect(about.systemNavigationBarIconBrightness, Brightness.dark);
      expect(about.systemNavigationBarContrastEnforced, isFalse);
      expect(about.statusBarIconBrightness, Brightness.dark);

      await tapText(tester, '이용약관');
      expect(SystemChrome.latestStyle!.systemNavigationBarIconBrightness, Brightness.dark);
    });
  });

  group('의견 보내기', () {
    const subject = 'Pic Merge inquiry - App: Pic Merge 1.0.0 (1), Device: samsung SM-S938N, OS: Android 17';

    testWidgets('언어와 상관없이 영어 제목과 받는 사람을 네이티브로 넘기고, 열리면 아무것도 띄우지 않는다', (tester) async {
      for (final locale in const [Locale('ko'), Locale('de')]) {
        final bridge = FakeNativeBridge(cacheDirPath: cache.path);
        await pumpHome(tester, locale: locale, bridge: bridge);

        await openDrawer(tester);
        await tapText(tester, lookupAppLocalizations(locale).sendFeedback);

        expect(bridge.composeCalls.single.to, 'yncdev@gmail.com');
        expect(bridge.composeCalls.single.subject, subject);
        expect(find.byType(AlertDialog), findsNothing);
      }
    });

    testWidgets('메일 앱이 없으면 주소를 보여 주고 복사할 수 있다', (tester) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      final bridge = FakeNativeBridge(cacheDirPath: cache.path)..composeEmailResult = false;
      await pumpHome(tester, bridge: bridge);

      await openDrawer(tester);
      await tapText(tester, '의견 보내기');

      expect(find.text('메일 앱을 열 수 없습니다'), findsOneWidget);
      expect(find.text('yncdev@gmail.com'), findsOneWidget);

      await tester.tap(find.text('주소 복사'));
      await tester.pumpAndSettle();

      expect(copied, ['yncdev@gmail.com']);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('주소를 복사했습니다.'), findsOneWidget);
    });

    testWidgets('네이티브 오류도 주소 창으로 보여 준다', (tester) async {
      final bridge = FakeNativeBridge(cacheDirPath: cache.path)..composeEmailError = 'unknown';
      await pumpHome(tester, bridge: bridge);

      await openDrawer(tester);
      await tapText(tester, '의견 보내기');

      expect(find.text('yncdev@gmail.com'), findsOneWidget);
      await tapText(tester, '확인');
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

}
