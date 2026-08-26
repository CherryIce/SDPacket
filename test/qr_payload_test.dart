import 'package:flutter_test/flutter_test.dart';
import 'package:moving_box/services/qr_payload.dart';

void main() {
  test('round trips stable project and box identity', () {
    const source = BoxQrPayload(
      projectId: 'project-id',
      boxId: 'box-id',
      code: 'C-009',
    );
    final decoded = BoxQrPayload.tryParse(source.encode());

    expect(decoded, isNotNull);
    expect(decoded!.projectId, source.projectId);
    expect(decoded.boxId, source.boxId);
    expect(decoded.code, source.code);
  });

  test('rejects unsupported or privacy-heavy arbitrary payloads', () {
    expect(BoxQrPayload.tryParse('https://example.com/full-item-list'), isNull);
    expect(
      BoxQrPayload.tryParse('MOVEBOX|v=2|project=p|box=b|code=C-1'),
      isNull,
    );
    expect(BoxQrPayload.tryParse('MOVEBOX|v=1|project=p|box=b'), isNull);
  });
}
