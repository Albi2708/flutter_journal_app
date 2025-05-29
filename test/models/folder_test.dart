import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/models/folder.dart';

void main() {
  group('Folder model', () {
    test('toMap/fromMap roundtrip', () {
      const redArgb = 0xFFFF0000;
      final entry = Folder(id: 42, color: Color(redArgb), name: 'Test');

      final map = entry.toMap();
      expect(map['id'], 42);
      expect(map['color'], redArgb);
      expect(map['name'], 'Test');

      final reconstructed = Folder.fromMap(map);
      expect(reconstructed.id, 42);
      expect(reconstructed.color, const Color(redArgb));
      expect(reconstructed.name, 'Test');
    });
  });
}
