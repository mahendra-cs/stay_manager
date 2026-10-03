import 'package:flutter/material.dart';

import '../../core/utils/app_date.dart';
import '../../core/utils/money_format.dart';
import '../operations/operations_scope.dart';
import '../settings/config_scope.dart';
import 'dashboard_widgets.dart';

/// Occupancy, arrivals, departures, revenue and outstanding (spec \u00a716).
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final config = ConfigScope.of(context);
    final operations = OperationsScope.of(context);
    final property = config.property;
    final theme = Theme.of(context);
    final currency = property.currency;
    final today = AppDate.today();

    final arrivals = operations.arrivalsOn(today);
    final departures = operations.departuresOn(today);
    final recent = operations.recentBookings();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(property.name, style: theme.textTheme.headlineSmall),
        if (property.hasAddress) ...[
          const SizedBox(height: 4),
          Text(property.address, style: theme.textTheme.bodyMedium),
        ],
        const SizedBox(height: 24),

        Text('Occupancy', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DashboardMetricCard(
                label: 'Total',
                value: '${config.totalRooms}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DashboardMetricCard(
                label: 'Available',
                value: '${config.availableRooms}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DashboardMetricCard(
                label: 'Occupied',
                value: '${config.occupiedRooms}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Text('Today', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DashboardMetricCard(
                label: 'Arrivals',
                value: '${arrivals.length}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DashboardMetricCard(
                label: 'Departures',
                value: '${departures.length}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Text('Collection today', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        DashboardMoneyRow(
          label: 'Revenue',
          value: formatMoney(currency, operations.revenueToday),
        ),
        DashboardMoneyRow(
          label: 'Cash',
          value: formatMoney(currency, operations.cashToday),
        ),
        DashboardMoneyRow(
          label: 'Online',
          value: formatMoney(currency, operations.onlineToday),
        ),
        DashboardMoneyRow(
          label: 'Expenses',
          value: formatMoney(currency, operations.expenseToday),
        ),
        DashboardMoneyRow(
          label: 'Outstanding',
          value: formatMoney(currency, operations.outstandingTotal),
          emphasise: operations.outstandingTotal > 0,
        ),
        const SizedBox(height: 24),

        DashboardBookingList(
          title: 'Today''s arrivals',
          bookings: arrivals,
          currency: currency,
          emptyMessage: 'No arrivals expected today.',
        ),
        const SizedBox(height: 24),

        DashboardBookingList(
          title: 'Today''s departures',
          bookings: departures,
          currency: currency,
          emptyMessage: 'No departures expected today.',
        ),
        const SizedBox(height: 24),

        DashboardBookingList(
          title: 'Recent bookings',
          bookings: recent,
          currency: currency,
          emptyMessage: 'No bookings yet. Use the Bookings tab to add one.',
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
