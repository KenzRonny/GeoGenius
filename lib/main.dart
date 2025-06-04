import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app_state.dart';
import 'firebase_options.dart';
import 'features/login/login_first_page.dart';
import 'features/home/ui/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => ApplicationState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geo Genius',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<ApplicationState>(context);

    if (!appState.initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!appState.loggedIn) {
      return const FirstLoginPage();
    }

    // App-Navigation: entweder Home (mit BottomNav) oder Spielmodus (ohne)
    return appState.mainView == MainView.dashboard
        ? const MyHomePage() // enthält BottomNavigationBar intern
        : const FullScreenOverlay(); // Spielmodus
  }
}

/// Diese Ansicht erscheint, wenn ein Spielmodus aktiv ist, ohne BottomNavigationBar.
class FullScreenOverlay extends StatelessWidget {
  const FullScreenOverlay({super.key});

  @override
  Widget build(BuildContext context) {

    return const Scaffold(
      body: Center(child: Text("Vollbild-Modus aktiv (z. B. Spielmodus)")),
    );
  }
}
