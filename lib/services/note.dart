import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../core/database/tables/note_table.dart';
import '../models/note_model.dart';

class NoteService {
  NoteService._();

  static final NoteService instance = NoteService._();

  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<int> createNote(NoteModel note) async {
    final db = await _db;
    final data = note.toMap()..remove(NoteTable.id);
    return db.insert(NoteTable.notes, data);
  }

  Future<List<NoteModel>> getAllNotes() async {
    final db = await _db;
    final rows = await db.query(
      NoteTable.notes,
      orderBy: '${NoteTable.createdAt} DESC',
    );
    return rows.map(NoteModel.fromMap).toList();
  }

  Future<void> updateNote(NoteModel note) async {
    final id = note.id;
    if (id == null) {
      throw ArgumentError('Note id is required for update.');
    }
    final db = await _db;
    await db.update(
      NoteTable.notes,
      note.toMap()..remove(NoteTable.id),
      where: '${NoteTable.id} = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteNote(int id) async {
    final db = await _db;
    await db.delete(
      NoteTable.notes,
      where: '${NoteTable.id} = ?',
      whereArgs: [id],
    );
  }
}
