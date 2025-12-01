import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:re_source/pages/login.dart';
import 'package:re_source/pages/home.dart';
import 'package:re_source/pages/library.dart';
import 'package:re_source/pages/profile.dart';

// App-wide theme mode controller
final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier<ThemeMode>(
  ThemeMode.light,
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Re-Source',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              brightness: Brightness.light,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: null,
              foregroundColor: null,
              elevation: 0,
              centerTitle: false,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 36),
              ),
            ),
            cardTheme: const CardThemeData(elevation: 0),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: null,
              foregroundColor: null,
              elevation: 0,
              centerTitle: false,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 36),
              ),
            ),
            cardTheme: const CardThemeData(elevation: 0),
          ),
          themeMode: mode,
          home: FirebaseAuth.instance.currentUser == null
              ? const Login()
              : const MainNavigation(),
        );
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [Home(), Library(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Library',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
