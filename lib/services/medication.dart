import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../core/database/tables/medication_table.dart';
import '../models/medication_model.dart';

class MedicationService {
  MedicationService._();

  static final MedicationService instance = MedicationService._();

  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<int> createMedication(MedicationModel medication) async {
    final db = await _db;
    final data = medication.toMap()..remove(MedicationTable.id);
    return db.insert(MedicationTable.medications, data);
  }

  Future<List<MedicationModel>> getAllMedications() async {
    final db = await _db;
    final rows = await db.query(
      MedicationTable.medications,
      orderBy: '${MedicationTable.name} COLLATE NOCASE ASC',
    );
    return rows.map(MedicationModel.fromMap).toList();
  }

  Future<List<MedicationModel>> getMedicationsForWeekday(int weekday) async {
    final all = await getAllMedications();
    return all
        .where((medication) => medication.daysOfWeek.contains(weekday))
        .toList();
  }

  Future<void> updateMedication(MedicationModel medication) async {
    final id = medication.id;
    if (id == null) {
      throw ArgumentError('Medication id is required for update.');
    }

    final db = await _db;
    await db.update(
      MedicationTable.medications,
      medication.toMap()..remove(MedicationTable.id),
      where: '${MedicationTable.id} = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteMedication(int medicationId) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(
        MedicationTable.taken,
        where: '${MedicationTable.takenMedicationId} = ?',
        whereArgs: [medicationId],
      );
      await txn.delete(
        MedicationTable.medications,
        where: '${MedicationTable.id} = ?',
        whereArgs: [medicationId],
      );
    });
  }

  Future<Set<int>> getTakenMedicationIdsForDate(DateTime date) async {
    final db = await _db;
    final formattedDate = _toDateOnly(date);
    final rows = await db.query(
      MedicationTable.taken,
      columns: [MedicationTable.takenMedicationId],
      where: '${MedicationTable.takenDate} = ?',
      whereArgs: [formattedDate],
    );
    return rows
        .map((row) => row[MedicationTable.takenMedicationId] as int)
        .toSet();
  }

  Future<void> setMedicationTaken({
    required int medicationId,
    required DateTime date,
    required bool taken,
  }) async {
    final db = await _db;
    final formattedDate = _toDateOnly(date);

    if (taken) {
      await db.insert(MedicationTable.taken, {
        MedicationTable.takenMedicationId: medicationId,
        MedicationTable.takenDate: formattedDate,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      return;
    }

    await db.delete(
      MedicationTable.taken,
      where:
          '${MedicationTable.takenMedicationId} = ? AND ${MedicationTable.takenDate} = ?',
      whereArgs: [medicationId, formattedDate],
    );
  }

  String _toDateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
