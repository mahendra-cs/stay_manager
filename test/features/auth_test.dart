import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stay_manager/app/app.dart';
import 'package:stay_manager/data/models/app_user.dart';
import 'package:stay_manager/data/repositories/in_memory_auth_service.dart';
import 'package:stay_manager/data/repositories/in_memory_config_repository.dart';
import 'package:stay_manager/data/repositories/in_memory_operations_repository.dart';
import 'package:stay_manager/features/auth/auth_controller.dart';
import 'package:stay_manager/features/operations/operations_controller.dart';
import 'package:stay_manager/features/settings/config_controller.dart';

/// Boots the app with the login gate enabled and the local auth service.
Future<AuthController> pumpLogin(WidgetTester tester) async {
  final config = ConfigController(InMemoryConfigRepository.seeded());
  await config.load();
  final operations = OperationsController(
    InMemoryOperationsRepository(),
    roomStatusWriter: config,
    settings: config.settings,
  );
  await operations.load();

  final auth = AuthController(InMemoryAuthService());
  addTearDown(auth.dispose);

  await tester.pumpWidget(
    StayManagerApp(
      configController: config,
      operationsController: operations,
      authController: auth,
      requireSignIn: true,
    ),
  );
  await tester.pumpAndSettle();
  return auth;
}

void main() {
  testWidgets('the login screen is shown when sign-in is required', (
    WidgetTester tester,
  ) async {
    await pumpLogin(tester);

    expect(find.text('Sign in to continue'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email *'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password *'), findsOneWidget);
  });

  testWidgets('registration is rejected until the form is valid', (
    WidgetTester tester,
  ) async {
    await pumpLogin(tester);

    await tester.tap(find.text('First time here? Create an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
    // Empty fields report "required" before the length rule is reached.
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('a new account can be registered and reaches the dashboard', (
    WidgetTester tester,
  ) async {
    await pumpLogin(tester);

    await tester.tap(find.text('First time here? Create an account'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name *'),
      'Front Desk',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email *'),
      'staff@property.test',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password *'),
      'secret123',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    // The auth gate swapped the login screen for the app shell.
    expect(find.text('Sign in to continue'), findsNothing);
    expect(find.text('Occupancy'), findsOneWidget);
  });

  test('the local service rejects an unknown account', () async {
    final service = InMemoryAuthService();
    addTearDown(service.dispose);

    await expectLater(
      service.signIn(email: 'nobody@test.com', password: 'whatever'),
      throwsA(isA<Exception>()),
    );
  });

  test('AppUser exposes the admin role for UI gating', () {
    const admin = AppUser(id: 'u1', role: UserRole.admin, propertyId: 'p1');
    const staff = AppUser(id: 'u2', role: UserRole.staff, propertyId: 'p1');

    expect(admin.isAdmin, isTrue);
    expect(staff.isAdmin, isFalse);
  });
}