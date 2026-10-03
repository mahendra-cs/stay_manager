import 'package:flutter/material.dart';

import '../../core/services/export_service.dart';
import '../../core/utils/money_format.dart';
import '../../data/models/payment.dart';
import '../operations/operations_scope.dart';
import '../settings/config_scope.dart';

/// Sends booking data to the administrator over WhatsApp.
///
/// This is an export, not a sync: the admin receives a read-only snapshot to
/// archive or load into their own tooling. Nothing is read back into the staff
/// phone, so the device stays the single source of truth.
class ShareDataPage extends StatefulWidget {
  const ShareDataPage({super.key, this.adminName});

  final String? adminName;

  @override
  State<ShareDataPage> createState() => _ShareDataPageState();
}

class _ShareDataPageState extends State<ShareDataPage> {
  bool _sharing = false;
  bool _includePayments = true;
  bool _includeGuests = true;

  @override
  Widget build(BuildContext context) {
    final operations = OperationsScope.of(context);
    final config = ConfigScope.of(context);
    final theme = Theme.of(context);
    final currency = config.property.currency;

    final bookings = operations.bookings;
    final payments = operations.payments;
    final guests = operations.guests;
    final admin = widget.adminName?.trim() ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Share booking data')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What will be sent', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _Row(label: 'Bookings', value: '${bookings.length}'),
                  _Row(
                    label: 'Payments',
                    value: '${payments.length} '
                        '(${formatMoney(currency, _total(payments))})',
                  ),
                  _Row(label: 'Guests', value: '${guests.length}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _includePayments,
                  onChanged: (value) =>
                      setState(() => _includePayments = value),
                  title: const Text('Include payments'),
                  subtitle: const Text('Collection history and modes'),
                ),
                SwitchListTile(
                  value: _includeGuests,
                  onChanged: (value) => setState(() => _includeGuests = value),
                  title: const Text('Include guest details'),
                  subtitle: const Text('Names, phone and ID fields'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _sharing || bookings.isEmpty ? null : _share,
            icon: _sharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share),
            label: Text(
              admin.isEmpty ? 'Share via WhatsApp' : 'Share with $admin',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'A CSV file is created and handed to WhatsApp. You choose the chat '
            'to send it to - nothing is sent automatically.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  double _total(List<Payment> payments) =>
      payments.fold<double>(0, (sum, p) => sum + p.amount);

  Future<void> _share() async {
    setState(() => _sharing = true);
    final operations = OperationsScope.of(context);
    final config = ConfigScope.of(context);

    try {
      await ExportService.shareCsv(
        bookings: operations.bookings,
        payments: _includePayments ? operations.payments : const <Payment>[],
        guests: _includeGuests ? operations.guests : const [],
        propertyName: config.property.name,
        recipientHint: widget.adminName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export ready - choose the chat in WhatsApp')),
      );
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not create the export file.')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
