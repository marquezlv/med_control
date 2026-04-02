class NoteTable {
  static const String notes = 'notes';

  static const String id = 'id';
  static const String text = 'text';
  static const String createdAt = 'created_at';
  static const String title = 'title';

  static const String createNotesTable = '''
CREATE TABLE $notes (
  $id INTEGER PRIMARY KEY AUTOINCREMENT,
  $text TEXT NOT NULL,
  $createdAt TEXT NOT NULL,
  $title TEXT
);
''';
}
