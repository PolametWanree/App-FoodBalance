import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ImageDisplayPage extends StatefulWidget {
  @override
  _ImageDisplayPageState createState() => _ImageDisplayPageState();
}

class _ImageDisplayPageState extends State<ImageDisplayPage> {
  String imageUrl = '';

  @override
  void initState() {
    super.initState();
    _getImageUrl();
  }

  Future<void> _getImageUrl() async {
    try {
      // ดึง URL ของไฟล์ที่ต้องการ
      String downloadURL = await FirebaseStorage.instance
          .ref('1.jpg') // เปลี่ยนเป็น path ที่ถูกต้องใน Firebase Storage ของคุณ
          .getDownloadURL();
      setState(() {
        imageUrl = downloadURL;
      });
    } catch (e) {
      print('Error fetching image URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image from Firebase Storage'),
      ),
      body: Center(
        child: imageUrl.isNotEmpty
            ? Image.network(imageUrl)
            : CircularProgressIndicator(),
      ),
    );
  }
}
