import 'package:flutter/widgets.dart';

import 'operations_controller.dart';

/// Provides the [OperationsController] to the widget tree.
class OperationsScope extends InheritedNotifier<OperationsController> {
  const OperationsScope({
    super.key,
    required OperationsController controller,
    required super.child,
  }) : super(notifier: controller);

  static OperationsController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<OperationsScope>();
    assert(scope != null, 'OperationsScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}