import 'package:flutter/material.dart';

class LogoutButton extends StatelessWidget {
  final VoidCallback onLogout; // Callback für Logout-Action

  const LogoutButton({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: (){
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ausgeloggt')),
        );
      }, // Wenn der Button gedrückt wird, wird onLogout aufgerufen

      icon: const Icon(Icons.logout),
      color: Colors.white,
    );
  }

}
