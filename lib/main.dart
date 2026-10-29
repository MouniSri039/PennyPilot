import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/finance_state.dart';
import 'screens/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ChangeNotifierProvider(
      create: (_) => FinanceState()..initialize(),
      child: const PennyPilotApp()));
}

class PennyPilotApp extends StatelessWidget {
  const PennyPilotApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'PennyPilot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF087D80)),
          scaffoldBackgroundColor: const Color(0xFFF8FAF9),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF8FAF9), centerTitle: true)),
      home: const HomeShell());
}
