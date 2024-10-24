import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // นำเข้า Firebase Firestore
import 'package:firebase_auth/firebase_auth.dart'; // นำเข้า Firebase Auth
import 'activity_level_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // นำเข้า Font Awesome

class GenderPage extends StatefulWidget {
  final String name;
  final double height;
  final double weight;
  final DateTime birthdate;

  const GenderPage({
    Key? key,
    required this.name,
    required this.height,
    required this.weight,
    required this.birthdate,
  }) : super(key: key);

  @override
  _GenderPageState createState() => _GenderPageState();
}

class _GenderPageState extends State<GenderPage> {
  String? _selectedGender;
  bool _isSaving = false;

  // ฟังก์ชันบันทึกข้อมูลเพศใน Firestore
  void _saveDataAndNavigate() async {
    if (_selectedGender != null) {
      setState(() {
        _isSaving = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // บันทึกข้อมูลเพศลงใน Firestore
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'gender': _selectedGender,
          }, SetOptions(merge: true)); // ใช้ merge เพื่อไม่ลบข้อมูลเดิม

          // นำทางไปยังหน้า ActivityLevelPage
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivityLevelPage(
                name: widget.name,
                height: widget.height,
                weight: widget.weight,
                birthdate: widget.birthdate,
                gender: _selectedGender!,
              ),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save data: $e')),
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Please select your gender'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/BG.png'), // แบ็คกราวด์เป็นรูปภาพ
            fit: BoxFit.cover,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Select Your Gender',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ปุ่มเพศชาย
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedGender = 'Male';
                    });
                  },
                  child: Container(
                    width: 130, // กำหนดความกว้าง
                    height: 150, // กำหนดความสูง
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedGender == 'Male' ? const Color.fromARGB(255, 33, 72, 243) : Colors.white,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // จัดให้อยู่กลาง
                      children: [
                        Icon(FontAwesomeIcons.male, size: 80, color: Color.fromARGB(255, 33, 72, 243)), // ใช้ไอคอนชาย
                        const SizedBox(height: 8),
                        const Text('Male', style: TextStyle(color: Colors.black)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // ปุ่มเพศหญิง
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedGender = 'Female';
                    });
                  },
                  child: Container(
                    width: 130, // กำหนดความกว้าง
                    height: 150, // กำหนดความสูง
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedGender == 'Female' ? Colors.pink : Colors.white,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // จัดให้อยู่กลาง
                      children: [
                        Icon(FontAwesomeIcons.female, size: 80, color: Colors.pink), // ใช้ไอคอนหญิง
                        const SizedBox(height: 8),
                        const Text('Female', style: TextStyle(color: Colors.black)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _isSaving
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _saveDataAndNavigate,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color.fromARGB(255, 0, 150, 136), // ปรับสีปุ่ม
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Next', style: TextStyle(color: Colors.white)),
                  ),
          ],
        ),
      ),
    );
  }
}
