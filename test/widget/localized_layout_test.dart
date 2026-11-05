import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_merger/app.dart';
import 'package:image_merger/core/crop_rect.dart';
import 'package:image_merger/core/database/app_database.dart';
import 'package:image_merger/core/platform/native_bridge.dart';
import 'package:image_merger/core/providers.dart';
import 'package:image_merger/core/storage/temp_storage.dart';
import 'package:image_merger/features/image_merger/domain/output_settings.dart';
import 'package:image_merger/features/image_merger/presentation/output_settings_controller.dart';
import 'package:image_merger/features/image_selection/domain/selected_image.dart';
import 'package:image_merger/features/image_selection/presentation/selection_controller.dart';
import 'package:image_merger/l10n/app_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/fake_native_bridge.dart';

class _PresetSelection extends SelectionController {
  _PresetSelection(this.preset);

  final List<SelectedImage> preset;

  @override
  List<SelectedImage> build() => preset;
}

class _PresetSettings extends OutputSettingsController {
  _PresetSettings(this.preset);

  final OutputSettings preset;

  @override
  OutputSettings build() => preset;
}

SelectedImage item(int i, {CropRect? crop}) => SelectedImage(
      path: '/nonexistent/shot_$i.png',
      thumbnailPath: '/nonexistent/thumb_$i.jpg',
      displayName: 'shot_$i.png',
      width: 1080,
      height: 2340,
      bytes: 800000,
      mime: 'image/png',
      crop: crop,
    );

/// 테스트 글꼴은 모든 글자의 폭이 1em이라 실제 글꼴보다 넓다. 여기서 넘치지 않으면 실제로도 넘치지 않는다.
void main() {
  late AppDatabase database;
  late Directory cache;

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    database = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    cache = await Directory.systemTemp.createTemp('localized_layout_test');
  });
  tearDown(() async {
    await database.close();
    await cache.delete(recursive: true);
  });

  Future<void> pump(
    WidgetTester tester,
    Locale locale,
    Size size, {
    List<SelectedImage> items = const [],
    OutputSettings settings = const OutputSettings(),
    double navBar = 0,
    FakeNativeBridge? bridge,
    FolderRef? folder,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = FakeViewPadding(bottom: navBar);
    tester.view.padding = FakeViewPadding(bottom: navBar);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appServicesProvider.overrideWithValue(AppServices(
          bridge: bridge ?? FakeNativeBridge(cacheDirPath: cache.path),
          database: database,
          tempStorage: TempStorage(cache.path),
          initialFolder: folder,
        )),
        selectionProvider.overrideWith(() => _PresetSelection(items)),
        outputSettingsProvider.overrideWith(() => _PresetSettings(settings)),
      ],
      child: ImageMergerApp(locale: locale),
    ));
    await tester.pump();
  }

  /// 넘치면 레이아웃 오류가 나서 takeException에 잡힌다.
  void expectBottomBarIntact(WidgetTester tester, AppLocalizations l, Size size, {double navBar = 0}) {
    for (final label in [l.saveAs('PNG'), l.saveAs('PDF'), l.share]) {
      final button = find.ancestor(of: find.text(label), matching: find.byWidgetPredicate((w) => w is FilledButton));
      expect(button, findsOneWidget, reason: label);
      final rect = tester.getRect(button);
      expect(rect.left, greaterThanOrEqualTo(0), reason: label);
      expect(rect.right, lessThanOrEqualTo(size.width), reason: label);
      expect(rect.bottom, lessThanOrEqualTo(size.height - navBar), reason: '$label: 내비게이션 바 위');
    }
  }

  for (final locale in AppLocalizations.supportedLocales) {
    final name = locale.toLanguageTag();
    final l = lookupAppLocalizations(locale);

    group('$name 360×640', () {
      const size = Size(360, 640);
      final items = [item(1), item(2, crop: const CropRect(0, 0, 1, 0.5)), item(3)];

      testWidgets('항목 있음: 설정과 하단 버튼이 넘치지 않는다', (tester) async {
        await pump(tester, locale, size, items: items);

        expect(tester.takeException(), isNull);
        expectBottomBarIntact(tester, l, size);
        expect(find.byType(SegmentedButton<PaperOrientation>), findsOneWidget);
        expect(find.byType(SegmentedButton<bool>), findsOneWidget);
        expect(find.byKey(const ValueKey('images-per-paper')), findsOneWidget);
        expect(find.byKey(const ValueKey('image-size')), findsOneWidget);
        expect(find.byKey(const ValueKey('margin')), findsOneWidget);
        expect(find.byType(SegmentedButton<int>), findsOneWidget);
        expect(find.text(l.margin), findsOneWidget);
      });

      testWidgets('항목 없음: 안내와 하단 버튼이 넘치지 않는다', (tester) async {
        await pump(tester, locale, size);

        expect(tester.takeException(), isNull);
        expectBottomBarIntact(tester, l, size);
        expect(find.text(l.pickImages), findsOneWidget);
      });

      testWidgets('1장: 안내 문구가 있어도 넘치지 않는다', (tester) async {
        await pump(tester, locale, size, items: [item(1)]);

        expect(tester.takeException(), isNull);
        expect(find.text(l.needMinImages(2)), findsOneWidget);
        expectBottomBarIntact(tester, l, size);
      });

      testWidgets('3버튼 내비게이션 바가 있어도 버튼이 그 위에 있다', (tester) async {
        await pump(tester, locale, size, items: items, navBar: 48);

        expect(tester.takeException(), isNull);
        expectBottomBarIntact(tester, l, size, navBar: 48);
      });

      group('폴더 변경 창', () {
        const documents = FolderRef(uri: 'content://tree/docs', name: 'Documents');

        testWidgets('버튼이 모두 있고 넘치지 않는다', (tester) async {
          await pump(tester, locale, size, items: items, folder: documents);

          await tester.tap(find.text(l.changeFolder));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text(l.folderDialogBodyAndroid), findsOneWidget);
          for (final label in [l.useDefaultFolder('Download'), l.pickOtherFolder, l.cancel]) {
            expect(find.text(label), findsOneWidget, reason: label);
            final button = tester.getRect(find.text(label));
            final dialog = tester.getRect(find.byType(AlertDialog));
            expect(button.left, greaterThanOrEqualTo(dialog.left), reason: label);
            expect(button.right, lessThanOrEqualTo(dialog.right), reason: label);
          }
        });

        testWidgets('접근할 수 없다는 안내까지 있어도 넘치지 않고 끝까지 스크롤된다', (tester) async {
          final bridge = FakeNativeBridge(cacheDirPath: cache.path)..inaccessibleUris.add(documents.uri);
          await pump(tester, locale, size, items: items, folder: documents, bridge: bridge);

          await tester.tap(find.text(l.saveAs('PNG')));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text(l.errorFolderUnavailable), findsOneWidget);
          await tester.ensureVisible(find.text(l.cancel));
          await tester.pumpAndSettle();
          expect(tester.getRect(find.text(l.cancel)).bottom, lessThanOrEqualTo(size.height));
        });

        testWidgets('기본 폴더가 없는 기기의 첫 저장 창도 넘치지 않는다', (tester) async {
          final bridge = FakeNativeBridge(cacheDirPath: cache.path)..defaultFolderRef = null;
          await pump(tester, locale, size, items: items, bridge: bridge);

          await tester.tap(find.text(l.saveAs('PNG')));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text(l.pickFolder), findsOneWidget);
        });
      });

      testWidgets('원본 크기 설정에서도 넘치지 않는다', (tester) async {
        await pump(
          tester,
          locale,
          size,
          items: items,
          settings: const OutputSettings(paper: PaperSize.original, grayscale: true),
        );

        expect(tester.takeException(), isNull);
        expect(find.text(l.paperOriginal), findsOneWidget);
        expect(find.byType(SegmentedButton<int>), findsOneWidget);
      });

      group('메뉴', () {
        Future<void> openDrawer(WidgetTester tester) async {
          await tester.tap(find.byIcon(Icons.menu));
          await tester.pumpAndSettle();
        }

        Future<void> openAbout(WidgetTester tester) async {
          await openDrawer(tester);
          await tester.tap(find.text(l.aboutTitle));
          await tester.pumpAndSettle();
        }

        Future<void> openTile(WidgetTester tester, String title) async {
          await openAbout(tester);
          await tester.tap(find.widgetWithText(ListTile, title));
          await tester.pumpAndSettle();
        }

        testWidgets('서랍이 넘치지 않는다', (tester) async {
          await pump(tester, locale, size, items: items);

          await openDrawer(tester);

          expect(tester.takeException(), isNull);
          expect(find.text(l.aboutTitle), findsOneWidget);
          expect(find.text(l.sendFeedback), findsOneWidget);
        });

        testWidgets('프로그램 정보가 넘치지 않고 세 항목이 화면 안에 있다', (tester) async {
          await pump(tester, locale, size, items: items, navBar: 48);

          await openAbout(tester);

          expect(tester.takeException(), isNull);
          expect(find.text('1.0.0 (1)'), findsOneWidget);
          for (final title in [l.termsTitle, l.privacyTitle, l.openSourceLicenses]) {
            final tile = find.widgetWithText(ListTile, title);
            await tester.ensureVisible(tile);
            await tester.pumpAndSettle();
            expect(tester.getRect(tile).bottom, lessThanOrEqualTo(size.height - 48), reason: title);
          }
        });

        for (final (label, title, body) in [
          ('이용약관', l.termsTitle, l.termsBody),
          ('개인정보 처리방침', l.privacyTitle, l.privacyBody),
        ]) {
          testWidgets('$label이 넘치지 않고 끝까지 스크롤된다', (tester) async {
            await pump(tester, locale, size, items: items, navBar: 48);

            await openTile(tester, title);

            expect(tester.takeException(), isNull);
            final text = find.text(body);
            expect(text, findsOneWidget);
            await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -200000));
            await tester.pumpAndSettle();
            expect(tester.getRect(text).bottom, lessThanOrEqualTo(size.height - 48));
          });
        }

        testWidgets('오픈소스 라이선스가 넘치지 않는다', (tester) async {
          LicenseRegistry.addLicense(
            () => Stream.value(const LicenseEntryWithLineBreaks(['example_package'], 'Example license text')),
          );
          addTearDown(LicenseRegistry.reset);
          await pump(tester, locale, size, items: items);

          await openTile(tester, l.openSourceLicenses);

          expect(tester.takeException(), isNull);
          expect(find.byType(LicensePage), findsOneWidget);

          await tester.tap(find.text('example_package'));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Example license text'), findsOneWidget);
        });

        testWidgets('메일 앱이 없을 때의 창이 넘치지 않는다', (tester) async {
          final bridge = FakeNativeBridge(cacheDirPath: cache.path)..composeEmailResult = false;
          await pump(tester, locale, size, items: items, bridge: bridge);

          await openDrawer(tester);
          await tester.tap(find.text(l.sendFeedback));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text(l.copyAddress), findsOneWidget);
        });
      });

      testWidgets('큰 화면(360×800)에서 미리보기까지 넘치지 않는다', (tester) async {
        await pump(tester, locale, const Size(360, 800), items: items, navBar: 48);

        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('preview-page-0')), findsOneWidget);
      });
    });

    testWidgets('$name 360×640에서 미리보기가 보이고 넘치지 않는다', (tester) async {
      await pump(tester, locale, const Size(360, 640), items: [item(1), item(2), item(3)]);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('preview-page-0')), findsOneWidget);
      expect(find.text(l.previewSummary(3, 1)), findsOneWidget);
    });

    testWidgets('$name 360×640에 상태·내비게이션 바가 있어도 미리보기가 보이고 넘치지 않는다', (tester) async {
      await pump(tester, locale, const Size(360, 640), items: [item(1), item(2), item(3)], navBar: 48);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('preview-page-0')), findsOneWidget);
      expectBottomBarIntact(tester, l, const Size(360, 640), navBar: 48);
    });

    testWidgets('$name 폰 가로에 옆쪽 내비게이션 바가 있어도 넘치지 않는다', (tester) async {
      tester.view.physicalSize = const Size(740, 360);
      tester.view.devicePixelRatio = 1;
      const insets = FakeViewPadding(right: 48);
      tester.view.viewPadding = insets;
      tester.view.padding = insets;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          appServicesProvider.overrideWithValue(AppServices(
            bridge: FakeNativeBridge(cacheDirPath: cache.path),
            database: database,
            tempStorage: TempStorage(cache.path),
          )),
          selectionProvider.overrideWith(() => _PresetSelection([item(1), item(2)])),
        ],
        child: ImageMergerApp(locale: locale),
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(tester.getRect(find.text(l.clearList)).right, lessThanOrEqualTo(692));
    });

    testWidgets('$name 폰 가로 740×360에서 넘치지 않는다', (tester) async {
      await pump(tester, locale, const Size(740, 360), items: [item(1), item(2)]);

      expect(tester.takeException(), isNull);
      expectBottomBarIntact(tester, l, const Size(740, 360));
    });

    testWidgets('$name 최근 기록 시트와 공유 시트가 넘치지 않는다', (tester) async {
      await pump(tester, locale, const Size(360, 640), items: [item(1), item(2)]);

      await tester.tap(find.text(l.share));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(l.shareAs('PNG')), findsOneWidget);
    });
  }
}
