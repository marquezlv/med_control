import 'package:sqflite/sqflite.dart';

import 'tables/medication_table.dart';
import 'tables/note_table.dart';

class DatabaseMigrations {
  static const int currentVersion = 3;

  static Future<void> onCreate(Database db, int version) async {
    await db.execute(MedicationTable.createMedicationsTable);
    await db.execute(MedicationTable.createTakenTable);
    await db.execute(NoteTable.createNotesTable);
  }

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 1) {
      await onCreate(db, newVersion);
      return;
    }
    if (oldVersion < 2) {
      await db.execute(NoteTable.createNotesTable);
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE ${MedicationTable.medications} ADD COLUMN ${MedicationTable.notificationTime} TEXT;',
      );
      await db.execute(
        'ALTER TABLE ${NoteTable.notes} ADD COLUMN ${NoteTable.title} TEXT;',
      );
    }
  }
}
