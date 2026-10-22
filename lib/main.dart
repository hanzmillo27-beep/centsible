import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/database_service.dart';
import 'pages/auth_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://pirazsiijiwltfzvlqzu.supabase.co',
    publishableKey: 'sb_publishable_PZ6jyFhMPKGc7zsM3J0i7g_iE5yLRha',
  );


  runApp(const MoneyPlanApp());
}

final supabase = Supabase.instance.client;
final db = DatabaseService();

class MoneyPlanApp extends StatelessWidget {
  const MoneyPlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Centsible',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF7F7FB),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = supabase.auth.currentSession;
        if (session == null) return const AuthPage();

        return FutureBuilder<bool>(
          future: db.hasCompletedOnboarding(),
          builder: (context, onboarding) {
            if (!onboarding.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return onboarding.data!
                ? const HomePage()
                : const OnboardingPage();
          },
        );
      },
    );
  }
}
