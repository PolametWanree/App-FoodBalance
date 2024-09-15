import 'package:flutter/material.dart';

class ImageTestPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Image from Assets'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/1.jpg', // Path ไปยังรูปภาพใน assets
              width: 300,
              height: 300,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 20),
            Text(
              'รูปภาพจาก assets',
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
