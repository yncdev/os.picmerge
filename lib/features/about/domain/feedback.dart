import '../../../core/app_info.dart';

/// 의견 보내기 받는 사람 (DESIGN §2.2).
const kFeedbackAddress = 'yncdev@gmail.com';

/// `1.0.0 (1)`
String appVersionLabel(AppInfo info) => '${info.versionName} (${info.buildNumber})';

/// 의견 보내기 제목. 받는 쪽에서 읽기 쉽게 기기 언어와 무관하게 영어다 (DESIGN §2.2).
/// 예: `Pic Merge inquiry - App: Pic Merge 1.0.0 (1), Device: samsung SM-S938N, OS: Android 17`
String feedbackSubject(AppInfo info) => 'Pic Merge inquiry - App: Pic Merge ${appVersionLabel(info)}, '
    'Device: ${info.manufacturer} ${info.model}, OS: ${info.osName} ${info.osVersion}';
