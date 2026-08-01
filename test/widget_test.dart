import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:car_scanner_app/main.dart';

void main() {
  testWidgets('app launches and shows splash', (WidgetTester tester) async {
    await tester.pumpWidget(const CarScannerApp());
    expect(find.text('فاحص برو X1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('dark theme is applied', (WidgetTester tester) async {
    await tester.pumpWidget(const CarScannerApp());
    final MaterialApp materialApp =
        tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme!.brightness, Brightness.dark);
    expect(materialApp.theme!.colorScheme.brightness, Brightness.dark);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('arabic locale is configured', (WidgetTester tester) async {
    await tester.pumpWidget(const CarScannerApp());
    final MaterialApp materialApp =
        tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.locale, const Locale('ar'));
    expect(materialApp.supportedLocales, const [Locale('ar')]);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('splash navigates to main shell', (WidgetTester tester) async {
    await tester.pumpWidget(const CarScannerApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
