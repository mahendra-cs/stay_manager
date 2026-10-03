import 'package:flutter/material.dart';

import '../../core/utils/money_format.dart';
import '../../core/widgets/room_status_chip.dart';
import '../../data/models/room.dart';
import 'config_controller.dart';
import 'config_scope.dart';
import 'room_form_page.dart';

/// Lists the configured rooms and lets an admin add, edit or remove them.
class RoomsSetupPage extends StatelessWidget {
  const RoomsSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final config = ConfigScope.of(context);
    final rooms = config.rooms;

    return Scaffold(
      appBar: AppBar(title: const Text('Room setup')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Add room'),
      ),
      body: rooms.isEmpty
          ? const _EmptyRooms()
          : ListView.separated(
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RoomStatusChip(status: room.status),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Delete room',
                          onPressed: () =>
                              _confirmDelete(context, config, room),
                        ),
                      ],
                    ),
                    onTap: () => _openForm(context, room),
                  ),
                );
              },
            ),
    );
  }

  void _openForm(BuildContext context, Room? room) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => RoomFormPage(room: room)),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ConfigController config,
    Room room,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete room?'),
        content: Text(
          '${room.displayName} will be removed from this property.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await config.deleteRoom(room.id);
    }
  }

  String _subtitle(Room room, String currency) {
    final parts = <String>[];
    if (room.type.trim().isNotEmpty) parts.add(room.type);
    parts.add('Floor ${room.floor}');
    parts.add(formatMoney(currency, room.basePrice));
    return parts.join(' \u00b7 ');
  }
}

class _EmptyRooms extends StatelessWidget {
  const _EmptyRooms();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No rooms yet.\nTap "Add room" to create your first room.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}