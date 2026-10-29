import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juniauto/main.dart';

void main() {
  testWidgets('App smoke test on desktop viewport', (WidgetTester tester) async {
    // Set standard desktop resolution for testing
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Build app
    await tester.pumpWidget(const WebRevenApp());
    await tester.pumpAndSettle();

    // Verify main components render properly
    expect(find.text('WebReven'), findsOneWidget);
    expect(find.text('START SCRAPING'), findsOneWidget);
    expect(find.text('Notepad View (0)'), findsOneWidget);
  });
}
