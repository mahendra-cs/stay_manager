/// Small, dependency-free date helpers.
///
/// All booking/availability logic works on calendar days, so timestamps are
/// normalised with [dateOnly] before comparison.
class AppDate {
  const AppDate._();

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Inclusive start / exclusive end of the calendar month containing [value].
  static (DateTime, DateTime) monthRange(DateTime value) {
    final start = DateTime(value.year, value.month);
    final end = DateTime(value.year, value.month + 1);
    return (start, end);
  }

  /// `dd-MM-yyyy` for display.
  static String format(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day-$month-${value.year}';
  }
}