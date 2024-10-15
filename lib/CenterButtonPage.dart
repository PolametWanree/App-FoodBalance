import 'package:flutter/material.dart';
import 'package:foodbalance4/FoodListPage.dart';
import 'package:foodbalance4/tflite.dart';

// หน้าหลักที่มีสองปุ่ม
class CenterButtonPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // ปุ่มแรก
            GestureDetector(
              onTap: () {
                // เมื่อกดปุ่มแรก จะไปยังหน้าที่สอง
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ImageScannerPage()),
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // วงกลมปุ่มหลัก
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color.fromARGB(255, 52, 157, 90), // สีขอบของปุ่ม
                        width: 3, // ความหนาของขอบ
                      ),
                    ),
                    child: Icon(
                      Icons.camera_enhance, // ไอคอนตรงกลาง
                      size: 40,
                      color: const Color.fromARGB(255, 52, 157, 90),
                    ),
                  ),
                ],
              ),
            ),
            // ปุ่มที่สอง
            GestureDetector(
              onTap: () {
                // เมื่อกดปุ่มที่สอง จะไปยังหน้าที่สาม
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FoodListPage()),
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // วงกลมปุ่มหลัก
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color.fromARGB(255, 52, 157, 90), // สีขอบของปุ่ม
                        width: 3, // ความหนาของขอบ
                      ),
                    ),
                    child: Icon(
                      Icons.restaurant_menu, // ไอคอนตรงกลางของปุ่มที่สอง
                      size: 40,
                      color: const Color.fromARGB(255, 52, 157, 90),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
