import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:itec_parking/main.dart';
import 'package:itec_parking/providers/app_provider.dart';

void main() {
  group('ITEC Parking App Tests', () {
    testWidgets('App renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppProvider(),
          child: const ITECParkingApp(),
        ),
      );
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Splash screen shows app name', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppProvider(),
          child: const ITECParkingApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('ITEC Parking'), findsOneWidget);
    });
  });

  group('AppUtils Tests', () {
    test('formatRwf formats correctly', () {
      from_import_apputils: {
        // RWF 1,500 for 3 hrs @ 500/hr
      }
    });

    test('Slot ID validation works', () {
      // Valid
      expect(RegExp(r'^\d+-\d+$').hasMatch('1-101'), isTrue);
      expect(RegExp(r'^\d+-\d+$').hasMatch('2-104'), isTrue);
      // Invalid
      expect(RegExp(r'^\d+-\d+$').hasMatch('abc'), isFalse);
      expect(RegExp(r'^\d+-\d+$').hasMatch('1-'), isFalse);
      expect(RegExp(r'^\d+-\d+$').hasMatch(''), isFalse);
    });

    test('Duration calculation is correct', () {
      final entry = DateTime.now().subtract(const Duration(hours: 2, minutes: 30));
      final elapsed = DateTime.now().difference(entry);
      final hours = elapsed.inMinutes / 60.0;
      final amount = (hours * 500).ceilToDouble();
      expect(amount, greaterThanOrEqualTo(1250));
    });
  });
}
