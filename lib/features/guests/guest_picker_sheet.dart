import 'package:flutter/material.dart';

import '../../data/models/guest.dart';
import '../operations/operations_scope.dart';
import 'guest_form_page.dart';

/// Lets the receptionist pick an existing guest or create one without losing
/// the half-filled booking form.
///
/// Returns the chosen [Guest], or `null` if the user backs out.
Future<Guest?> showGuestPicker(BuildContext context) {
  return showModalBottomSheet<Guest>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const _GuestPickerSheet(),
  );
}

class _GuestPickerSheet extends StatefulWidget {
  const _GuestPickerSheet();

  @override
  State<_GuestPickerSheet> createState() => _GuestPickerSheetState();
}

class _GuestPickerSheetState extends State<_GuestPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final operations = OperationsScope.of(context);
    final guests = operations.searchGuests(_query);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search by name or phone',
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _createGuest,
                  icon: const Icon(Icons.person_add_alt),
                  label: const Text('New guest details'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: guests.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _query.isEmpty
                              ? 'No guests yet. Tap "New guest details" to '
                                  'add the first one.'
                              : 'No guest matches "$_query".',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: guests.length,
                      itemBuilder: (context, index) {
                        final guest = guests[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          title: Text(guest.name),
                          subtitle: guest.phone.trim().isEmpty
                              ? null
                              : Text(guest.phone),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).pop(guest),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createGuest() async {
    final guest = await Navigator.of(context).push<Guest>(
      MaterialPageRoute<Guest>(builder: (context) => const GuestFormPage()),
    );
    if (guest != null && mounted) {
      Navigator.of(context).pop(guest);
    }
  }
}