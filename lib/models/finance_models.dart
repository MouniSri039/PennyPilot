class BudgetCategory {
  final int? id;
  final String name;
  final String icon;
  final double limit;
  final String kind;

  const BudgetCategory({
    this.id,
    required this.name,
    this.icon = 'category',
    this.limit = 0,
    this.kind = 'expense',
  });

  factory BudgetCategory.fromMap(Map<String, Object?> m) => BudgetCategory(
        id: m['id'] as int,
        name: m['name'] as String,
        icon: m['icon'] as String,
        limit: (m['budget_limit'] as num).toDouble(),
        kind: (m['kind'] as String?) ?? 'expense',
      );

  Map<String, Object?> toMap() => {
        'name': name,
        'icon': icon,
        'budget_limit': limit,
        'kind': kind,
      };
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

  const MoneyTransaction({
    this.id,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.date,
    this.description = '',
    this.paymentMethod = 'Cash',
    this.receivedInto = '',
  });

  factory MoneyTransaction.fromMap(Map<String, Object?> m) => MoneyTransaction(
        id: m['id'] as int,
        categoryId: m['category_id'] as int,
        type: m['type'] as String,
        amount: (m['amount'] as num).toDouble(),
        date: DateTime.parse(m['date'] as String),
        description: m['description'] as String,
        paymentMethod: m['payment_method'] as String,
        receivedInto: (m['received_into'] as String?) ?? '',
      );

  Map<String, Object?> toMap() => {
        'category_id': categoryId,
        'type': type,
        'amount': amount,
        'date': date.toIso8601String(),
        'description': description,
        'payment_method': paymentMethod,
        'received_into': receivedInto,
      };
}

class SavingsChallenge {
  final int? id;
  final String title;
  final double target;
  final double saved;
  final String status;

  const SavingsChallenge({
    this.id,
    required this.title,
    required this.target,
    this.saved = 0,
    this.status = 'active',
  });

  factory SavingsChallenge.fromMap(Map<String, Object?> m) => SavingsChallenge(
        id: m['id'] as int,
        title: m['title'] as String,
        target: (m['target'] as num).toDouble(),
        saved: (m['saved'] as num).toDouble(),
        status: m['status'] as String,
      );

  Map<String, Object?> toMap() => {
        'title': title,
        'target': target,
        'saved': saved,
        'status': status,
      };
}

/// A single contribution made toward a savings challenge.
///
/// Each entry is stored separately so the user can review how their
/// challenge balance accumulated over time.
class ChallengeProgressEntry {
  final int? id;
  final int challengeId;
  final double amount;
  final DateTime recordedAt;

  const ChallengeProgressEntry({
    this.id,
    required this.challengeId,
    required this.amount,
    required this.recordedAt,
  });

  factory ChallengeProgressEntry.fromMap(Map<String, Object?> map) {
    return ChallengeProgressEntry(
      id: map['id'] as int?,
      challengeId: map['challenge_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      recordedAt: DateTime.parse(map['recorded_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'challenge_id': challengeId,
      'amount': amount,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }
}

/// A historical prediction saved on a particular day.
///
/// [forecastMonth] identifies the month being predicted.
/// [snapshotDate] identifies when the prediction was recorded.
class ForecastSnapshot {
  final int? id;
  final DateTime forecastMonth;
  final DateTime snapshotDate;
  final double predictedTotal;

  const ForecastSnapshot({
    this.id,
    required this.forecastMonth,
    required this.snapshotDate,
    required this.predictedTotal,
  });

  factory ForecastSnapshot.fromMap(Map<String, Object?> map) {
    return ForecastSnapshot(
      id: map['id'] as int,
      forecastMonth: DateTime.parse(map['forecast_month'] as String),
      snapshotDate: DateTime.parse(map['snapshot_date'] as String),
      predictedTotal: (map['predicted_total'] as num).toDouble(),
    );
  }

  Map<String, Object?> toMap() {
    final month = DateTime(
      forecastMonth.year,
      forecastMonth.month,
    );

    final date = DateTime(
      snapshotDate.year,
      snapshotDate.month,
      snapshotDate.day,
    );

    return {
      'forecast_month': '${month.year.toString().padLeft(4, '0')}-'
          '${month.month.toString().padLeft(2, '0')}-01',
      'snapshot_date': '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}',
      'predicted_total': predictedTotal,
    };
  }
}
