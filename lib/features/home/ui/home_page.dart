import 'package:flutter/material.dart';
import 'package:geo_genius/widgets/custom_bottom_nav_bar.dart';
import 'package:geo_genius/app_state.dart';
import 'package:provider/provider.dart';
import 'widgets/game_modes_overview.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<ApplicationState>(context);
    final currentIndex = appState.bottomNavIndex;

    final List<Widget> pages = [
      const GameModesOverview(), // Tab 0 – Startseite
      const Center(child: Text('Lernen')), // Tab 1 – Lernen
      const Center(child: Text('Profil')), // Tab 2 – Profil
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text('GeoGenius'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.settings),
          ),
        ],
        elevation: 0,
      ),
      body: pages[currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          appState.setBottomNavIndex(index);
        },
      ),
    );
  }
}
