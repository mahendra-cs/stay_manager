import 'package:flutter/widgets.dart';

import 'config_controller.dart';

/// Provides the [ConfigController] to the widget tree.
///
/// Because it is an [InheritedNotifier], every widget that reads the controller
/// through [ConfigScope.of] automatically rebuilds when the configuration
/// changes — no manual listener wiring required.
class ConfigScope extends InheritedNotifier<ConfigController> {
  const ConfigScope({
    super.key,
    required ConfigController controller,
    required super.child,
  }) : super(notifier: controller);

  static ConfigController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ConfigScope>();
    assert(scope != null, 'ConfigScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}