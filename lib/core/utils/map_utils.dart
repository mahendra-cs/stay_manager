/// Defensive helpers for reading values out of raw maps (for example a
/// Firestore document snapshot) into strongly typed Dart values.
///
/// Keeping this logic in one place avoids duplicating `as` casts and null
/// checks across every model and makes the models resilient to partial or
/// malformed documents.
class MapUtils {
  const MapUtils._();

  static String asString(Object? value, [String fallback = '']) =>
      value is String ? value : fallback;

  static double asDouble(Object? value, [double fallback = 0]) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static int asInt(Object? value, [int fallback = 0]) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static bool asBool(Object? value, [bool fallback = false]) =>
      value is bool ? value : fallback;

  static DateTime? asDateTime(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static List<String> asStringList(Object? value) => value is Iterable
      ? value.whereType<String>().toList(growable: false)
      : const <String>[];
}