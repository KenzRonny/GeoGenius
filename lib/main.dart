import 'package:flutter/material.dart';
import 'app_state.dart';
import 'features/home/ui/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/login/login_first_page.dart';
import 'package:provider/provider.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ChangeNotifierProvider(
    create: (context) => ApplicationState(),
    builder: ((context, child) => const MyApp()),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geo Genius',
      theme: ThemeData(
        primaryColor: const Color(0xFF00008B),
      ),
      home: AuthGate(),
      //home: const MyHomePage(),//(title: 'Geo Genius'),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate ({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<ApplicationState>(context);

    if (!appState.initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (appState.loggedIn) {
      return const MyHomePage(); // Eingeloggter User
    } else {
      return const FirstLoginPage(); // Nicht eingeloggt
    }
  }
}

