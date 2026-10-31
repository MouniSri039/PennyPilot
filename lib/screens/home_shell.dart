import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/finance_state.dart';
import 'dashboard_screen.dart';
import 'financial_insights_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'transaction_form_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FinanceState>();

    if (state.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null && state.categories.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text('Could not load local data: ${state.error}'),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: [
          DashboardScreen(
            onAdd: () => setState(() => index = 1),
            onHistory: () => setState(() => index = 2),
          ),
          const TransactionFormScreen(),
          const HistoryScreen(),
          const FinancialInsightsScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Add',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
