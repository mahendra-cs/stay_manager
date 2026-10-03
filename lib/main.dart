import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/config/property_seed.dart';
import 'data/repositories/config_repository.dart';
import 'data/repositories/in_memory_auth_service.dart';
import 'data/repositories/in_memory_config_repository.dart';
import 'data/repositories/local_file_operations_repository.dart';
import 'data/repositories/operations_repository.dart';
import 'features/auth/auth_controller.dart';
import 'features/operations/operations_controller.dart';
import 'features/settings/config_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // No cloud backend by design: booking data lives on this device only and is
  // flushed to disk on every write, so nothing is lost when the app closes.
  // Configuration is still seeded in memory and editable from the app.
  final ConfigRepository configRepository =
      InMemoryConfigRepository.seeded();
  final OperationsRepository operationsRepository =
      LocalFileOperationsRepository();

  final configController = ConfigController(configRepository);
  await configController.load();

  // Rooms belong to configuration; operations only drives their status, so the
  // config controller is injected as the room-status writer.
  final operationsController = OperationsController(
    operationsRepository,
    roomStatusWriter: configController,
    settings: configController.settings,
  );
  await operationsController.load();

  runApp(
    StayManagerApp(
      configController: configController,
      operationsController: operationsController,
      authController: AuthController(
        InMemoryAuthService(propertyId: PropertySeed.propertyId),
      ),
      // Sign-in is a local convenience while there is no cloud identity
      // provider; the Firestore rules path can be re-enabled any time.
      requireSignIn: false,
    ),
  );
}
