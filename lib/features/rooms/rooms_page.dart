import 'package:flutter/material.dart';

import '../../core/utils/money_format.dart';
import '../../core/widgets/room_status_chip.dart';
import '../../core/widgets/section_placeholder.dart';
import '../../data/models/room.dart';
import '../settings/config_scope.dart';

class RoomsPage extends StatelessWidget {
  const RoomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final config = ConfigScope.of(context);
    final rooms = config.rooms;

    if (rooms.isEmpty) {
      return const SectionPlaceholder(
        icon: Icons.meeting_room_outlined,
        title: 'No rooms yet',
        message: 'Add rooms from More \u2192 Room setup.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rooms.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final room = rooms[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(room.roomNumber)),
            title: Text(room.displayName),
            subtitle: Text(_subtitle(room, config.property.currency)),
            trailing: RoomStatusChip(status: room.status),
          ),
        );
      },
    );
  }

  String _subtitle(Room room, String currency) {
    final parts = <String>[];
    if (room.type.trim().isNotEmpty) parts.add(room.type);
    parts.add('Floor ${room.floor}');
    parts.add(formatMoney(currency, room.basePrice));
    return parts.join(' \u00b7 ');
  }
}
