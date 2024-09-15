import 'package:flutter/material.dart';
import 'package:foodbalance4/tflite.dart';
import 'FoodListPage.dart';
import 'setting_page.dart';
import 'AddFoodPage.dart';
import 'homepage.dart';
import 'chatgemini.dart';
import 'tflite.dart';
import 'MainMenu.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    MainMenu(),
    AddFoodPage(),
    ImageScannerPage(),
    FoodListPage(),
    ChatGemini()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
         selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'About',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'Chat',
          ),
        ],
      ),
    );
  }
}
