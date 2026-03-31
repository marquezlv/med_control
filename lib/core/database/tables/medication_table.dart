class MedicationTable {
  static const String medications = 'medications';
  static const String taken = 'medication_taken';

  static const String id = 'id';
  static const String name = 'name';
  static const String quantity = 'quantity';
  static const String colorHex = 'color_hex';
  static const String dosage = 'dosage';
  static const String daysOfWeek = 'days_of_week';

  static const String takenId = 'id';
  static const String takenMedicationId = 'medication_id';
  static const String takenDate = 'taken_date';

  static const String createMedicationsTable =
      '''
CREATE TABLE $medications (
	$id INTEGER PRIMARY KEY AUTOINCREMENT,
	$name TEXT NOT NULL,
	$quantity INTEGER NOT NULL DEFAULT 0,
	$colorHex TEXT NOT NULL,
	$dosage INTEGER NOT NULL DEFAULT 1,
	$daysOfWeek TEXT NOT NULL
);
''';

  static const String createTakenTable =
      '''
CREATE TABLE $taken (
	$takenId INTEGER PRIMARY KEY AUTOINCREMENT,
	$takenMedicationId INTEGER NOT NULL,
	$takenDate TEXT NOT NULL,
	UNIQUE($takenMedicationId, $takenDate),
	FOREIGN KEY($takenMedicationId) REFERENCES $medications($id) ON DELETE CASCADE
);
''';
}
