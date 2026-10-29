class BudgetCategory {
  final int? id;
  final String name;
  final String icon;
  final double limit;
  final String kind;
  const BudgetCategory(
      {this.id,
      required this.name,
      this.icon = 'category',
      this.limit = 0,
      this.kind = 'expense'});
  factory BudgetCategory.fromMap(Map<String, Object?> m) => BudgetCategory(
      id: m['id'] as int,
      name: m['name'] as String,
      icon: m['icon'] as String,
      limit: (m['budget_limit'] as num).toDouble(),
      kind: (m['kind'] as String?) ?? 'expense');
  Map<String, Object?> toMap() =>
      {'name': name, 'icon': icon, 'budget_limit': limit, 'kind': kind};
}

class MoneyTransaction {
  final int? id;
  final int categoryId;
  final String type;
  final double amount;
  final DateTime date;
  final String description;
  final String paymentMethod;
  final String receivedInto;
  const MoneyTransaction(
      {this.id,
      required this.categoryId,
      required this.type,
      required this.amount,
      required this.date,
      this.description = '',
      this.paymentMethod = 'Cash',
      this.receivedInto = ''});
  factory MoneyTransaction.fromMap(Map<String, Object?> m) => MoneyTransaction(
      id: m['id'] as int,
      categoryId: m['category_id'] as int,
      type: m['type'] as String,
      amount: (m['amount'] as num).toDouble(),
      date: DateTime.parse(m['date'] as String),
      description: m['description'] as String,
      paymentMethod: m['payment_method'] as String,
      receivedInto: (m['received_into'] as String?) ?? '');
  Map<String, Object?> toMap() => {
        'category_id': categoryId,
        'type': type,
        'amount': amount,
        'date': date.toIso8601String(),
        'description': description,
        'payment_method': paymentMethod,
        'received_into': receivedInto
      };
}

class SavingsChallenge {
  final int? id;
  final String title;
  final double target;
  final double saved;
  final String status;
  const SavingsChallenge(
      {this.id,
      required this.title,
      required this.target,
      this.saved = 0,
      this.status = 'active'});
  factory SavingsChallenge.fromMap(Map<String, Object?> m) => SavingsChallenge(
      id: m['id'] as int,
      title: m['title'] as String,
      target: (m['target'] as num).toDouble(),
      saved: (m['saved'] as num).toDouble(),
      status: m['status'] as String);
  Map<String, Object?> toMap() =>
      {'title': title, 'target': target, 'saved': saved, 'status': status};
}
