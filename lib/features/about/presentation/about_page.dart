import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_info.dart';
import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme.dart';
import '../domain/feedback.dart';
import 'legal_text_page.dart';

/// 프로그램 정보 (DESIGN §2.2). 버전은 설치된 앱에서 읽는다.
class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> {
  late final Future<AppInfo> _info = ref.read(appServicesProvider).bridge.appInfo();

  void _openLegalText(String title, String body) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LegalTextPage(title: title, body: body)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: navBarOverlayStyle(context, background: theme.colorScheme.surface),
      child: Scaffold(
        appBar: AppBar(title: Text(l.aboutTitle)),
        body: SafeArea(
          top: false,
          child: FutureBuilder<AppInfo>(
            future: _info,
            builder: (context, snapshot) {
              final info = snapshot.data;
              final version = info == null ? null : appVersionLabel(info);
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(l.appName, style: theme.textTheme.headlineSmall),
                  ),
                  ListTile(title: Text(l.version), subtitle: Text(version ?? '')),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(l.termsTitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openLegalText(l.termsTitle, l.termsBody),
                  ),
                  ListTile(
                    title: Text(l.privacyTitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openLegalText(l.privacyTitle, l.privacyBody),
                  ),
                  ListTile(
                    title: Text(l.openSourceLicenses),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: l.appName,
                      applicationVersion: version,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
