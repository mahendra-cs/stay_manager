/// Formats a monetary amount together with the property's configured currency
/// code.
///
/// No currency symbol is hard-coded: the code comes from configuration. This is
/// intentionally dependency-free for now; locale-aware formatting can be added
/// later without changing call sites.
String formatMoney(String currencyCode, num amount) {
  final isWhole = amount == amount.roundToDouble();
  final text = isWhole ? amount.toInt().toString() : amount.toStringAsFixed(2);
  final code = currencyCode.trim();
  return code.isEmpty ? text : '$code $text';
}