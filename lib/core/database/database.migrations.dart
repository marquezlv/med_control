import 'package:sqflite/sqflite.dart';

import 'tables/medication_table.dart';

class DatabaseMigrations {
  static const int currentVersion = 1;

  static Future<void> onCreate(Database db, int version) async {
    await db.execute(MedicationTable.createMedicationsTable);
    await db.execute(MedicationTable.createTakenTable);
  }

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 1) {
      await onCreate(db, newVersion);
    }
  }
}
