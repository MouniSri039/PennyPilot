import 'package:flutter_test/flutter_test.dart';
import 'package:pennypilot/services/transaction_validation.dart';

void main() {
  group('Transaction amount validation', () {
    test('accepts valid amounts', () {
      for (final value in ['1', '12.5', '12.50', '0.01', '999999999.99']) {
        expect(
          TransactionValidation.validateAmount(value),
          isNull,
          reason: 'Expected valid amount: \\$value',
        );
      }
    });

    test('rejects empty amounts', () {
      expect(TransactionValidation.validateAmount(''), isNotNull);
      expect(TransactionValidation.validateAmount('  '), isNotNull);
      expect(TransactionValidation.validateAmount(null), isNotNull);
    });

    test('rejects zero and negative amounts', () {
      expect(TransactionValidation.validateAmount('0'), isNotNull);
      expect(TransactionValidation.validateAmount('-5'), isNotNull);
    });

    test('rejects amounts with excessive decimal places', () {
      expect(TransactionValidation.validateAmount('12.345'), isNotNull);
      expect(TransactionValidation.validateAmount('0.001'), isNotNull);
    });

    test('rejects invalid numeric input', () {
      expect(TransactionValidation.validateAmount('abc'), isNotNull);
      expect(TransactionValidation.validateAmount('NaN'), isNotNull);
      expect(TransactionValidation.validateAmount('Infinity'), isNotNull);
    });

    test('rejects amounts above the maximum', () {
      expect(
        TransactionValidation.validateAmount('1000000000'),
        isNotNull,
      );
    });
  });

  group('Transaction description validation', () {
    test('accepts valid descriptions', () {
      expect(
        TransactionValidation.validateDescription('Groceries'),
        isNull,
      );
      expect(
        TransactionValidation.validateDescription('  Coffee  '),
        isNull,
      );
      expect(
        TransactionValidation.validateDescription('A' * 120),
        isNull,
      );
    });

    test('rejects empty descriptions', () {
      expect(TransactionValidation.validateDescription(''), isNotNull);
      expect(TransactionValidation.validateDescription('   '), isNotNull);
      expect(TransactionValidation.validateDescription(null), isNotNull);
    });

    test('rejects descriptions longer than 120 characters', () {
      expect(
        TransactionValidation.validateDescription('A' * 121),
        isNotNull,
      );
    });
  });
}
