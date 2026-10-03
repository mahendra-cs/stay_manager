import 'package:flutter/material.dart';

import '../../data/models/app_user.dart';

/// Admin / Staff picker shown during registration.
class RoleSelector extends StatelessWidget {
  const RoleSelector({
    super.key,
    required this.role,
    required this.onChanged,
  });

  final UserRole role;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<UserRole>(
      segments: const [
        ButtonSegment<UserRole>(
          value: UserRole.staff,
          label: Text('Staff'),
          icon: Icon(Icons.badge_outlined),
        ),
        ButtonSegment<UserRole>(
          value: UserRole.admin,
          label: Text('Admin'),
          icon: Icon(Icons.shield_outlined),
        ),
      ],
      selected: {role},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

/// Inline, dismissible-free error message for auth failures.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
