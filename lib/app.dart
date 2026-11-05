import 'package:flutter/material.dart';

import 'features/image_merger/presentation/home_page.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_resolution.dart';
import 'shared/theme.dart';

class ImageMergerApp extends StatelessWidget {
  const ImageMergerApp({super.key, this.locale});

  /// 앱 안에 언어 설정은 없다 (DESIGN §2.2). 테스트에서 언어를 고정할 때만 준다.
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: resolveAppLocale,
      home: const HomePage(),
    );
  }
}
