import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/services/firebase_bootstrap.dart';
import 'data/config/property_seed.dart';
import 'data/repositories/config_repository.dart';
import 'data/repositories/firestore_config_repository.dart';
import 'data/repositories/firestore_operations_repository.dart';
import 'data/repositories/in_memory_config_repository.dart';
import 'data/repositories/in_memory_operations_repository.dart';
import 'data/repositories/operations_repository.dart';
import 'features/operations/operations_controller.dart';
import 'features/settings/config_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fire-and-forget: the app must boot even when Firebase is not configured
  // yet, so a missing project never blocks local development.
  final firebaseReady = await FirebaseBootstrap.initialize();

  final ConfigRepository configRepository;
  final OperationsRepository operationsRepository;

  if (firebaseReady) {
    // Phase 11: both phones read and write the same Firestore project, so
    // changes synchronize automatically and work while offline.
    final firestore = FirebaseFirestore.instance;
    configRepository = FirestoreConfigRepository(
      firestore: firestore,
      propertyId: PropertySeed.propertyId,
    );
    operationsRepository = FirestoreOperationsRepository(
      firestore: firestore,
      propertyId: PropertySeed.propertyId,
    );
  } else {
    configRepository = InMemoryConfigRepository.seeded();
    operationsRepository = InMemoryOperationsRepository();
  }

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
    ),
  );
}
