import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/page_layout.dart';

/// 한 페이지에 이미지를 모은 뒤 페이지로 내보낸다. JPEG는 다시 인코딩하지 않고 그대로(DCTDecode) 넣고,
/// 메모리에는 JPEG 바이트만 둔다. 별도 isolate 안에서만 쓴다 (DESIGN §3.1).
class PdfAssembler {
  final _document = pw.Document();
  final _pending = <pw.Widget>[];
  var _pageCount = 0;

  int get pageCount => _pageCount;

  /// 다음 [finishPage] 페이지에 넣을 이미지. [rect]는 포인트이고 왼쪽 위가 원점이다.
  void addImage(Uint8List jpeg, LayoutRect rect) {
    _pending.add(pw.Positioned(
      left: rect.left,
      top: rect.top,
      child: pw.SizedBox(
        width: rect.width,
        height: rect.height,
        child: pw.Image(pw.MemoryImage(jpeg), fit: pw.BoxFit.fill),
      ),
    ));
  }

  /// 모은 이미지로 페이지를 만든다. 빈 곳은 흰색이고 선을 긋지 않는다.
  void finishPage({required double widthPt, required double heightPt}) {
    final children = List<pw.Widget>.of(_pending);
    _pending.clear();
    _document.addPage(pw.Page(
      pageFormat: PdfPageFormat(widthPt, heightPt),
      margin: pw.EdgeInsets.zero,
      build: (_) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Stack(overflow: pw.Overflow.visible, children: children),
      ),
    ));
    _pageCount++;
  }

  Future<Uint8List> save() => _document.save();
}
