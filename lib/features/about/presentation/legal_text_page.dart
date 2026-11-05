import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/theme.dart';

/// 이용약관과 개인정보 처리방침 (DESIGN §2.2). 인터넷 없이 읽을 수 있게 문구는 번역 파일에 있다.
class LegalTextPage extends StatelessWidget {
  const LegalTextPage({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: navBarOverlayStyle(context, background: Theme.of(context).colorScheme.surface),
      child: Scaffold(
        appBar: AppBar(
          // 긴 언어에서 제목이 잘리지 않게 줄인다.
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(title),
          ),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(body),
          ),
        ),
      ),
    );
  }
}
