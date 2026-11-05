import 'package:flutter_test/flutter_test.dart';
import 'package:image_merger/core/app_info.dart';
import 'package:image_merger/features/about/domain/feedback.dart';

void main() {
  const samsung = AppInfo(
    versionName: '1.0.0',
    buildNumber: '1',
    manufacturer: 'samsung',
    model: 'SM-S938N',
    osName: 'Android',
    osVersion: '17',
  );
  const iphone = AppInfo(
    versionName: '1.2.3',
    buildNumber: '45',
    manufacturer: 'Apple',
    model: 'iPhone16,2',
    osName: 'iOS',
    osVersion: '18.1',
  );

  test('받는 사람', () {
    expect(kFeedbackAddress, 'yncdev@gmail.com');
  });

  test('버전 표시', () {
    expect(appVersionLabel(samsung), '1.0.0 (1)');
    expect(appVersionLabel(iphone), '1.2.3 (45)');
  });

  test('Android 제목', () {
    expect(
      feedbackSubject(samsung),
      'Pic Merge inquiry - App: Pic Merge 1.0.0 (1), Device: samsung SM-S938N, OS: Android 17',
    );
  });

  test('iOS 제목', () {
    expect(
      feedbackSubject(iphone),
      'Pic Merge inquiry - App: Pic Merge 1.2.3 (45), Device: Apple iPhone16,2, OS: iOS 18.1',
    );
  });
}
