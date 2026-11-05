import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 실제 파일 I/O는 가짜 시계에서 끝나지 않아, 실제 시간을 주고 그때마다 화면을 다시 그린다.
/// 기다리는 시간을 고정하면 테스트가 몰릴 때 실패하므로 [condition]이 참이 될 때까지 기다리고,
/// 그 뒤 화면 전환이 끝나도록 가짜 시계를 더 돌린다.
Future<void> pumpUntil(WidgetTester tester, bool Function() condition) async {
  const attempts = 1000; // 20ms씩 약 20초
  for (var i = 0; !condition(); i++) {
    if (i == attempts) throw TestFailure('기다리던 상태가 되지 않았습니다');
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 100));
  }
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Windows는 열려 있는 파일이 든 폴더를 지우지 못한다. 위젯이 해제되며 임시 파일을 닫는 동안 다시 시도한다.
/// 끝내 지우지 못해도 시스템 임시 폴더라 시험 결과와는 상관없다.
Future<void> deleteTempDir(Directory dir) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    try {
      await dir.delete(recursive: true);
      return;
    } on FileSystemException {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }
}
