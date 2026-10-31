enum BudgetAlertLevel {
  noBudget,
  onTrack,
  approaching,
  exceeded,
}

class BudgetAlert {
  final BudgetAlertLevel level;
  final double percentage;
  final double progress;
  final double remaining;
  final String title;
  final String message;

  const BudgetAlert({
    required this.level,
    required this.percentage,
    required this.progress,
    required this.remaining,
    required this.title,
    required this.message,
  });
}

class BudgetAlertService {
  const BudgetAlertService();

  BudgetAlert evaluate({
    required double spent,
    required double budget,
  }) {
    if (budget <= 0) {
      return const BudgetAlert(
        level: BudgetAlertLevel.noBudget,
        percentage: 0,
        progress: 0,
        remaining: 0,
        title: 'Set your monthly budget',
        message: 'Add a budget in Settings to track your spending.',
      );
    }

    final safeSpent = spent < 0 ? 0.0 : spent;
    final ratio = safeSpent / budget;
    final percentage = ratio * 100;
    final progress = ratio.clamp(0.0, 1.0).toDouble();
    final remaining = budget - safeSpent;

    if (ratio >= 1) {
      return BudgetAlert(
        level: BudgetAlertLevel.exceeded,
        percentage: percentage,
        progress: progress,
        remaining: remaining,
        title: ratio == 1 ? 'Budget limit reached' : 'Over budget',
        message: ratio == 1
            ? 'You have used your entire monthly budget.'
            : 'You are over your monthly budget by '
                '\$${(-remaining).toStringAsFixed(2)}.',
      );
    }

    if (ratio >= 0.8) {
      return BudgetAlert(
        level: BudgetAlertLevel.approaching,
        percentage: percentage,
        progress: progress,
        remaining: remaining,
        title: 'Approaching budget limit',
        message: 'You have used ${percentage.round()}% of your '
            'monthly budget. Consider limiting nonessential expenses.',
      );
    }

    return BudgetAlert(
      level: BudgetAlertLevel.onTrack,
      percentage: percentage,
      progress: progress,
      remaining: remaining,
      title: 'Budget on track',
      message: 'You have used ${percentage.round()}% of your '
          'monthly budget. Keep tracking your expenses!',
    );
  }
}
