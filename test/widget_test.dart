// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:med_control/main.dart';

void main() {
  testWidgets('renders medication dashboard layout', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MedControlApp());
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsAtLeastNWidgets(1));
    expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.medication_rounded), findsOneWidget);
  });
}
