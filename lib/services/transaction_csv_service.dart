import '../models/finance_models.dart';

class TransactionCsvService {
  const TransactionCsvService();

  static const String header =
      'Date,Type,Category,Amount,Description,Payment Method,Received Into';

  String generate({
    required List<MoneyTransaction> transactions,
    required List<BudgetCategory> categories,
  }) {
    final categoryNames = <int, String>{
      for (final category in categories)
        if (category.id != null) category.id!: category.name,
    };

    final sorted = List<MoneyTransaction>.of(transactions)
      ..sort((a, b) {
        final dateComparison = b.date.compareTo(a.date);
        if (dateComparison != 0) return dateComparison;
        return (b.id ?? 0).compareTo(a.id ?? 0);
      });

    final lines = <String>[header];

    for (final transaction in sorted) {
      final date = transaction.date;
      final formattedDate = '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';

      final fields = [
        formattedDate,
        transaction.type,
        categoryNames[transaction.categoryId] ?? 'Unknown',
        transaction.amount.toStringAsFixed(2),
        transaction.description,
        transaction.paymentMethod,
        transaction.receivedInto,
      ];

      lines.add(fields.map(_escape).join(','));
    }

    return '${lines.join('\r\n')}\r\n';
  }

  String _escape(String value) {
    // Prevent spreadsheet applications from interpreting user-entered
    // descriptions or category names as formulas.
    final firstNonWhitespace = value.trimLeft();

    if (firstNonWhitespace.isNotEmpty &&
        '=+-@\t\r\n'.contains(firstNonWhitespace[0])) {
      value = "'$value";
    }

    final escaped = value.replaceAll('"', '""');

    if (escaped.contains(',') ||
        escaped.contains('"') ||
        escaped.contains('\n') ||
        escaped.contains('\r')) {
      return '"$escaped"';
    }

    return escaped;
  }
}
