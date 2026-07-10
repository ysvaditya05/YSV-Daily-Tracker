import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ysv_daily/screens/create_tracker_screen.dart';

void main() {
  testWidgets('validates the tracker name and shows all tracker types', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CreateTrackerScreen()));

    await tester.tap(find.text('Create'));
    await tester.pump();

    expect(find.text('Enter a tracker name.'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    expect(find.text('Time'), findsNWidgets(2));
    expect(find.text('Number'), findsOneWidget);
    expect(find.text('Checklist'), findsOneWidget);
    expect(find.text('List'), findsOneWidget);
  });
}
