import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import '../../../core/errors/merge_exception.dart';
import '../domain/page_layout.dart';
import 'pdf_assembler.dart';
import 'png_compositor.dart';

class PngOutput {
  const PngOutput({
    required this.width,
    required this.height,
    required this.bytes,
    required this.scale,
  });

  final int width;
  final int height;
  final int bytes;
  final double scale;
}

/// 캔버스 복사, PNG 인코딩, PDF 조립을 하는 별도 isolate (DESIGN §3.1).
/// 순수 Dart만 다루고 플랫폼 채널은 부르지 않는다.
///
/// 취소는 [kill]로 isolate를 바로 끝낸다. PNG 인코딩은 한 번의 긴 호출이라
/// 중간에 멈출 방법이 이것뿐이다. 진행 중이던 요청은 [MergeCancelled]로 끝난다.
class MergeWorker {
  MergeWorker._();

  static Future<MergeWorker> spawn() async {
    final worker = MergeWorker._();
    await worker._start();
    return worker;
  }

  final _responses = ReceivePort();
  final _exits = ReceivePort();
  final _pending = <int, Completer<Object?>>{};
  late final Isolate _isolate;
  late final SendPort _commands;
  var _nextId = 0;
  var _killed = false;
  var _exited = false;

  Future<void> _start() async {
    final ready = Completer<SendPort>();
    _responses.listen((message) {
      if (message is SendPort) {
        ready.complete(message);
      } else {
        _handleResponse(message as List<Object?>);
      }
    });
    _exits.listen((_) {
      _onExit();
      if (!ready.isCompleted) {
        ready.completeError(const MergeException(MergeErrorCode.unknown, detail: 'worker exited'));
      }
    });
    _isolate = await Isolate.spawn(
      _workerMain,
      _responses.sendPort,
      onExit: _exits.sendPort,
      debugName: 'merge_worker',
    );
    _commands = await ready.future;
  }

  Future<void> startPng({
    required int width,
    required int height,
    required int channels,
  }) =>
      _request('startPng', {'width': width, 'height': height, 'channels': channels});

  /// 워커가 [rawPath]를 읽어 캔버스에 복사한 뒤 지운다.
  Future<void> addRaw({
    required String rawPath,
    required int x,
    required int y,
    required int width,
    required int height,
  }) =>
      _request('addRaw', {'path': rawPath, 'x': x, 'y': y, 'width': width, 'height': height});

  /// 캔버스에 구분선을 칠한다.
  Future<void> drawDividers(List<PixelRect> dividers) => _request('drawDividers', {
        'rects': [
          for (final d in dividers) ...[d.x, d.y, d.width, d.height],
        ],
      });

  Future<PngOutput> finishPng({required String outPath, required int maxBytes}) async {
    final m = (await _request('finishPng', {'outPath': outPath, 'maxBytes': maxBytes}))!
        as Map<Object?, Object?>;
    return PngOutput(
      width: m['width']! as int,
      height: m['height']! as int,
      bytes: m['bytes']! as int,
      scale: m['scale']! as double,
    );
  }

  Future<void> startPdf() => _request('startPdf', const {});

  /// 워커가 [jpegPath]를 읽어 지금 페이지에 모은 뒤 지운다.
  Future<void> addPdfImage({required String jpegPath, required LayoutRect rect}) =>
      _request('addPdfImage', {
        'path': jpegPath,
        'left': rect.left,
        'top': rect.top,
        'width': rect.width,
        'height': rect.height,
      });

  /// 모은 이미지로 페이지를 만든다.
  Future<void> finishPdfPage({required double widthPt, required double heightPt}) =>
      _request('finishPdfPage', {'widthPt': widthPt, 'heightPt': heightPt});

  /// PDF를 [outPath]에 쓰고 파일 크기를 돌려준다.
  Future<int> finishPdf({required String outPath}) async =>
      (await _request('finishPdf', {'outPath': outPath}))! as int;

  /// 취소. 진행 중이던 요청은 [MergeCancelled]로 끝난다.
  void kill() {
    if (_exited) return;
    _killed = true;
    _isolate.kill(priority: Isolate.immediate);
  }

  /// 작업을 마친 뒤 정리.
  void close() {
    if (_exited) return;
    _isolate.kill(priority: Isolate.immediate);
  }

  Future<Object?> _request(String command, Map<String, Object?> args) {
    if (_exited) {
      return Future.error(_killed
          ? const MergeCancelled()
          : const MergeException(MergeErrorCode.unknown, detail: 'worker exited'));
    }
    final id = _nextId++;
    final completer = Completer<Object?>();
    _pending[id] = completer;
    _commands.send([id, command, args]);
    return completer.future;
  }

  void _handleResponse(List<Object?> message) {
    final completer = _pending.remove(message[0]! as int);
    if (completer == null) return;
    if (message[1]! as bool) {
      completer.complete(message[2]);
    } else {
      completer.completeError(MergeException(
        MergeErrorCode.fromCode(message[2] as String?),
        detail: message[3] as String?,
      ));
    }
  }

  void _onExit() {
    _exited = true;
    final Object error = _killed
        ? const MergeCancelled()
        : const MergeException(MergeErrorCode.unknown, detail: 'worker exited');
    for (final completer in _pending.values) {
      completer.completeError(error);
    }
    _pending.clear();
    _responses.close();
    _exits.close();
  }
}

// ---- 워커 isolate 안 ----

void _workerMain(SendPort responses) {
  final commands = ReceivePort();
  responses.send(commands.sendPort);
  final state = _WorkerState();
  commands.listen((message) async {
    final m = message as List<Object?>;
    final id = m[0]! as int;
    try {
      final result = await state.handle(m[1]! as String, (m[2]! as Map).cast<String, Object?>());
      responses.send([id, true, result]);
    } on MergeException catch (e) {
      responses.send([id, false, e.code.code, e.detail]);
    } on OutOfMemoryError catch (e) {
      state.reset();
      responses.send([id, false, MergeErrorCode.outOfMemory.code, '$e']);
    } on FileSystemException catch (e) {
      final noSpace = e.osError?.errorCode == 28; // ENOSPC
      responses.send([
        id,
        false,
        noSpace ? MergeErrorCode.outOfSpace.code : MergeErrorCode.unknown.code,
        '$e',
      ]);
    } catch (e) {
      responses.send([id, false, MergeErrorCode.unknown.code, '$e']);
    }
  });
}

class _WorkerState {
  PngCompositor? _png;
  PdfAssembler? _pdf;

  void reset() {
    _png = null;
    _pdf = null;
  }

  Future<Object?> handle(String command, Map<String, Object?> a) async {
    switch (command) {
      case 'startPng':
        _png = PngCompositor(
          width: a['width']! as int,
          height: a['height']! as int,
          channels: a['channels']! as int,
        );
        return null;
      case 'addRaw':
        final file = File(a['path']! as String);
        try {
          _png!.blitFile(
            file,
            x: a['x']! as int,
            y: a['y']! as int,
            width: a['width']! as int,
            height: a['height']! as int,
          );
        } finally {
          _deleteQuietly(file);
        }
        return null;
      case 'drawDividers':
        final rects = a['rects']! as List<Object?>;
        _png!.drawDividers([
          for (var i = 0; i < rects.length; i += 4)
            PixelRect(
              rects[i]! as int,
              rects[i + 1]! as int,
              rects[i + 2]! as int,
              rects[i + 3]! as int,
            ),
        ]);
        return null;
      case 'finishPng':
        final result = _png!.encode(maxBytes: a['maxBytes']! as int);
        _png = null; // 캔버스 메모리를 먼저 놓는다.
        File(a['outPath']! as String).writeAsBytesSync(result.bytes, flush: true);
        return {
          'width': result.width,
          'height': result.height,
          'bytes': result.bytes.length,
          'scale': result.scale,
        };
      case 'startPdf':
        _pdf = PdfAssembler();
        return null;
      case 'addPdfImage':
        final file = File(a['path']! as String);
        try {
          _pdf!.addImage(
            file.readAsBytesSync(),
            LayoutRect(
              a['left']! as double,
              a['top']! as double,
              a['width']! as double,
              a['height']! as double,
            ),
          );
        } finally {
          _deleteQuietly(file);
        }
        return null;
      case 'finishPdfPage':
        _pdf!.finishPage(widthPt: a['widthPt']! as double, heightPt: a['heightPt']! as double);
        return null;
      case 'finishPdf':
        final bytes = await _pdf!.save();
        _pdf = null;
        File(a['outPath']! as String).writeAsBytesSync(bytes, flush: true);
        return bytes.length;
    }
    throw ArgumentError.value(command, 'command');
  }

  void _deleteQuietly(File file) {
    try {
      file.deleteSync();
    } on FileSystemException {
      // 작업 폴더째 지워지므로 무시한다.
    }
  }
}
