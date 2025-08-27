import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/note.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._();
  AppDatabase._();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'notes_calendar_fpt.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
        CREATE TABLE notes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          scheduledAt INTEGER NOT NULL,
          done INTEGER NOT NULL DEFAULT 0,
          ttsVoice TEXT
        );
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_scheduledAt ON notes(scheduledAt);');
      },
    );
  }

  Future<int> insertNote(Note note) async {
    final d = await db;
    return await d.insert('notes', note.toMap());
  }

  Future<int> updateNote(Note note) async {
    final d = await db;
    return await d.update('notes', note.toMap(),
        where: 'id = ?', whereArgs: [note.id]);
  }

  Future<int> deleteNote(int id) async {
    final d = await db;
    return await d.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Note>> getNotesForDay(DateTime day) async {
    final d = await db;
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final res = await d.query(
      'notes',
      where: 'scheduledAt >= ? AND scheduledAt < ?',
      whereArgs: [
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'scheduledAt ASC',
    );
    return res.map(Note.fromMap).toList();
  }

  Future<List<Note>> getAllNotes() async {
    final d = await db;
    final res = await d.query('notes', orderBy: 'scheduledAt DESC');
    return res.map(Note.fromMap).toList();
  }
}
