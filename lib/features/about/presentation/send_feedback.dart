import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/platform/native_bridge.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/feedback.dart';

/// 기기의 메일 앱을 받는 사람과 제목만 채워 연다. 내용은 사용자가 쓰고 보내는 것도 사용자가 한다.
/// 메일 앱이 없으면 주소를 보여주고 복사할 수 있게 한다 (DESIGN §2.2).
Future<void> sendFeedback(BuildContext context, NativeBridge bridge) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  var opened = false;
  try {
    final info = await bridge.appInfo();
    opened = await bridge.composeEmail(to: kFeedbackAddress, subject: feedbackSubject(info));
  } on PlatformException {
    opened = false;
  }
  if (opened || !context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: Text(l.noMailAppTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Text(l.noMailAppBody),
          const SelectableText(kFeedbackAddress),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(const ClipboardData(text: kFeedbackAddress));
            if (context.mounted) Navigator.pop(context);
            messenger.showSnackBar(SnackBar(content: Text(l.addressCopied)));
          },
          child: Text(l.copyAddress),
        ),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.ok)),
      ],
    ),
  );
}
