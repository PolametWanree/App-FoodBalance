import 'package:flutter/material.dart';
import 'package:foodbalance4/CenterButtonPage.dart';
import 'package:foodbalance4/exercise_creation_page.dart';
import 'package:foodbalance4/exercise_list_page.dart';
import 'package:foodbalance4/profilepage.dart';
import 'package:foodbalance4/tflite.dart';
import 'package:icons_plus/icons_plus.dart';
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

  final List<Widget> _pages = [
    MainMenu(),
    ExerciseListPage(),
    CenterButtonPage(),
    ProfilePage(),
    ChatGemini(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _pages[_currentIndex],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 40), // เพิ่มระยะห่างจากด้านบนของ BottomAppBar
        child: Container(
          height: 80, // ขนาดความสูงของวงกลม
          width: 80,  // ขนาดความกว้างของวงกลม
          decoration: BoxDecoration(
            shape: BoxShape.circle, // กำหนดรูปทรงวงกลม
            color: const Color.fromARGB(255, 59, 157, 79), // สีพื้นหลังของวงกลม
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 82, 82, 82).withOpacity(0.7),
                spreadRadius: 3,
                blurRadius: 6,
                offset: Offset(0, 3), // สร้างเงาให้ปุ่ม
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                _currentIndex = 2; // ไปที่หน้า Exercise เมื่อกดปุ่ม
              });
            },
            child: Icon(Icons.add, size: 40, color: Colors.white), // ไอคอนตรงกลางที่เป็น "+"
            backgroundColor: Colors.transparent, // ให้พื้นหลังปุ่มลอยใสเพื่อให้เห็นวงกลมที่กำหนด
            elevation: 0, // เอาเงาของปุ่มลอยออก เพราะใช้เงาจาก Container แทน
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: 
      BottomAppBar(
  shape: CircularNotchedRectangle(), // รูปแบบที่เว้นที่ให้ปุ่มลอย
  notchMargin: 6.0, // ระยะห่างระหว่างปุ่มกับ BottomAppBar
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround, // การจัดไอคอนซ้าย-ขวา
    children: <Widget>[
      IconButton(
        icon: Icon(Icons.home, size: 30), // ปรับขนาดไอคอนให้ใหญ่ขึ้น
        color: _currentIndex == 0 ? Colors.green : Colors.grey,
        onPressed: () {
          setState(() {
            _currentIndex = 0;
          });
        },
      ),
      IconButton(
        icon: Icon(Icons.run_circle, size: 30), // ปรับขนาดไอคอนให้ใหญ่ขึ้น
        color: _currentIndex == 1 ? Colors.green : Colors.grey,
        onPressed: () {
          setState(() {
            _currentIndex = 1;
          });
        },
      ),
      SizedBox(width: 70), // กำหนดระยะห่างที่แน่นอนระหว่างไอคอน
      IconButton(
        icon: Icon(Icons.local_fire_department, size: 30), // ปรับขนาดไอคอนให้ใหญ่ขึ้น
        color: _currentIndex == 3 ? Colors.green : Colors.grey,
        onPressed: () {
          setState(() {
            _currentIndex = 3;
          });
        },
      ),
      IconButton(
        icon: Icon(OctIcons.code_of_conduct, size: 25), // ปรับขนาดไอคอนให้ใหญ่ขึ้น
        color: _currentIndex == 4 ? Colors.green : Colors.grey,
        onPressed: () {
          setState(() {
            _currentIndex = 4;
          });
        },
      ),
    ],
  ),
)


    );
  }
}
