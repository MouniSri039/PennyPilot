import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/finance_state.dart';
import 'screens/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (_) => FinanceState()..initialize(),
      child: const PennyPilotApp(),
    ),
  );
}

class PennyPilotApp extends StatelessWidget {
  const PennyPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FinanceState>();

    return MaterialApp(
      title: 'PennyPilot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF087D80),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAF9),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8FAF9),
          centerTitle: true,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF56C5C0),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121A1A),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Color(0xFF121A1A),
        ),
        cardTheme: const CardThemeData(
          color: const Color(0xFF1D2929),
          elevation: 2,
        ),
      ),
      themeMode: state.darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      home: const HomeShell(),
    );
  }
}
