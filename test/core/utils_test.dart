import 'package:flutter_test/flutter_test.dart';

import 'package:stay_manager/core/utils/money_format.dart';
import 'package:stay_manager/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('required rejects empty and whitespace', () {
      expect(Validators.required(''), isNotNull);
      expect(Validators.required('   '), isNotNull);
      expect(Validators.required('value'), isNull);
    });

    test('percentage enforces the 0-100 range', () {
      expect(Validators.percentage('0'), isNull);
      expect(Validators.percentage('50'), isNull);
      expect(Validators.percentage('100'), isNull);
      expect(Validators.percentage('101'), isNotNull);
      expect(Validators.percentage('-1'), isNotNull);
      expect(Validators.percentage('abc'), isNotNull);
    });

    test('positiveInt rejects zero and negatives', () {
      expect(Validators.positiveInt('2'), isNull);
      expect(Validators.positiveInt('0'), isNotNull);
      expect(Validators.positiveInt('-3'), isNotNull);
      expect(Validators.positiveInt('x'), isNotNull);
    });

    test('timeOfDay accepts 24-hour values and empty strings', () {
      expect(Validators.timeOfDay('14:00'), isNull);
      expect(Validators.timeOfDay(''), isNull);
      expect(Validators.timeOfDay('24:00'), isNotNull);
      expect(Validators.timeOfDay('9:5'), isNotNull);
    });

    test('email accepts valid addresses and empty strings', () {
      expect(Validators.email('guest@example.com'), isNull);
      expect(Validators.email(''), isNull);
      expect(Validators.email('not-an-email'), isNotNull);
    });
  });

  group('formatMoney', () {
    test('uses the configured currency code', () {
      expect(formatMoney('INR', 1500), 'INR 1500');
    });

    test('keeps two decimals for fractional amounts', () {
      expect(formatMoney('INR', 1500.5), 'INR 1500.50');
    });

    test('omits the code when currency is empty', () {
      expect(formatMoney('', 200), '200');
    });
  });
}