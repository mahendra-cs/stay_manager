import 'package:flutter/material.dart';

import '../../core/errors/validation_exception.dart';
import '../../core/utils/booking_builder.dart';
import '../../core/utils/money_format.dart';
import '../../core/utils/validators.dart';
import '../../data/models/booking.dart';
import '../../data/models/payment.dart';
import '../../data/models/payment_mode.dart';
import '../operations/operations_scope.dart';
import '../settings/config_scope.dart';

/// Records a payment against a booking (spec §28 Phase 7).
///
/// The amount defaults to the outstanding balance so the common
/// "collect the rest at check-out" case needs no typing.
class PaymentFormPage extends StatefulWidget {
  const PaymentFormPage({super.key, required this.booking});

  final Booking booking;

  @override
  State<PaymentFormPage> createState() => _PaymentFormPageState();
}

class _PaymentFormPageState extends State<PaymentFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _reference;
  late final TextEditingController _notes;

  late PaymentMode _mode;
  late DateTime _paymentDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final outstanding = _outstanding;
    _amount = TextEditingController(
      text: outstanding <= 0 ? '' : outstanding.toStringAsFixed(2),
    );
    _reference = TextEditingController();
    _notes = TextEditingController();
    _mode = _availableModes.first;
    _paymentDate = DateTime.now();
  }

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _notes.dispose();
    super.dispose();
  }

  double get _outstanding {
    final summary = OperationsScope.of(context).summaryFor(widget.booking);
    return summary.outstanding;
  }

  List<PaymentMode> get _availableModes =>
      BookingBuilder.availablePaymentModes(ConfigScope.of(context).settings);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && mounted) {
      setState(() => _paymentDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final operations = OperationsScope.of(context);
    final config = ConfigScope.of(context);
    final booking = operations.bookingById(widget.booking.id) ?? widget.booking;

    try {
      await operations.addPayment(
        Payment(
          id: 'payment-${DateTime.now().microsecondsSinceEpoch}',
          propertyId: config.property.id,
          bookingId: booking.id,
          guestId: booking.guestId,
          amount: double.parse(_amount.text.trim()),
          paymentMode: _mode,
          reference: _reference.text.trim(),
          notes: _notes.text.trim(),
          paymentDate: _paymentDate,
          createdBy: '',
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded')),
      );
      Navigator.of(context).pop();
    } on ValidationException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }
@override
  Widget build(BuildContext context) {
    final config = ConfigScope.of(context);
    final currency = config.property.currency;
    final outstanding = _outstanding;

    return Scaffold(
      appBar: AppBar(title: const Text('Record payment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _SummaryRow(
                      label: 'Guest',
                      value: widget.booking.guestName,
                    ),
                    _SummaryRow(
                      label: 'Total',
                      value: formatMoney(currency, widget.booking.total),
                    ),
                    _SummaryRow(
                      label: 'Outstanding',
                      value: formatMoney(currency, outstanding),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: currency.isEmpty ? null : '$currency ',
              ),
              validator: (value) {
                final error = Validators.positiveNumber(
                  value,
                  fieldName: 'Amount',
                );
                if (error != null) return error;
                final parsed = double.parse(value!.trim());
                if (parsed > outstanding + 0.005) {
                  return 'Amount exceeds the outstanding balance';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PaymentMode>(
              initialValue: _mode,
              decoration: const InputDecoration(labelText: 'Payment mode'),
              items: [
                for (final mode in _availableModes)
                  DropdownMenuItem<PaymentMode>(
                    value: mode,
                    child: Text(mode.label),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => _mode = value ?? PaymentMode.cash),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: const Text('Payment date'),
              subtitle: Text(_paymentDate.toString().split('.').first),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reference,
              decoration: const InputDecoration(labelText: 'Reference'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving || outstanding <= 0 ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('Save payment'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value),
        ],
      ),
    );
  }
}