import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stay_manager/app/app.dart';
import 'package:stay_manager/data/repositories/in_memory_config_repository.dart';
import 'package:stay_manager/data/repositories/in_memory_operations_repository.dart';
import 'package:stay_manager/features/operations/operations_controller.dart';
import 'package:stay_manager/features/settings/config_controller.dart';

Future<void> pumpApp(WidgetTester tester) async {
  final config = ConfigController(InMemoryConfigRepository.seeded());
  await config.load();
  final operations = OperationsController(
    InMemoryOperationsRepository(),
    roomStatusWriter: config,
    settings: config.settings,
  );
  await operations.load();

  await tester.pumpWidget(
    StayManagerApp(
      configController: config,
      operationsController: operations,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('dashboard shows the configured property and room counts', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Veda Bed & Breakfast'), findsOneWidget);
    expect(find.text('Occupancy'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('9'), findsWidgets);
  });

  testWidgets('navigates between the primary sections', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Rooms'));
    await tester.pumpAndSettle();
    expect(find.text('Room 1'), findsOneWidget);

    await tester.tap(find.text('Bookings'));
    await tester.pumpAndSettle();
    expect(find.text('No bookings yet'), findsOneWidget);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Property setup'), findsOneWidget);
    expect(find.text('Room setup'), findsOneWidget);
    expect(find.text('Guests'), findsOneWidget);
  });

  testWidgets('the New booking action opens the booking form', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Bookings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New booking'));
    await tester.pumpAndSettle();

    // The guest picker is the first field of the form.
    expect(find.text('Select guest'), findsOneWidget);

    // Room selection and submit sit further down the scrollable form.
    await tester.scrollUntilVisible(
      find.text('Select room'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Select room'), findsOneWidget);
  });


  testWidgets('guest details can be entered from the booking form', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Bookings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New booking'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Select guest'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New guest details'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name *'),
      'Test Guest',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone'),
      '9876543210',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save guest'));
    await tester.pumpAndSettle();

    expect(find.text('Test Guest'), findsWidgets);
  });
}
