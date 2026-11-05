import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

ThemeData buildAppTheme() => ThemeData(
      colorSchemeSeed: const Color(0xFF2F6FDE),
      useMaterial3: true,
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );

/// 주 색상 배경의 하단 저장 영역 버튼 (DESIGN §2.2). 켜졌을 때는 밝게 채우고,
/// 꺼졌을 때는 배경보다 조금 밝은 바탕에 흐린 글자로 두되 읽을 수 있게 한다.
ButtonStyle saveBarButtonStyle(ColorScheme colors) => FilledButton.styleFrom(
      backgroundColor: colors.onPrimary,
      foregroundColor: colors.primary,
      disabledBackgroundColor: colors.onPrimary.withValues(alpha: 0.12),
      disabledForegroundColor: colors.onPrimary.withValues(alpha: 0.72),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

/// 화면 맨 아래가 [background]일 때의 Android 내비게이션 바 모양. `AnnotatedRegion`으로 화면마다 준다.
/// 가로 모드의 3버튼 바처럼 바가 옆에 있으면 [sideBackground]가 비친다. 없으면 [background]와 같다고 본다.
///
/// 시스템이 앱을 바 뒤까지 그리게 하면(API 29 이상의 edge-to-edge) 바를 투명하게 두어 [background]가
/// 비치게 한다. 그 아래 버전은 앱이 바 뒤에 그려지지 않아 바 아래 인셋이 0이고, 투명하게 두면 창 배경이
/// 비쳐 아이콘이 보이지 않는다. 그때는 어두운 바를 칠해 흰 아이콘을 보이게 한다. API 26 미만은
/// 아이콘 색을 바꿀 수 없어 항상 흰색이기 때문이다.
SystemUiOverlayStyle navBarOverlayStyle(
  BuildContext context, {
  required Color background,
  Color? sideBackground,
}) {
  final inset = MediaQuery.viewPaddingOf(context);
  // 아래 인셋이 있으면 옆의 인셋은 화면 구멍이다. 바는 아래에 있다.
  final barOnSide = inset.bottom == 0 && (inset.left > 0 || inset.right > 0);
  final behindBar = barOnSide ? sideBackground ?? background : background;
  final darkBackground = ThemeData.estimateBrightnessForColor(behindBar) == Brightness.dark;
  final drawnBehindBar = inset.bottom > 0 || barOnSide;
  return SystemUiOverlayStyle(
    systemNavigationBarColor:
        drawnBehindBar ? Colors.transparent : (darkBackground ? behindBar : Colors.black),
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness:
        darkBackground || !drawnBehindBar ? Brightness.light : Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );
}
