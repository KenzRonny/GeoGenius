import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

/// Enum für Ansicht mit oder ohne BottomNavigationBar
enum MainView {
  dashboard,   // mit BottomNavigationBar
  fullScreen,  // Spielmodus, ohne NavBar
}

class ApplicationState extends ChangeNotifier {
  ApplicationState() {
    init();
  }

  bool _initialized = false;
  bool get initialized => _initialized;

  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

  User? _user;
  User? get user => _user;

  /// Aktuelle Ansicht (für NavBar oder Fullscreen)
  MainView _mainView = MainView.dashboard;
  MainView get mainView => _mainView;

  /// Aktuell ausgewählter BottomNavBar-Index
  int _bottomNavIndex = 0;
  int get bottomNavIndex => _bottomNavIndex;

  Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseUIAuth.configureProviders([
    ]);

    FirebaseAuth.instance.userChanges().listen((user) {
      _user = user;
      _loggedIn = user != null;
      notifyListeners();
    });

    _initialized = true;
    notifyListeners();
  }

  void setMainView(MainView view) {
    _mainView = view;
    notifyListeners();
  }

  void setBottomNavIndex(int index) {
    _bottomNavIndex = index;
    notifyListeners();
  }
}
