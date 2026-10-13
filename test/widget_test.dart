// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kanji_athletes/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    // Without this, SharedPreferences.getInstance() inside _StartupGate
    // (main.dart) never resolves (no mocked platform channel), leaving its
    // CircularProgressIndicator spinning forever and pumpAndSettle timing out.
    SharedPreferences.setMockInitialValues({});

    // Build the app and ensure it renders a MaterialApp
    await tester.pumpWidget(const GemGridApp());
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
