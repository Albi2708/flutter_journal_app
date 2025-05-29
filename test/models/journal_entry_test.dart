import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/models/journal_entry.dart';

void main() {
  group('JournalEntry model', () {
    test('toMap/fromMap roundtrip', () {
      final now = DateTime.now();
      final entry = JournalEntry(
        id: 42,
        folderId: 7,
        title: 'Test',
        content: 'Body',
        date: now,
      );

      final map = entry.toMap();
      expect(map['id'], 42);
      expect(map['folder_id'], 7);
      expect(map['title'], 'Test');
      expect(map['content'], 'Body');
      expect(map['date'], now.toIso8601String());

      final reconstructed = JournalEntry.fromMap(map);
      expect(reconstructed.id, 42);
      expect(reconstructed.folderId, 7);
      expect(reconstructed.title, 'Test');
      expect(reconstructed.content, 'Body');
      expect(reconstructed.date, now);
    });
  });
}
