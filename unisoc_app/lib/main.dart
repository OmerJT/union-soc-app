import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';

/// Main entry point for the UniSoc Flutter application.
/// Initializes the app with authentication state management using Provider.
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: const UniSocApp(),
    ),
  );
}

/// Root widget of the UniSoc application.
/// Manages authentication state and displays appropriate screens based on login status.
class UniSocApp extends StatefulWidget {
  const UniSocApp({super.key});

  @override
  State<UniSocApp> createState() => _UniSocAppState();
}

class _UniSocAppState extends State<UniSocApp> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      // Load authentication token on app startup
      Provider.of<AuthService>(context, listen: false).loadToken().then((_) {
        if (mounted) setState(() => _loaded = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniSoc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
        useMaterial3: true,
      ),
      home: !_loaded
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : Consumer<AuthService>(
              builder: (context, auth, _) {
                return auth.isLoggedIn ? const HomeScreen() : const LoginScreen();
              },
            ),
    );
  }
}
