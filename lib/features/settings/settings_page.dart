import 'package:flutter/material.dart';

import '../auth/auth_scope.dart';
import '../export/share_data_page.dart';
import '../guests/guests_page.dart';
import '../payments/payments_page.dart';
import 'config_scope.dart';
import 'property_setup_page.dart';
import 'rooms_setup_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final config = ConfigScope.of(context);
    final property = config.property;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(property.name, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                '${property.currency} \u00b7 ${config.totalRooms} rooms',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const _SectionHeader('Configuration'),
        ListTile(
          leading: const Icon(Icons.storefront_outlined),
          title: const Text('Property setup'),
          subtitle: const Text('Name, contact, currency, tax, timings'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => PropertySetupPage(initialProperty: property),
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.meeting_room_outlined),
          title: const Text('Room setup'),
          subtitle: Text('${config.totalRooms} rooms configured'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const RoomsSetupPage(),
            ),
          ),
        ),
        const _SectionHeader('Operations'),
        ListTile(
          leading: const Icon(Icons.people_outline),
          title: const Text('Guests'),
          subtitle: const Text('Profiles, search and stay history'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (context) => const GuestsPage()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.payments_outlined),
          title: const Text('Payments'),
          subtitle: const Text('Collection history'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (context) => const PaymentsPage()),
          ),
        ),
        const ListTile(
          leading: Icon(Icons.receipt_long_outlined),
          title: Text('Expenses'),
          subtitle: Text('Coming soon'),
          enabled: false,
        ),
        const ListTile(
          leading: Icon(Icons.bar_chart_outlined),
          title: Text('Reports'),
          subtitle: Text('Coming soon'),
          enabled: false,
        ),
        ListTile(
          leading: const Icon(Icons.ios_share),
          title: const Text('Share booking data'),
          subtitle: const Text('Send a snapshot to the admin over WhatsApp'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => ShareDataPage(
                adminName: property.name,
              ),
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sign out'),
          subtitle: const Text('End this session on this device'),
          onTap: () async {
            await AuthScope.of(context).signOut();
            if (context.mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
        ),
        const _SectionHeader('Administration'),
        const ListTile(
          leading: Icon(Icons.manage_accounts_outlined),
          title: Text('Users'),
          subtitle: Text('Coming soon'),
          enabled: false,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
