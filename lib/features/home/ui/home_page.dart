import 'package:flutter/material.dart';
import 'widgets/play_button.dart';
import 'widgets/learn_button.dart';
import 'widgets/settings_button.dart';
import 'widgets/logout_button.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});
  void _logout(BuildContext context){
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ausgeloggt')),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
              'Geo Genius',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              LogoutButton(onLogout: () => _logout(context)),
            ],
        ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            PlayButton(),
            SizedBox(height: 50),
            LearnButton(),
            SizedBox(height: 50),
            SettingsButton(),
          ],
        ),
      ),
    );
  }
}