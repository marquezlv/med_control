import 'package:flutter/material.dart';

import '../core/database/tables/medication_table.dart';

class MedicationModel {
  const MedicationModel({
    this.id,
    required this.name,
    required this.quantity,
    required this.colorHex,
    required this.dosage,
    required this.daysOfWeek,
  });

  final int? id;
  final String name;
  final int quantity;
  final String colorHex;
  final int dosage;
  final List<int> daysOfWeek;

  Map<String, Object?> toMap() {
    return {
      MedicationTable.id: id,
      MedicationTable.name: name,
      MedicationTable.quantity: quantity,
      MedicationTable.colorHex: colorHex,
      MedicationTable.dosage: dosage,
      MedicationTable.daysOfWeek: encodeDays(daysOfWeek),
    };
  }

  factory MedicationModel.fromMap(Map<String, Object?> map) {
    return MedicationModel(
      id: map[MedicationTable.id] as int?,
      name: map[MedicationTable.name] as String,
      quantity: map[MedicationTable.quantity] as int,
      colorHex: map[MedicationTable.colorHex] as String,
      dosage: map[MedicationTable.dosage] as int,
      daysOfWeek: decodeDays(map[MedicationTable.daysOfWeek] as String),
    );
  }

  MedicationModel copyWith({
    int? id,
    String? name,
    int? quantity,
    String? colorHex,
    int? dosage,
    List<int>? daysOfWeek,
  }) {
    return MedicationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      colorHex: colorHex ?? this.colorHex,
      dosage: dosage ?? this.dosage,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
    );
  }

  static String encodeDays(List<int> days) {
    final normalized = [...days]..sort();
    return normalized.join(',');
  }

  static List<int> decodeDays(String value) {
    if (value.trim().isEmpty) {
      return <int>[];
    }

    return value
        .split(',')
        .map((entry) => int.tryParse(entry.trim()))
        .whereType<int>()
        .toList();
  }

  static Color parseColor(String hex) {
    final normalized = hex.replaceAll('#', '').toUpperCase();
    final alphaPrefixed = normalized.length == 6 ? 'FF$normalized' : normalized;
    return Color(int.parse(alphaPrefixed, radix: 16));
  }
}
