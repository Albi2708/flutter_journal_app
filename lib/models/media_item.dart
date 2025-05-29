class MediaItem {
  final int? id;
  final int entryId;
  final String path;
  final DateTime date;

  MediaItem({
    this.id,
    required this.entryId,
    required this.path,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'entry_id': entryId,
    'path': path,
    'date': date.toIso8601String(),
  };

  factory MediaItem.fromMap(Map<String, dynamic> m) => MediaItem(
    id: m['id'] as int?,
    entryId: m['entry_id'] as int,
    path: m['path'] as String,
    date: DateTime.parse(m['date'] as String),
  );
}
