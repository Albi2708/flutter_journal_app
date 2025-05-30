import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:journal_app/models/folder.dart';
import '../models/journal_entry.dart';
import 'package:journal_app/models/media_item.dart';

/// A singleton helper for opening, creating, migrating, and performing
/// CRUD operations on the app’s SQLite database.
///
/// Manages three tables:
///  * `entries`   – journal entries
///  * `folders`   – user-defined folders
///  * `media`     – photos attached to entries
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  /// Opens the database if needed and returns the [Database] instance.
  ///
  /// If the DB has not yet been initialized, calls [_initDatabase].
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Creates (or opens) the physical database file at `journal_app.db`,
  /// registers [_onCreate] and [_onUpgrade], and sets the schema version.
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

  /// Called when the database is first created.
  /// Executes the SQL statements to create all three tables.
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

  /// Called when opening a database with an older schema version.
  /// Applies incremental SQL migrations from [oldV] → [newV].
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

  /// Inserts a new [JournalEntry] into `entries`.
  /// Returns the newly generated entry ID.
  Future<int> insertEntry(JournalEntry entry) async {
    final db = await database;
    return db.insert('entries', entry.toMap());
  }

  /// Fetches all journal entries, ordered by descending date.
  Future<List<JournalEntry>> getAllEntries() async {
    final db = await database;
    final maps = await db.query('entries', orderBy: 'date DESC');
    return maps.map((m) => JournalEntry.fromMap(m)).toList();
  }

  /// Looks up a single [JournalEntry] by its integer [id].
  /// Returns null if no matching row is found.
  Future<JournalEntry?> getEntry(int id) async {
    final db = await database;
    final maps = await db.query('entries', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return JournalEntry.fromMap(maps.first);
    return null;
  }

  /// Updates an existing journal entry (matched by `entry.id`).
  /// Returns the number of rows affected (should be 1).
  Future<int> updateEntry(JournalEntry entry) async {
    final db = await database;
    return db.update(
      'entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  /// Deletes the entry with the given [id].
  /// Returns the number of rows deleted.
  Future<int> deleteEntry(int id) async {
    final db = await database;
    return db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  /// Returns all entries belonging to the folder with ID [folderId].
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

  /// Returns the total count of entries in the specified folder.
  Future<int> getEntryCountByFolder(int folderId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM entries WHERE folder_id = ?',
      [folderId],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  // ─── Folder CRUD ─────────────────────────────────

  /// Inserts a new [Folder], returning its generated ID.
  Future<int> insertFolder(Folder f) async {
    final db = await database;
    return db.insert('folders', f.toMap());
  }

  /// Updates an existing [Folder] by `folder.id`.
  /// Returns the number of rows affected.
  Future<int> updateFolder(Folder folder) async {
    final db = await database;
    return db.update(
      'folders',
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  /// Retrieves all folders, sorted by ascending ID.
  Future<List<Folder>> getAllFolders() async {
    final db = await database;
    final maps = await db.query('folders', orderBy: 'id ASC');
    return maps.map((m) => Folder.fromMap(m)).toList();
  }

  /// Deletes the folder with the given [id].
  /// Returns the number of rows deleted.
  Future<int> deleteFolder(int id) async {
    final db = await database;
    return db.delete('folders', where: 'id = ?', whereArgs: [id]);
  }

  /// Deletes _all_ entries in folder [folderId].
  Future<int> deleteEntriesByFolder(int folderId) async {
    final db = await database;
    return db.delete('entries', where: 'folder_id = ?', whereArgs: [folderId]);
  }

  // ─── Media CRUD ──────────────────────────────────

  /// Inserts a [MediaItem] linked to an entry.
  /// Returns the new media-item ID.
  Future<int> insertMedia(MediaItem m) async {
    final db = await database;
    return db.insert('media', m.toMap());
  }

  /// Retrieves all media for the entry with ID [entryId], newest first.
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

  /// Deletes a single media item by [mediaId].
  Future<int> deleteMedia(int mediaId) async {
    final db = await database;
    return db.delete('media', where: 'id = ?', whereArgs: [mediaId]);
  }

  /// Deletes all media items linked to entry [entryId].
  Future<int> deleteMediaByEntry(int entryId) async {
    final db = await database;
    return db.delete('media', where: 'entry_id = ?', whereArgs: [entryId]);
  }
}
