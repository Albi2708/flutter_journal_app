class JournalEntry {
  late final int? id;
  final int folderId;
  final String title;
  final String content;
  final DateTime date;

  JournalEntry({
    this.id,
    required this.folderId,
    required this.title,
    required this.content,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'folder_id': folderId,
    'title': title,
    'content': content,
    'date': date.toIso8601String(),
  };

  factory JournalEntry.fromMap(Map<String, dynamic> m) => JournalEntry(
    id: m['id'] as int?,
    folderId: m['folder_id'] as int,
    title: m['title'] as String,
    content: m['content'] as String,
    date: DateTime.parse(m['date'] as String),
  );

  @override
  String toString() =>
      'JournalEntry{id: $id, folderId: $folderId, title: $title}';
}
