import '../core/database/tables/note_table.dart';

class NoteModel {
  const NoteModel({
    this.id,
    required this.text,
    required this.createdAt,
    this.title,
  });

  final int? id;
  final String text;
  final DateTime createdAt;
  final String? title;

  Map<String, Object?> toMap() {
    return {
      NoteTable.id: id,
      NoteTable.text: text,
      NoteTable.createdAt: createdAt.toIso8601String(),
      NoteTable.title: title,
    };
  }

  factory NoteModel.fromMap(Map<String, Object?> map) {
    return NoteModel(
      id: map[NoteTable.id] as int?,
      text: map[NoteTable.text] as String,
      createdAt: DateTime.parse(map[NoteTable.createdAt] as String),
      title: map[NoteTable.title] as String?,
    );
  }

  NoteModel copyWith({
    int? id,
    String? text,
    DateTime? createdAt,
    Object? title = _sentinel,
  }) {
    return NoteModel(
      id: id ?? this.id,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      title: title == _sentinel ? this.title : title as String?,
    );
  }

  static const Object _sentinel = Object();
}
