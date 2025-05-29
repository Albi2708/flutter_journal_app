import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:journal_app/models/folder.dart';
import '../models/journal_entry.dart';
import 'package:journal_app/models/media_item.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'journal_app.db');
    return openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folder_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE folders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE media(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entry_id INTEGER NOT NULL,
        path TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }

  FutureOr<void> _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      await db.execute('''
        CREATE TABLE folders(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          color INTEGER NOT NULL
        )
      ''');
    }
    if (oldV < 3) {
      await db.execute('''
        ALTER TABLE entries
        ADD COLUMN folder_id INTEGER NOT NULL DEFAULT 1
      ''');
    }
    if (oldV < 4) {
      await db.execute('''
        CREATE TABLE media(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          entry_id INTEGER NOT NULL,
          path TEXT NOT NULL,
          date TEXT NOT NULL
        )
      ''');
    }
  }

  // ─── Entries CRUD ────────────────────────────────
  Future<int> insertEntry(JournalEntry entry) async {
    final db = await database;
    return db.insert('entries', entry.toMap());
  }

  Future<List<JournalEntry>> getAllEntries() async {
    final db = await database;
    final maps = await db.query('entries', orderBy: 'date DESC');
    return maps.map((m) => JournalEntry.fromMap(m)).toList();
  }

  Future<JournalEntry?> getEntry(int id) async {
    final db = await database;
    final maps = await db.query('entries', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return JournalEntry.fromMap(maps.first);
    return null;
  }

  Future<int> updateEntry(JournalEntry entry) async {
    final db = await database;
    return db.update(
      'entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteEntry(int id) async {
    final db = await database;
    return db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<JournalEntry>> getEntriesByFolder(int folderId) async {
    final db = await database;
    final maps = await db.query(
      'entries',
      where: 'folder_id = ?',
      whereArgs: [folderId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => JournalEntry.fromMap(m)).toList();
  }

  Future<int> getEntryCountByFolder(int folderId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM entries WHERE folder_id = ?',
      [folderId],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  // ─── Folder CRUD ─────────────────────────────────
  Future<int> insertFolder(Folder f) async {
    final db = await database;
    return db.insert('folders', f.toMap());
  }

  Future<int> updateFolder(Folder folder) async {
    final db = await database;
    return db.update(
      'folders',
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  Future<List<Folder>> getAllFolders() async {
    final db = await database;
    final maps = await db.query('folders', orderBy: 'id ASC');
    return maps.map((m) => Folder.fromMap(m)).toList();
  }

  Future<int> deleteFolder(int id) async {
    final db = await database;
    return db.delete('folders', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteEntriesByFolder(int folderId) async {
    final db = await database;
    return db.delete('entries', where: 'folder_id = ?', whereArgs: [folderId]);
  }

  // ─── Media CRUD ──────────────────────────────────
  Future<int> insertMedia(MediaItem m) async {
    final db = await database;
    return db.insert('media', m.toMap());
  }

  Future<List<MediaItem>> getMediaByEntry(int entryId) async {
    final db = await database;
    final maps = await db.query(
      'media',
      where: 'entry_id = ?',
      whereArgs: [entryId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => MediaItem.fromMap(m)).toList();
  }

  Future<int> deleteMedia(int mediaId) async {
    final db = await database;
    return db.delete('media', where: 'id = ?', whereArgs: [mediaId]);
  }

  Future<int> deleteMediaByEntry(int entryId) async {
    final db = await database;
    return db.delete('media', where: 'entry_id = ?', whereArgs: [entryId]);
  }
}
