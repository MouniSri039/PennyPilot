import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/budget_alert_service.dart';
import '../state/finance_state.dart';
import '../widgets/common.dart';
import 'challenge_screen.dart';
import 'transaction_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onHistory;

  const DashboardScreen({
    super.key,
    required this.onAdd,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FinanceState>();
    final recent = state.transactions.take(4).toList();

    final alert = const BudgetAlertService().evaluate(
      spent: state.spent,
      budget: state.monthlyBudget,
    );

    final Color alertColor;
    final IconData alertIcon;

    switch (alert.level) {
      case BudgetAlertLevel.noBudget:
        alertColor = Colors.blueGrey;
        alertIcon = Icons.info_outline;
        break;
      case BudgetAlertLevel.onTrack:
        alertColor = const Color(0xFF087D80);
        alertIcon = Icons.check_circle_outline;
        break;
      case BudgetAlertLevel.approaching:
        alertColor = const Color(0xFFB76E00);
        alertIcon = Icons.warning_amber_rounded;
        break;
      case BudgetAlertLevel.exceeded:
        alertColor = const Color(0xFFB3261E);
        alertIcon = Icons.error_outline;
        break;
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const Icon(
                Icons.eco,
                size: 32,
                color: Color(0xFF087D80),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'PennyPilot',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Savings challenge',
                icon: const Icon(Icons.savings_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChallengeScreen(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Card(
            color: const Color(0xFF087D80),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly Budget',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    money(state.monthlyBudget),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  LinearProgressIndicator(
                    key: const Key('monthly-budget-progress'),
                    value: alert.progress,
                    minHeight: 12,
                    backgroundColor: Colors.white30,
                    color: alert.level == BudgetAlertLevel.exceeded
                        ? Colors.redAccent
                        : alert.level == BudgetAlertLevel.approaching
                            ? Colors.amber
                            : const Color(0xFFF2C87D),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${alert.percentage.round()}% used',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '${money(state.spent)} spent',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          alert.remaining >= 0
                              ? '${money(alert.remaining)} remaining'
                              : '${money(-alert.remaining)} over',
                          textAlign: TextAlign.end,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            key: const Key('budget-alert-card'),
            child: ListTile(
              leading: Icon(alertIcon, color: alertColor),
              title: Text(
                alert.title,
                style: TextStyle(
                  color: alertColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(alert.message),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: const Text('Spending Check'),
              subtitle: Text(state.tip),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onHistory,
                child: const Text('See All'),
              ),
            ],
          ),
          if (recent.isEmpty)
            const Card(
              child: ListTile(
                title: Text('No transactions yet'),
                subtitle: Text(
                  'Tap Add to record your first purchase.',
                ),
              ),
            ),
          for (final t in recent)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(
                    t.type == 'income'
                        ? Icons.south_west
                        : Icons.shopping_bag_outlined,
                  ),
                ),
                title: Text(
                  t.description.isEmpty
                      ? state.categoryName(t.categoryId)
                      : t.description,
                ),
                subtitle: Text(
                  '${state.categoryName(t.categoryId)} · '
                  '${shortDate(t.date)}',
                ),
                trailing: Text(
                  '${t.type == 'expense' ? '-' : '+'}'
                  '${money(t.amount)}',
                  style: TextStyle(
                    color: t.type == 'expense' ? Colors.red : Colors.green,
                  ),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TransactionDetailScreen(transaction: t),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Transaction'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ChallengeScreen(),
              ),
            ),
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Savings Challenges'),
          ),
        ],
      ),
    );
  }
}
