import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:med_control/models/medication_model.dart';
import 'package:med_control/screens/medications.dart';

void main() {
  testWidgets('renders medication form with required fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MedicationFormScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Add medication'), findsOneWidget);
    expect(find.text('Medication name *'), findsOneWidget);
    expect(find.text('Current quantity'), findsOneWidget);
    expect(find.text('Medication color'), findsOneWidget);
    expect(find.text('Dosage per day'), findsOneWidget);
    expect(find.text('Days of week'), findsOneWidget);
    expect(find.text('Save medication'), findsOneWidget);
  });

  test('converts a color to hex', () {
    expect(MedicationModel.colorToHex(const Color(0xFFFFC0CB)), '#FFC0CB');
  });
}
