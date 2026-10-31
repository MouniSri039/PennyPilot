import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/finance_models.dart';
import '../state/finance_state.dart';
import '../widgets/common.dart';
import 'transaction_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int? filterCategory;
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FinanceState>();

    // Monthly and category filters control financial insights.
    final filtered = state.transactions
        .where(
          (t) =>
              t.date.year == month.year &&
              t.date.month == month.month &&
              (filterCategory == null || t.categoryId == filterCategory),
        )
        .toList();

    // Search only narrows the transaction list, not the financial chart.
    final query = searchQuery.trim().toLowerCase();

    final searchedTransactions = filtered.where((t) {
      if (query.isEmpty) return true;

      final description = t.description.toLowerCase();
      final category = state.categoryName(t.categoryId).toLowerCase();

      return description.contains(query) || category.contains(query);
    }).toList();

    final spent = filtered
        .where((t) => t.type == 'expense')
        .fold<double>(0, (sum, t) => sum + t.amount);

    final income = filtered
        .where((t) => t.type == 'income')
        .fold<double>(0, (sum, t) => sum + t.amount);

    final expenseByCategory = <int, double>{};

    for (final t in filtered.where((t) => t.type == 'expense')) {
      expenseByCategory[t.categoryId] =
          (expenseByCategory[t.categoryId] ?? 0) + t.amount;
    }

    final entries = expenseByCategory.entries.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('History & Insights')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: filterCategory == null,
                  onSelected: (_) {
                    setState(() => filterCategory = null);
                  },
                ),
                const SizedBox(width: 8),
                for (final c in state.categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c.name),
                      selected: filterCategory == c.id,
                      onSelected: (_) {
                        setState(() => filterCategory = c.id);
                      },
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    month = DateTime(month.year, month.month - 1);
                  });
                },
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '${month.year} – ${month.month.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    month = DateTime(month.year, month.month + 1);
                  });
                },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Spent'),
                      Text(money(spent)),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Income'),
                      Text(money(income)),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Transactions'),
                      Text('${filtered.length}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Expenses by Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            const Card(
              child: ListTile(
                title: Text('No expense data for this selection'),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();

                          if (i < 0 || i >= entries.length) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              state.categoryName(entries[i].key),
                              style: const TextStyle(fontSize: 9),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < entries.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: entries[i].value,
                            width: 22,
                            color: const Color(0xFF087D80),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          const Text(
            'Transactions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Search transactions by description or category.
          TextField(
            key: const Key('transaction-search'),
            decoration: const InputDecoration(
              labelText: 'Search Transactions',
              hintText: 'Search by description or category',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.search,
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),

          if (query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${searchedTransactions.length} matching transaction(s)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),

          if (searchedTransactions.isEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.search_off),
                title: Text(
                  query.isNotEmpty
                      ? 'No matching transactions'
                      : 'No transactions for this selection',
                ),
                subtitle: Text(
                  query.isNotEmpty
                      ? 'Try another description or category.'
                      : 'Try selecting another month or category.',
                ),
              ),
            ),

          for (final MoneyTransaction t in searchedTransactions)
            Card(
              child: ListTile(
                title: Text(
                  t.description.isEmpty
                      ? state.categoryName(t.categoryId)
                      : t.description,
                ),
                subtitle: Text(
                  '${state.categoryName(t.categoryId)} · ${shortDate(t.date)}',
                ),
                trailing: Text(
                  '${t.type == 'expense' ? '-' : '+'}${money(t.amount)}',
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TransactionDetailScreen(transaction: t),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
