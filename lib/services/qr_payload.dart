class BoxQrPayload {
  const BoxQrPayload({
    required this.projectId,
    required this.boxId,
    required this.code,
  });

  static const String prefix = 'MOVEBOX';
  static const String version = '1';

  final String projectId;
  final String boxId;
  final String code;

  String encode() => [
    prefix,
    'v=$version',
    'project=${Uri.encodeComponent(projectId)}',
    'box=${Uri.encodeComponent(boxId)}',
    'code=${Uri.encodeComponent(code)}',
  ].join('|');

  static BoxQrPayload? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('|');
    if (parts.length != 5 || parts.first != prefix) return null;
    final values = <String, String>{};
    for (final part in parts.skip(1)) {
      final separator = part.indexOf('=');
      if (separator <= 0) return null;
      values[part.substring(0, separator)] = Uri.decodeComponent(
        part.substring(separator + 1),
      );
    }
    if (values['v'] != version ||
        (values['project'] ?? '').isEmpty ||
        (values['box'] ?? '').isEmpty ||
        (values['code'] ?? '').isEmpty) {
      return null;
    }
    return BoxQrPayload(
      projectId: values['project']!,
      boxId: values['box']!,
      code: values['code']!,
    );
  }
}
