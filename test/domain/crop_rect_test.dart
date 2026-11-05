import 'package:flutter_test/flutter_test.dart';
import 'package:image_merger/core/crop_rect.dart';
import 'package:image_merger/core/image_size.dart';

void main() {
  group('applyTo', () {
    test('비율 좌표를 픽셀 크기로 바꾼다', () {
      expect(const CropRect(0.25, 0, 0.75, 0.5).applyTo(const ImageSize(4000, 3000)),
          const ImageSize(2000, 1500));
    });

    test('아주 작은 영역도 1px 이상이고, 원본을 넘지 않는다', () {
      expect(const CropRect(0, 0, 0.001, 0.001).applyTo(const ImageSize(100, 100)),
          const ImageSize(1, 1));
      expect(CropRect.full.applyTo(const ImageSize(7, 9)), const ImageSize(7, 9));
    });
  });

  group('drag', () {
    const rect = CropRect(0.2, 0.2, 0.8, 0.8);

    test('모서리는 두 변을, 변은 한 변만 옮긴다', () {
      final corner = rect.drag(CropHandle.bottomRight, -0.1, -0.2);
      expect(corner.right, closeTo(0.7, 1e-9));
      expect(corner.bottom, closeTo(0.6, 1e-9));
      expect((corner.left, corner.top), (0.2, 0.2));

      final edge = rect.drag(CropHandle.left, 0.1, 0.5);
      expect(edge.left, closeTo(0.3, 1e-9));
      expect((edge.top, edge.right, edge.bottom), (0.2, 0.8, 0.8));
    });

    test('경계 밖으로 나가지 않는다', () {
      final r = rect.drag(CropHandle.topLeft, -1, -1);
      expect((r.left, r.top), (0.0, 0.0));
      final b = rect.drag(CropHandle.bottomRight, 1, 1);
      expect((b.right, b.bottom), (1.0, 1.0));
    });

    test('가로·세로 모두 2%보다 작아지지 않고, 변이 뒤집히지 않는다', () {
      final r = rect.drag(CropHandle.right, -5, 0);
      expect(r.width, closeTo(CropRect.minFraction, 1e-9));
      final t = rect.drag(CropHandle.top, 0, 5);
      expect(t.height, closeTo(CropRect.minFraction, 1e-9));
    });

    test('옮기기는 크기를 유지하고 경계에서 멈춘다', () {
      final moved = rect.drag(CropHandle.move, 0.1, -0.1);
      expect(moved.width, closeTo(0.6, 1e-9));
      expect(moved.height, closeTo(0.6, 1e-9));
      expect(moved.left, closeTo(0.3, 1e-9));
      expect(moved.top, closeTo(0.1, 1e-9));

      final stopped = rect.drag(CropHandle.move, 9, 9);
      expect(stopped.right, 1.0);
      expect(stopped.bottom, 1.0);
      expect(stopped.width, closeTo(0.6, 1e-9));
    });
  });

  group('cropHandleAt', () {
    const rect = CropRect(0.2, 0.2, 0.8, 0.8);
    CropHandle? at(double x, double y) => cropHandleAt(rect, x, y, 0.05, 0.05);

    test('모서리, 변, 안쪽, 바깥을 구분한다', () {
      expect(at(0.2, 0.2), CropHandle.topLeft);
      expect(at(0.82, 0.18), CropHandle.topRight);
      expect(at(0.8, 0.8), CropHandle.bottomRight);
      expect(at(0.2, 0.8), CropHandle.bottomLeft);
      expect(at(0.5, 0.2), CropHandle.top);
      expect(at(0.8, 0.5), CropHandle.right);
      expect(at(0.5, 0.8), CropHandle.bottom);
      expect(at(0.2, 0.5), CropHandle.left);
      expect(at(0.5, 0.5), CropHandle.move);
      expect(at(0.05, 0.05), isNull);
      expect(at(0.5, 0.95), isNull);
    });

    test('작은 영역도 가운데를 끌면 옮기고, 모서리와 변은 바깥에서 잡을 수 있다', () {
      const small = CropRect(0.5, 0.5, 0.52, 0.52);
      expect(cropHandleAt(small, 0.51, 0.51, 0.05, 0.05), CropHandle.move);
      expect(cropHandleAt(small, 0.49, 0.49, 0.05, 0.05), CropHandle.topLeft);
      expect(cropHandleAt(small, 0.53, 0.53, 0.05, 0.05), CropHandle.bottomRight);
      expect(cropHandleAt(small, 0.51, 0.48, 0.05, 0.05), CropHandle.top);
    });

    test('허용 범위보다 좁은 영역은 가까운 변을 잡는다', () {
      const thin = CropRect(0.5, 0.2, 0.52, 0.8);
      expect(cropHandleAt(thin, 0.53, 0.5, 0.05, 0.05), CropHandle.right);
      expect(cropHandleAt(thin, 0.49, 0.5, 0.05, 0.05), CropHandle.left);
    });

    test('영역 높이가 낮으면(글자 한 줄) 가운데를 끌어도 위 변이 잡히지 않는다', () {
      const line = CropRect(0.1, 0.45, 0.9, 0.5);
      expect(cropHandleAt(line, 0.5, 0.475, 0.05, 0.05), CropHandle.move);
    });
  });

  group('플랫폼 채널 값', () {
    test('전체 영역이면 null, 아니면 [왼쪽, 위, 오른쪽, 아래]', () {
      expect(CropRect.full.toChannelValue(), isNull);
      expect(const CropRect(0.1, 0.2, 0.3, 0.4).toChannelValue(), [0.1, 0.2, 0.3, 0.4]);
    });
  });
}
