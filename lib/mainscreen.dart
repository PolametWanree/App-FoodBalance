import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:foodbalance4/tflite.dart';
import 'FoodListPage.dart';
import 'setting_page.dart';
import 'AddFoodPage.dart';
import 'homepage.dart';
import 'chatgemini.dart';
import 'tflite.dart';
import 'MainMenu.dart';
import 'FirebaseStorageTest.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // ตรวจสอบให้แน่ใจว่ามี 4 หน้าในรายการ _pages 
  final List<Widget> _pages = [
    MainMenu(),
    FoodListPage(),
    ChatGemini(),
    AddFoodPage(), // 4 หน้าใน _pages
    ImageDisplayPage(),
    ImageScannerPage(),
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
            icon: Icon(Icons.info),
            label: 'About',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Test',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera),
            label: 'Test',
          ),
        ],
      ),
    );
  }
}
