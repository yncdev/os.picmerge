import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_merger/features/image_merger/data/pdf_assembler.dart';
import 'package:image_merger/features/image_merger/domain/page_layout.dart';

Uint8List jpeg(int w, int h, int r) =>
    img.encodeJpg(img.Image(width: w, height: h)..clear(img.ColorRgb8(r, 100, 50)), quality: 80);

int indexOfBytes(Uint8List haystack, Uint8List needle) {
  outer:
  for (var i = 0; i <= haystack.length - needle.length; i++) {
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) continue outer;
    }
    return i;
  }
  return -1;
}

/// PDF의 압축된 스트림을 풀어 이어 붙인 텍스트. 페이지 그리기 명령을 확인할 때 쓴다.
String inflatedStreams(Uint8List pdf) {
  final buffer = StringBuffer();
  final text = latin1.decode(pdf);
  for (final m in RegExp(r'stream\r?\n').allMatches(text)) {
    final end = text.indexOf('endstream', m.end);
    if (end < 0) continue;
    try {
      buffer.writeln(latin1.decode(zlib.decode(pdf.sublist(m.end, end))));
    } on FormatException {
      // JPEG(DCTDecode) 스트림은 zlib이 아니다.
    }
  }
  return buffer.toString();
}

void main() {
  test('용지 페이지: 이미지를 왼쪽 위 기준 좌표에 놓는다', () async {
    final assembler = PdfAssembler()
      ..addImage(jpeg(40, 20, 200), const LayoutRect(0, 250, 600, 300))
      ..finishPage(widthPt: 600, heightPt: 800);
    final pdf = await assembler.save();

    expect(latin1.decode(pdf), matches(RegExp(r'/MediaBox\s*\[\s*0\s+0\s+600')));
    // PDF 좌표는 왼쪽 아래가 원점이다. 위 250, 높이 300이면 아래 800 − 250 − 300 = 250.
    final drawing = inflatedStreams(pdf);
    expect(drawing, contains('1 0 0 1 0 250 cm'));
    expect(drawing, contains('600 0 0 300 0 0 cm'));
  });

  test('한 페이지에 이미지 여러 장을 모은 뒤 내보낸다. 선이나 사각형은 그리지 않는다', () async {
    final assembler = PdfAssembler()
      ..addImage(jpeg(40, 20, 200), const LayoutRect(0, 0, 600, 300))
      ..addImage(jpeg(40, 20, 20), const LayoutRect(0, 500, 600, 300))
      ..finishPage(widthPt: 600, heightPt: 800);
    expect(assembler.pageCount, 1);
    final pdf = await assembler.save();
    final text = latin1.decode(pdf);

    expect(RegExp(r'/Type\s*/Page(?!s)').allMatches(text).length, 1);
    final drawing = inflatedStreams(pdf);
    // 위 0 → 아래 800 − 0 − 300 = 500, 위 500 → 아래 0
    expect(drawing, contains('1 0 0 1 0 500 cm'));
    expect(drawing, contains('1 0 0 1 0 0 cm'));
    expect(RegExp(r'/I\d+ Do').allMatches(drawing).length, 2);
    // pw.Image가 쓰는 `re W n`은 칠하지 않는 잘라내기 영역이다.
    expect(RegExp(r'\bre\b(?! W n)').hasMatch(drawing), isFalse, reason: '사각형을 그리지 않는다');
    expect(RegExp(r'\b[lSsfF]\b').hasMatch(drawing), isFalse, reason: '선이나 채우기가 없다');
  });

  test('페이지마다 이미지를 나눠 담고, JPEG를 다시 인코딩하지 않고 그대로 넣는다', () async {
    final first = jpeg(40, 30, 200);
    final second = jpeg(30, 60, 20);
    final assembler = PdfAssembler()
      ..addImage(first, const LayoutRect(0, 0, 841.89, 631.42))
      ..finishPage(widthPt: 841.89, heightPt: 631.42)
      ..addImage(second, const LayoutRect(0, 0, 420.94, 841.89))
      ..finishPage(widthPt: 420.94, heightPt: 841.89);
    final pdf = await assembler.save();
    final text = latin1.decode(pdf);

    expect(text.startsWith('%PDF'), isTrue);
    expect(assembler.pageCount, 2);
    expect(RegExp(r'/Type\s*/Page(?!s)').allMatches(text).length, 2);
    expect(text, contains('/DCTDecode'));
    expect(indexOfBytes(pdf, first), greaterThan(0), reason: '첫 JPEG 바이트가 그대로 들어 있어야 한다');
    expect(indexOfBytes(pdf, second), greaterThan(0));
    // 페이지 크기 (여백 없음)
    expect(text, matches(RegExp(r'/MediaBox\s*\[\s*0\s+0\s+841\.89')));
  });
}
