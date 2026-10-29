import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/finance_state.dart';
import '../widgets/common.dart';
import 'transaction_detail_screen.dart';
import 'challenge_screen.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onHistory;
  const DashboardScreen(
      {super.key, required this.onAdd, required this.onHistory});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<FinanceState>();
    final recent = state.transactions.take(4).toList();
    return SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
      Row(children: [
        const Icon(Icons.eco, size: 32, color: Color(0xFF087D80)),
        const SizedBox(width: 8),
        const Expanded(
            child: Text('PennyPilot',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
        IconButton(
            tooltip: 'Savings challenge',
            icon: const Icon(Icons.savings_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ChallengeScreen())))
      ]),
      const SizedBox(height: 18),
      Card(
          color: const Color(0xFF087D80),
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Monthly Budget',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18)),
                          Text(money(state.monthlyBudget),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 22))
                        ]),
                    const SizedBox(height: 18),
                    LinearProgressIndicator(
                        value: state.monthlyBudget <= 0
                            ? 0
                            : (state.spent / state.monthlyBudget)
                                .clamp(0.0, 1.0),
                        minHeight: 12,
                        backgroundColor: Colors.white30,
                        color: const Color(0xFFF2C87D)),
                    const SizedBox(height: 14),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${money(state.spent)} spent',
                              style: const TextStyle(color: Colors.white)),
                          Text('${money(state.remaining)} remaining',
                              style: const TextStyle(color: Colors.white))
                        ])
                  ]))),
      const SizedBox(height: 18),
      Card(
          child: ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: const Text('Spending Check'),
              subtitle: Text(state.tip))),
      const SizedBox(height: 14),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Recent Transactions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        TextButton(onPressed: onHistory, child: const Text('See All'))
      ]),
      if (recent.isEmpty)
        const Card(
            child: ListTile(
                title: Text('No transactions yet'),
                subtitle: Text('Tap Add to record your first purchase.'))),
      for (final t in recent)
        Card(
            child: ListTile(
                leading: CircleAvatar(
                    child: Icon(t.type == 'income'
                        ? Icons.south_west
                        : Icons.shopping_bag_outlined)),
                title: Text(t.description.isEmpty
                    ? state.categoryName(t.categoryId)
                    : t.description),
                subtitle: Text(
                    '${state.categoryName(t.categoryId)} · ${shortDate(t.date)}'),
                trailing: Text(
                    '${t.type == 'expense' ? '-' : '+'}${money(t.amount)}',
                    style: TextStyle(
                        color:
                            t.type == 'expense' ? Colors.red : Colors.green)),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            TransactionDetailScreen(transaction: t))))),
      const SizedBox(height: 16),
      FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add Transaction')),
      OutlinedButton.icon(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ChallengeScreen())),
          icon: const Icon(Icons.flag_outlined),
          label: const Text('Savings Challenges')),
    ]));
  }
}
