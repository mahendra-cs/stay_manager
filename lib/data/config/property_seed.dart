import '../../core/constants/app_defaults.dart';
import '../models/app_settings.dart';
import '../models/property.dart';
import '../models/room.dart';
import '../models/room_status.dart';

/// Initial (seed) configuration.
///
/// This is **data, not business logic**. It exists purely so the app has
/// something meaningful to show on first run, before an admin configures the
/// property from the in-app screens. Nothing here is referenced from widgets —
/// the UI always reads configuration through `ConfigScope`.
///
/// Edit these values from *More → Property setup* / *Room setup* at runtime.
/// From Phase 11 the same shape is loaded from / saved to Firestore, and this
/// seed can then be removed or used only for first-run provisioning.
class PropertySeed {
  const PropertySeed._();

  static const String propertyId = 'property-default';
  static const String settingsId = 'settings-default';

  /// Number of rooms provisioned in the seed.
  static const int roomCount = 9;

  static Property property() {
    return const Property(
      id: propertyId,
      name: 'Veda Bed & Breakfast',
      currency: 'INR',
      timezone: 'Asia/Kolkata',
      taxEnabled: false,
      taxPercentage: 0,
      checkInTime: '14:00',
      checkOutTime: '11:00',
      active: true,
    );
  }

  static AppSettings settings() {
    return const AppSettings(
      id: settingsId,
      propertyId: propertyId,
      roomTypes: AppDefaults.roomTypes,
      paymentModes: AppDefaults.paymentModes,
      bookingSources: AppDefaults.bookingSources,
      expenseCategories: AppDefaults.expenseCategories,
      checkoutRequiresSettlement: false,
      roomStatusAfterCheckout: RoomStatus.cleaning,
    );
  }

  /// Nine rooms numbered `1`–`9`. Prices and types are left at neutral
  /// defaults and are meant to be filled in by the admin.
  static List<Room> rooms() {
    return List<Room>.generate(roomCount, (index) {
      final number = '${index + 1}';
      return Room(
        id: 'room-$number',
        propertyId: propertyId,
        roomNumber: number,
        name: 'Room $number',
        type: AppDefaults.roomTypes.first,
        floor: 1,
        maxOccupancy: 2,
        basePrice: 0,
        status: RoomStatus.available,
        active: true,
      );
    }, growable: false);
  }
}