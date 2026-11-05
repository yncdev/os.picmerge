import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_merger/shared/theme.dart';

/// WCAG 명암비. [foreground]가 반투명이면 [background] 위에 합친 색으로 잰다.
double contrast(Color foreground, Color background) {
  final fg = Color.alphaBlend(foreground, background).computeLuminance();
  final bg = background.computeLuminance();
  final (light, dark) = fg > bg ? (fg, bg) : (bg, fg);
  return (light + 0.05) / (dark + 0.05);
}

void main() {
  final colors = buildAppTheme().colorScheme;

  test('명암비 계산: 흰색과 검정은 21:1 (WCAG 정의)', () {
    expect(contrast(Colors.white, Colors.black), closeTo(21, 0.01));
  });

  test('주 색상과 그 위 글자의 명암비는 4.5:1 이상 (DESIGN §2.2)', () {
    expect(contrast(colors.onPrimary, colors.primary), greaterThanOrEqualTo(4.5));
  });

  group('하단 영역 버튼', () {
    final style = saveBarButtonStyle(colors);
    const enabled = <WidgetState>{};
    const disabled = {WidgetState.disabled};

    test('켜졌을 때: 밝은 바탕에 주 색상 글자, 4.5:1 이상, 배경과 구분된다', () {
      final fill = style.backgroundColor!.resolve(enabled)!;
      final label = style.foregroundColor!.resolve(enabled)!;

      expect(fill, colors.onPrimary);
      expect(label, colors.primary);
      expect(contrast(label, fill), greaterThanOrEqualTo(4.5));
      expect(contrast(fill, colors.primary), greaterThanOrEqualTo(3));
    });

    test('꺼졌을 때: 켜졌을 때보다 분명히 어둡지만 글자는 읽을 수 있다', () {
      final fill = Color.alphaBlend(style.backgroundColor!.resolve(disabled)!, colors.primary);
      final label = style.foregroundColor!.resolve(disabled)!;

      expect(
        fill.computeLuminance(),
        lessThan(colors.onPrimary.computeLuminance() / 2),
        reason: '켜진 버튼의 바탕보다 어둡다',
      );
      expect(contrast(label, fill), greaterThanOrEqualTo(3), reason: '흐리지만 읽히는 명암비');
    });
  });

  group('navBarOverlayStyle', () {
    late BuildContext captured;

    Future<SystemUiOverlayStyle> styleFor(WidgetTester tester, Color background, {required double inset}) async {
      await tester.pumpWidget(MediaQuery(
        data: MediaQueryData(viewPadding: EdgeInsets.only(bottom: inset)),
        child: Builder(builder: (context) {
          captured = context;
          return const SizedBox.shrink();
        }),
      ));
      return navBarOverlayStyle(captured, background: background);
    }

    testWidgets('바 뒤까지 그리면 투명한 바에 대비 강제 끔, 어두운 배경은 밝은 아이콘', (tester) async {
      final style = await styleFor(tester, colors.primary, inset: 48);

      expect(style.systemNavigationBarColor, Colors.transparent);
      expect(style.systemNavigationBarContrastEnforced, isFalse);
      expect(style.systemNavigationBarIconBrightness, Brightness.light);
    });

    testWidgets('밝은 배경은 어두운 아이콘', (tester) async {
      final style = await styleFor(tester, colors.surface, inset: 48);

      expect(style.systemNavigationBarColor, Colors.transparent);
      expect(style.systemNavigationBarIconBrightness, Brightness.dark);
    });

    testWidgets('바 뒤에 그리지 못하는 옛 Android는 배경색을 바에 칠해 흰 아이콘이 보이게 한다', (tester) async {
      final style = await styleFor(tester, colors.primary, inset: 0);

      expect(style.systemNavigationBarColor, colors.primary);
      expect(style.systemNavigationBarIconBrightness, Brightness.light);
    });

    Future<SystemUiOverlayStyle> sideStyleFor(WidgetTester tester, {required EdgeInsets viewPadding}) async {
      await tester.pumpWidget(MediaQuery(
        data: MediaQueryData(viewPadding: viewPadding),
        child: Builder(builder: (context) {
          captured = context;
          return const SizedBox.shrink();
        }),
      ));
      return navBarOverlayStyle(captured, background: colors.primary, sideBackground: colors.surface);
    }

    testWidgets('바가 옆에 있으면 옆쪽 배경을 기준으로 아이콘 색을 정한다', (tester) async {
      final style = await sideStyleFor(tester, viewPadding: const EdgeInsets.only(right: 48));

      expect(style.systemNavigationBarColor, Colors.transparent);
      expect(style.systemNavigationBarIconBrightness, Brightness.dark);
    });

    testWidgets('아래에 바가 있으면 옆의 인셋(화면 구멍 등)이 있어도 아래쪽 배경을 따른다', (tester) async {
      final style = await sideStyleFor(tester, viewPadding: const EdgeInsets.only(left: 30, bottom: 24));

      expect(style.systemNavigationBarIconBrightness, Brightness.light);
    });

    testWidgets('옛 Android의 밝은 시트는 검은 바에 흰 아이콘이다 (API 26 미만은 아이콘 색을 바꿀 수 없다)', (tester) async {
      final style = await styleFor(tester, colors.surface, inset: 0);

      expect(style.systemNavigationBarColor, Colors.black);
      expect(style.systemNavigationBarIconBrightness, Brightness.light);
    });
  });
}
