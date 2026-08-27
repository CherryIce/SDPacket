enum EntryBatchSource { camera, gallery }

class EntryBatch {
  const EntryBatch({
    required this.id,
    required this.projectId,
    required this.source,
    required this.boxIds,
    required this.nextIndex,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String projectId;
  final EntryBatchSource source;
  final List<String> boxIds;
  final int nextIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasBoxes => boxIds.isNotEmpty;
  bool get isFinished => hasBoxes && nextIndex >= boxIds.length;
  int get safeNextIndex => nextIndex.clamp(0, boxIds.length);

  EntryBatch copyWith({
    List<String>? boxIds,
    int? nextIndex,
    DateTime? updatedAt,
  }) {
    return EntryBatch(
      id: id,
      projectId: projectId,
      source: source,
      boxIds: boxIds ?? this.boxIds,
      nextIndex: nextIndex ?? this.nextIndex,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'projectId': projectId,
    'source': source.name,
    'boxIds': boxIds,
    'nextIndex': nextIndex,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory EntryBatch.fromJson(Map<String, Object?> json) {
    final boxIds = json['boxIds'];
    if (boxIds is! List) throw const FormatException('Invalid batch boxes');
    return EntryBatch(
      id: _requiredString(json, 'id'),
      projectId: _requiredString(json, 'projectId'),
      source: EntryBatchSource.values.byName(
        json['source'] as String? ?? EntryBatchSource.gallery.name,
      ),
      boxIds: boxIds.map((value) => value as String).toList(growable: false),
      nextIndex: (json['nextIndex'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(_requiredString(json, 'createdAt')),
      updatedAt: DateTime.parse(_requiredString(json, 'updatedAt')),
    );
  }
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('Missing required batch field');
  }
  return value;
}
