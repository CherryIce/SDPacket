class MovingProject {
  const MovingProject({
    required this.id,
    required this.name,
    required this.boxPrefix,
    required this.nextSequence,
    required this.createdAt,
    required this.updatedAt,
    this.moveDate,
    this.origin = '',
    this.destination = '',
    this.archivedAt,
  });

  final String id;
  final String name;
  final DateTime? moveDate;
  final String origin;
  final String destination;
  final String boxPrefix;
  final int nextSequence;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;

  String codeFor(int sequence) =>
      '${boxPrefix.toUpperCase()}-${sequence.toString().padLeft(3, '0')}';

  MovingProject copyWith({
    String? name,
    DateTime? moveDate,
    String? origin,
    String? destination,
    String? boxPrefix,
    int? nextSequence,
    DateTime? updatedAt,
    Object? archivedAt = _unset,
  }) {
    return MovingProject(
      id: id,
      name: name ?? this.name,
      moveDate: moveDate ?? this.moveDate,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      boxPrefix: boxPrefix ?? this.boxPrefix,
      nextSequence: nextSequence ?? this.nextSequence,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: identical(archivedAt, _unset)
          ? this.archivedAt
          : archivedAt as DateTime?,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'moveDate': moveDate?.toIso8601String(),
    'origin': origin,
    'destination': destination,
    'boxPrefix': boxPrefix,
    'nextSequence': nextSequence,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'archivedAt': archivedAt?.toIso8601String(),
  };

  factory MovingProject.fromJson(Map<String, Object?> json) {
    return MovingProject(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      moveDate: _optionalDate(json['moveDate']),
      origin: json['origin'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      boxPrefix: (json['boxPrefix'] as String? ?? 'C').trim().isEmpty
          ? 'C'
          : (json['boxPrefix'] as String).trim(),
      nextSequence: (json['nextSequence'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.parse(_requiredString(json, 'createdAt')),
      updatedAt: DateTime.parse(_requiredString(json, 'updatedAt')),
      archivedAt: _optionalDate(json['archivedAt']),
    );
  }
}

const Object _unset = Object();

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('Missing required project field');
  }
  return value;
}

DateTime? _optionalDate(Object? value) {
  if (value == null) return null;
  if (value is! String) throw const FormatException('Invalid date');
  return DateTime.parse(value);
}
