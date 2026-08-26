enum MoveStatus { draft, packed, loaded, arrived, unpacked }

enum PhysicalMarkStatus { pending, confirmed }

enum PhysicalMarkMethod { qrLabel, handwritten, stickyNote, other }

enum BoxIssue { suspectedMissing, damagedBox, damagedContents }

class BoxItem {
  const BoxItem({
    required this.id,
    required this.name,
    this.quantity,
    this.note = '',
  });

  final String id;
  final String name;
  final int? quantity;
  final String note;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'note': note,
  };

  factory BoxItem.fromJson(Map<String, Object?> json) => BoxItem(
    id: json['id'] as String,
    name: json['name'] as String,
    quantity: (json['quantity'] as num?)?.toInt(),
    note: json['note'] as String? ?? '',
  );
}

class BoxRecord {
  const BoxRecord({
    required this.id,
    required this.projectId,
    required this.shortCode,
    required this.createdAt,
    required this.updatedAt,
    this.title = '',
    this.destinationRoom = '',
    this.currentLocation = '',
    this.memo = '',
    this.tags = const [],
    this.items = const [],
    this.photoPaths = const [],
    this.isPriority = false,
    this.moveStatus = MoveStatus.draft,
    this.physicalMarkStatus = PhysicalMarkStatus.pending,
    this.physicalMarkMethod,
    this.issues = const {},
    this.labelExportedAt,
    this.physicalMarkedAt,
  });

  final String id;
  final String projectId;
  final String shortCode;
  final String title;
  final String destinationRoom;
  final String currentLocation;
  final String memo;
  final List<String> tags;
  final List<BoxItem> items;
  final List<String> photoPaths;
  final bool isPriority;
  final MoveStatus moveStatus;
  final PhysicalMarkStatus physicalMarkStatus;
  final PhysicalMarkMethod? physicalMarkMethod;
  final Set<BoxIssue> issues;
  final DateTime? labelExportedAt;
  final DateTime? physicalMarkedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  BoxRecord copyWith({
    String? shortCode,
    String? title,
    String? destinationRoom,
    String? currentLocation,
    String? memo,
    List<String>? tags,
    List<BoxItem>? items,
    List<String>? photoPaths,
    bool? isPriority,
    MoveStatus? moveStatus,
    PhysicalMarkStatus? physicalMarkStatus,
    Object? physicalMarkMethod = _unset,
    Set<BoxIssue>? issues,
    Object? labelExportedAt = _unset,
    Object? physicalMarkedAt = _unset,
    DateTime? updatedAt,
  }) {
    return BoxRecord(
      id: id,
      projectId: projectId,
      shortCode: shortCode ?? this.shortCode,
      title: title ?? this.title,
      destinationRoom: destinationRoom ?? this.destinationRoom,
      currentLocation: currentLocation ?? this.currentLocation,
      memo: memo ?? this.memo,
      tags: tags ?? this.tags,
      items: items ?? this.items,
      photoPaths: photoPaths ?? this.photoPaths,
      isPriority: isPriority ?? this.isPriority,
      moveStatus: moveStatus ?? this.moveStatus,
      physicalMarkStatus: physicalMarkStatus ?? this.physicalMarkStatus,
      physicalMarkMethod: identical(physicalMarkMethod, _unset)
          ? this.physicalMarkMethod
          : physicalMarkMethod as PhysicalMarkMethod?,
      issues: issues ?? this.issues,
      labelExportedAt: identical(labelExportedAt, _unset)
          ? this.labelExportedAt
          : labelExportedAt as DateTime?,
      physicalMarkedAt: identical(physicalMarkedAt, _unset)
          ? this.physicalMarkedAt
          : physicalMarkedAt as DateTime?,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool matches(String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return true;
    final searchable = <String>[
      shortCode,
      title,
      destinationRoom,
      currentLocation,
      memo,
      ...tags,
      ...items.expand((item) => [item.name, item.note]),
      moveStatus.name,
      ...issues.map((issue) => issue.name),
    ].join('\n').toLowerCase();
    return searchable.contains(query);
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'projectId': projectId,
    'shortCode': shortCode,
    'title': title,
    'destinationRoom': destinationRoom,
    'currentLocation': currentLocation,
    'memo': memo,
    'tags': tags,
    'items': items.map((item) => item.toJson()).toList(),
    'photoPaths': photoPaths,
    'isPriority': isPriority,
    'moveStatus': moveStatus.name,
    'physicalMarkStatus': physicalMarkStatus.name,
    'physicalMarkMethod': physicalMarkMethod?.name,
    'issues': issues.map((issue) => issue.name).toList(),
    'labelExportedAt': labelExportedAt?.toIso8601String(),
    'physicalMarkedAt': physicalMarkedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory BoxRecord.fromJson(Map<String, Object?> json) {
    final id = _requiredString(json, 'id');
    final projectId = _requiredString(json, 'projectId');
    final shortCode = _requiredString(json, 'shortCode');
    return BoxRecord(
      id: id,
      projectId: projectId,
      shortCode: shortCode,
      title: json['title'] as String? ?? '',
      destinationRoom: json['destinationRoom'] as String? ?? '',
      currentLocation: json['currentLocation'] as String? ?? '',
      memo: json['memo'] as String? ?? '',
      tags: _stringList(json['tags']),
      items: _mapList(json['items']).map(BoxItem.fromJson).toList(),
      photoPaths: _stringList(json['photoPaths']),
      isPriority: json['isPriority'] as bool? ?? false,
      moveStatus: MoveStatus.values.byName(
        json['moveStatus'] as String? ?? MoveStatus.draft.name,
      ),
      physicalMarkStatus: PhysicalMarkStatus.values.byName(
        json['physicalMarkStatus'] as String? ??
            PhysicalMarkStatus.pending.name,
      ),
      physicalMarkMethod: _enumOrNull(
        PhysicalMarkMethod.values,
        json['physicalMarkMethod'],
      ),
      issues: _stringList(json['issues']).map(BoxIssue.values.byName).toSet(),
      labelExportedAt: _optionalDate(json['labelExportedAt']),
      physicalMarkedAt: _optionalDate(json['physicalMarkedAt']),
      createdAt: DateTime.parse(_requiredString(json, 'createdAt')),
      updatedAt: DateTime.parse(_requiredString(json, 'updatedAt')),
    );
  }
}

const Object _unset = Object();

T? _enumOrNull<T extends Enum>(List<T> values, Object? name) {
  if (name == null) return null;
  if (name is! String) throw const FormatException('Invalid enum value');
  return values.byName(name);
}

List<String> _stringList(Object? value) {
  if (value == null) return const [];
  if (value is! List) throw const FormatException('Invalid string list');
  return value.map((item) => item as String).toList(growable: false);
}

List<Map<String, Object?>> _mapList(Object? value) {
  if (value == null) return const [];
  if (value is! List) throw const FormatException('Invalid map list');
  return value
      .map((item) => (item as Map).cast<String, Object?>())
      .toList(growable: false);
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('Missing required box field');
  }
  return value;
}

DateTime? _optionalDate(Object? value) {
  if (value == null) return null;
  if (value is! String) throw const FormatException('Invalid date');
  return DateTime.parse(value);
}
