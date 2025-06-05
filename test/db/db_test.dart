import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/models/media_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:journal_app/db/database_helper.dart';
import 'package:journal_app/models/folder.dart';
import 'package:journal_app/models/journal_entry.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late DatabaseHelper dbHelper;

  setUp(() async {
  dbHelper = DatabaseHelper(
    factory: databaseFactoryFfi,
    path: inMemoryDatabasePath, // constant in sqflite_common_ffi that resolves to :memory:
  );
});

  tearDown(() async {
    final db = await dbHelper.database;
    await db.delete('entries');
    await db.delete('folders');
  });

  group('Folder table CRUD', () {
    test('insertFolder & getAllFolders', () async {
      final folder = Folder(name: 'TestFolder', color: Color(0xFF123456));
      final id = await dbHelper.insertFolder(folder);
      expect(id, isNonZero);

      final all = await dbHelper.getAllFolders();
      expect(all, hasLength(1));

      final fetched = all.first;
      expect(fetched.id, equals(id));
      expect(fetched.name, equals('TestFolder'));
      expect(fetched.color.value, equals(0xFF123456));
    });

    test('deleteFolder removes it', () async {
      final id = await dbHelper.insertFolder(
        Folder(name: 'ToDelete', color: Color(0xFF000000)),
      );
      expect((await dbHelper.getAllFolders()).length, equals(1));

      final deletedCount = await dbHelper.deleteFolder(id);
      expect(deletedCount, equals(1));
      expect((await dbHelper.getAllFolders()).isEmpty, isTrue);
    });
  });

  group('Entry table CRUD (per folder)', () {
    late int folderId;

    setUp(() async {
      folderId = await dbHelper.insertFolder(
        Folder(name: 'DefaultFolder', color: Color(0xFF00FF00)),
      );
    });

    test('insertEntry & getEntriesByFolder', () async {
      final entry = JournalEntry(
        folderId: folderId,
        title: 'Test',
        content: 'Content',
        date: DateTime(2025, 1, 1),
      );
      final id = await dbHelper.insertEntry(entry);
      expect(id, isNonZero);

      final entries = await dbHelper.getEntriesByFolder(folderId);
      expect(entries, hasLength(1));
      expect(entries.first.title, equals('Test'));
      expect(entries.first.content, equals('Content'));
      expect(entries.first.folderId, equals(folderId));
    });

    test('updateEntry modifies fields', () async {
      final original = JournalEntry(
        folderId: folderId,
        title: 'Orig',
        content: 'Old',
        date: DateTime(2025, 2, 2),
      );
      final id = await dbHelper.insertEntry(original);

      final updated = JournalEntry(
        id: id,
        folderId: folderId,
        title: 'Updated',
        content: 'New',
        date: DateTime(2025, 3, 3),
      );
      final count = await dbHelper.updateEntry(updated);
      expect(count, equals(1));

      final entries = await dbHelper.getEntriesByFolder(folderId);
      expect(entries, hasLength(1));
      expect(entries.first.title, equals('Updated'));
      expect(entries.first.content, equals('New'));
    });

    test('deleteEntry removes it', () async {
      final entry = JournalEntry(
        folderId: folderId,
        title: 'ToDelete',
        content: 'X',
        date: DateTime.now(),
      );
      final id = await dbHelper.insertEntry(entry);
      expect((await dbHelper.getEntriesByFolder(folderId)).length, equals(1));

      final deletedCount = await dbHelper.deleteEntry(id);
      expect(deletedCount, equals(1));
      expect((await dbHelper.getEntriesByFolder(folderId)).isEmpty, isTrue);
    });
  });

  group('Media table CRUD', () {
    late int entryId;
    setUp(() async {
      final folderId = await dbHelper.insertFolder(
        Folder(name: 'F', color: Colors.black),
      );
      entryId = await dbHelper.insertEntry(
        JournalEntry(
          folderId: folderId,
          title: 'E',
          content: 'C',
          date: DateTime.now(),
        ),
      );
    });

    test('insertMedia & getMediaByEntry', () async {
      final mid = await dbHelper.insertMedia(
        MediaItem(
          entryId: entryId,
          path: '/tmp/foo.png',
          date: DateTime(2025, 1, 1),
        ),
      );
      expect(mid, isNonZero);

      final list = await dbHelper.getMediaByEntry(entryId);
      expect(list, hasLength(1));
      expect(list.first.path, '/tmp/foo.png');
    });

    test('deleteMedia removes it', () async {
      final mid = await dbHelper.insertMedia(
        MediaItem(entryId: entryId, path: '/tmp/bar.png', date: DateTime.now()),
      );
      expect((await dbHelper.getMediaByEntry(entryId)).length, 1);

      final c = await dbHelper.deleteMedia(mid);
      expect(c, 1);
      expect((await dbHelper.getMediaByEntry(entryId)), isEmpty);
    });
  });
}
