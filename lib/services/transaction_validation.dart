class TransactionValidation {
  static const int maxDescriptionLength = 120;
  static const double maxAmount = 999999999.99;

  static String? validateAmount(String? value) {
    final text = (value ?? '').trim();

    if (text.isEmpty) {
      return 'Enter an amount';
    }

    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text)) {
      return 'Enter a valid amount with up to 2 decimal places';
    }

    final amount = double.tryParse(text);

    if (amount == null || !amount.isFinite || amount <= 0) {
      return 'Enter an amount greater than zero';
    }

    if (amount > maxAmount) {
      return 'Amount cannot exceed \$999,999,999.99';
    }

    return null;
  }

  static String? validateDescription(String? value) {
    final text = (value ?? '').trim();

    if (text.isEmpty) {
      return 'Enter a description';
    }

    if (text.length > maxDescriptionLength) {
      return 'Description cannot exceed 120 characters';
    }

    return null;
  }
}
