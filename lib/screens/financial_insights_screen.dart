import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/finance_state.dart';
import '../widgets/common.dart';

class FinancialInsightsScreen extends StatelessWidget {
  const FinancialInsightsScreen({super.key});

  static const Color teal = Color(0xFF087D80);
  static const Color orange = Color(0xFFE69A36);
  static const Color red = Color(0xFFD9534F);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FinanceState>();
    final forecast = state.spendingForecast;
    final anomalies = state.spendingAnomalies;
    final trends = state.categoryTrends;

    if (state.loading || forecast == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final utilization = forecast.budgetUtilization ?? 0;
    final progress = utilization.clamp(0.0, 1.0);

    final recommendation = utilization > 1
        ? 'Your current spending pace may exceed your monthly budget. '
            'Review recent expenses and consider reducing discretionary spending.'
        : utilization >= 0.8
            ? 'You are approaching your monthly budget. '
                'Monitor your remaining expenses carefully.'
            : anomalies.isNotEmpty
                ? 'Your projected spending is within budget, but some '
                    'transactions are higher than your usual category spending.'
                : 'Your projected spending is within your monthly budget. '
                    'Keep tracking your expenses to maintain this progress.';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Financial Insights',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: state.reload,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('Monthly Spending Forecast'),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Projected end-of-month spending',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      money(forecast.projectedTotal),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: teal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Budget utilization'),
                        Text(
                          forecast.budgetUtilization == null
                              ? 'No budget set'
                              : '${(utilization * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(8),
                      backgroundColor: Colors.grey.shade200,
                      color: utilization > 1 ? red : teal,
                    ),
                    const SizedBox(height: 14),
                    _metricRow(
                      'Spent so far',
                      money(forecast.spentSoFar),
                    ),
                    _metricRow(
                      'Monthly budget',
                      money(forecast.monthlyBudget),
                    ),
                    _metricRow(
                      'Daily spending average',
                      money(forecast.dailyAverage),
                    ),
                    _metricRow(
                      'Days elapsed',
                      '${forecast.daysElapsed} of ${forecast.daysInMonth}',
                    ),
                    const Divider(height: 24),
                    Text(
                      forecast.explanation,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                    if (forecast.projectedOverBudget) ...[
                      const SizedBox(height: 12),
                      _statusMessage(
                        'Projected spending is above your budget.',
                        red,
                        Icons.warning_amber_rounded,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Spending Recommendations'),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2F1),
                  child: Icon(Icons.lightbulb_outline, color: teal),
                ),
                title: const Text(
                  'Your financial check',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    recommendation,
                    style: const TextStyle(height: 1.4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Unusual Spending Alerts'),
            const SizedBox(height: 10),
            if (anomalies.isEmpty)
              _emptyCard(
                Icons.verified_outlined,
                'No unusual transactions detected',
                'As you record more expenses, this section will identify '
                    'transactions that are unusually high compared with '
                    'your previous spending in the same category.',
              )
            else
              ...anomalies.map((anomaly) {
                final transaction = anomaly.transaction;
                final description = transaction.description.isEmpty
                    ? state.categoryName(transaction.categoryId)
                    : transaction.description;

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFF0E0),
                      child: Icon(
                        Icons.trending_up,
                        color: orange,
                      ),
                    ),
                    title: Text(
                      description,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        '${state.categoryName(transaction.categoryId)}\n'
                        '${anomaly.explanation}',
                        style: const TextStyle(height: 1.4),
                      ),
                    ),
                    isThreeLine: true,
                    trailing: Text(
                      money(transaction.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: red,
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 24),
            _sectionTitle('Category Spending Trends'),
            const SizedBox(height: 6),
            Text(
              'Current month compared with previous month',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            if (trends.isEmpty)
              _emptyCard(
                Icons.bar_chart,
                'Not enough spending data',
                'Record expenses in different months to see category trends.',
              )
            else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 230,
                        child: BarChart(
                          BarChartData(
                            maxY: _maxTrendValue(trends),
                            minY: 0,
                            borderData: FlBorderData(show: false),
                            gridData: const FlGridData(
                              drawVerticalLine: false,
                            ),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 42,
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 42,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index >= trends.length) {
                                      return const SizedBox.shrink();
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        state.categoryName(
                                          trends[index].categoryId,
                                        ),
                                        style: const TextStyle(fontSize: 9),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barGroups: [
                              for (var i = 0; i < trends.length; i++)
                                BarChartGroupData(
                                  x: i,
                                  barsSpace: 4,
                                  barRods: [
                                    BarChartRodData(
                                      toY: trends[i].previousMonthTotal,
                                      color: orange,
                                      width: 10,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    BarChartRodData(
                                      toY: trends[i].currentMonthTotal,
                                      color: teal,
                                      width: 10,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Wrap(
                        spacing: 20,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _Legend(color: orange, label: 'Previous month'),
                          _Legend(color: teal, label: 'Current month'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...trends.map((trend) {
                final change = trend.percentageChange;

                return Card(
                  child: ListTile(
                    title: Text(
                      state.categoryName(trend.categoryId),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Previous: ${money(trend.previousMonthTotal)}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          money(trend.currentMonthTotal),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          change == null
                              ? 'No baseline'
                              : '${change >= 0 ? '+' : ''}'
                                  '${change.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: change == null
                                ? Colors.grey
                                : change > 0
                                    ? red
                                    : teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  static Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  static Widget _statusMessage(
    String message,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _emptyCard(
    IconData icon,
    String title,
    String description,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 34, color: teal),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  static double _maxTrendValue(List<dynamic> trends) {
    var maximum = 0.0;

    for (final trend in trends) {
      if (trend.currentMonthTotal > maximum) {
        maximum = trend.currentMonthTotal;
      }
      if (trend.previousMonthTotal > maximum) {
        maximum = trend.previousMonthTotal;
      }
    }

    return maximum <= 0 ? 10 : maximum * 1.2;
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
