import 'package:flutter_test/flutter_test.dart';

import 'package:stay_manager/data/config/property_seed.dart';
import 'package:stay_manager/data/models/room_status.dart';

void main() {
  test('seed defines the expected property', () {
    final property = PropertySeed.property();

    expect(property.name, 'Veda Bed & Breakfast');
    expect(property.currency, isNotEmpty);
    expect(property.active, isTrue);
  });

  test('seed defines nine available rooms with unique ids', () {
    final rooms = PropertySeed.rooms();

    expect(rooms, hasLength(9));
    expect(rooms.map((room) => room.id).toSet(), hasLength(9));
    expect(
      rooms.every((room) => room.status == RoomStatus.available),
      isTrue,
    );
  });
}