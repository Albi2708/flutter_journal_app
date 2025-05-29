import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/models/media_item.dart';

void main() {
  group('MediaItem model', () {
    test('toMap/fromMap roundtrip', () {
      final now = DateTime.now();
      final entry = MediaItem(id: 40, date: now, entryId: 42, path: "testPath");

      final map = entry.toMap();
      expect(map['id'], 40);
      expect(map['date'], now.toIso8601String());
      expect(map['entry_id'], 42);
      expect(map['path'], 'testPath');

      final reconstructed = MediaItem.fromMap(map);
      expect(reconstructed.id, 40);
      expect(reconstructed.date, now);
      expect(reconstructed.entryId, 42);
      expect(reconstructed.path, 'testPath');
    });
  });
}
