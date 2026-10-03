import 'package:flutter/material.dart';

import '../../data/models/room_status.dart';
import 'status_chip.dart';

/// A [StatusChip] pre-styled for a [RoomStatus].
///
/// The palette is presentation only; the status values themselves come from the
/// domain model.
class RoomStatusChip extends StatelessWidget {
  const RoomStatusChip({super.key, required this.status});

  final RoomStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _colorsFor(status);
    return StatusChip(
      label: status.label,
      background: background,
      foreground: foreground,
    );
  }

  static (Color, Color) _colorsFor(RoomStatus status) {
    return switch (status) {
      RoomStatus.available => (const Color(0xFFE3F2E5), const Color(0xFF1B5E20)),
      RoomStatus.booked => (const Color(0xFFFDF1DC), const Color(0xFF8A5A00)),
      RoomStatus.checkedIn => (
          const Color(0xFFE4EDFB),
          const Color(0xFF1B4F9C),
        ),
      RoomStatus.checkedOut => (
          const Color(0xFFECECEC),
          const Color(0xFF454545),
        ),
      RoomStatus.cleaning => (const Color(0xFFF0E7FB), const Color(0xFF5B2A9B)),
      RoomStatus.blocked => (const Color(0xFFFBE6E6), const Color(0xFF9C1B1B)),
    };
  }
}