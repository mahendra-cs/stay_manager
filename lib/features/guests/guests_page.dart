import 'package:flutter/material.dart';

import '../../core/widgets/section_placeholder.dart';
import '../../data/models/guest.dart';
import '../operations/operations_scope.dart';
import 'guest_details_page.dart';
import 'guest_form_page.dart';

class GuestsPage extends StatefulWidget {
  const GuestsPage({super.key});

  @override
  State<GuestsPage> createState() => _GuestsPageState();
}

class _GuestsPageState extends State<GuestsPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final operations = OperationsScope.of(context);
    final guests = operations.searchGuests(_query);

    return Scaffold(
      appBar: AppBar(title: const Text('Guests')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addGuest,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add guest'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by name or phone',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: guests.isEmpty
                ? SectionPlaceholder(
                    icon: Icons.people_outline,
                    title: _query.isEmpty ? 'No guests yet' : 'No matches',
                    message: _query.isEmpty
                        ? 'Add a guest to start taking bookings.'
                        : 'No guest matches "$_query".',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: guests.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final guest = guests[index];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          title: Text(guest.name),
                          subtitle: Text(_subtitle(guest)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) =>
                                  GuestDetailsPage(guestId: guest.id),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _addGuest() async {
    await Navigator.of(context).push(
      MaterialPageRoute<Guest>(
        builder: (context) => const GuestFormPage(),
      ),
    );
  }

  String _subtitle(Guest guest) {
    final parts = <String>[
      if (guest.phone.trim().isNotEmpty) guest.phone,
      if (guest.email.trim().isNotEmpty) guest.email,
    ];
    return parts.isEmpty ? 'No contact details' : parts.join(' \u00b7 ');
  }
}