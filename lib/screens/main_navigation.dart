import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'premium_screen.dart';
import 'settings_screen.dart';
import 'marksheet_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const HomeScreen(),
    const MarksheetScreen(),
    const PremiumScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: SizedBox(
              height: 20, // Small size as requested
              width: 20,
              child: Icon(Icons.grade, size: 18, color: _currentIndex == 1 ? Colors.blue : Colors.grey),
            ),
            label: 'Grade',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Premium'),
          const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
