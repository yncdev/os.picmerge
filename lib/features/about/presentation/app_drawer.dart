import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme.dart';

/// 메인 화면의 메뉴 (DESIGN §2.2). 서랍은 밝아서 메인 화면의 밝은 시스템 아이콘이 보이지 않으므로 함께 바꾼다.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.onAbout, required this.onFeedback});

  final VoidCallback onAbout;
  final VoidCallback onFeedback;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final surface = Theme.of(context).colorScheme.surface;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: navBarOverlayStyle(context, background: surface).copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l.aboutTitle),
                onTap: () {
                  Navigator.pop(context);
                  onAbout();
                },
              ),
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: Text(l.sendFeedback),
                onTap: () {
                  Navigator.pop(context);
                  onFeedback();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
