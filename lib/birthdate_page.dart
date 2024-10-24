import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // นำเข้า Firebase Firestore
import 'package:firebase_auth/firebase_auth.dart'; // นำเข้า Firebase Auth
import 'gender_page.dart';
import 'package:intl/intl.dart';

class BirthdatePage extends StatefulWidget {
  final String name;
  final double height;
  final double weight;

  const BirthdatePage({
    Key? key,
    required this.name,
    required this.height,
    required this.weight,
  }) : super(key: key);

  @override
  _BirthdatePageState createState() => _BirthdatePageState();
}

class _BirthdatePageState extends State<BirthdatePage> {
  DateTime? _birthdate;
  bool _isSaving = false; // สถานะการบันทึก

  // ฟังก์ชันคำนวณอายุ
  int _calculateAge(DateTime birthdate) {
    DateTime now = DateTime.now();
    int age = now.year - birthdate.year;
    if (now.isBefore(DateTime(now.year, birthdate.month, birthdate.day))) {
      age--;
    }
    return age;
  }

  // ฟังก์ชันบันทึกข้อมูลลงใน Firestore และนำทางไปยังหน้า GenderPage
  void _saveDataAndNavigate() async {
    if (_birthdate != null) {
      setState(() {
        _isSaving = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          int age = _calculateAge(_birthdate!);

          // บันทึกข้อมูลวันเกิดและอายุลงใน Firestore
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'birthdate': _birthdate,
            'age': age,
          }, SetOptions(merge: true)); // ใช้ merge เพื่อไม่ลบข้อมูลเดิม

          // นำทางไปยังหน้า GenderPage
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GenderPage(
                name: widget.name,
                height: widget.height,
                weight: widget.weight,
                birthdate: _birthdate!,
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
      // แจ้งให้ผู้ใช้เลือกวันเกิด
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Please select your birthdate'),
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
            GestureDetector(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    _birthdate = picked;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Birthdate',
                  labelStyle: TextStyle(color: Color.fromARGB(255, 37, 93, 51)),
                  filled: true,
                  fillColor: Color.fromARGB(255, 255, 255, 255),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _birthdate == null
                      ? 'Select your birthdate'
                      : DateFormat.yMMMd().format(_birthdate!),
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _isSaving
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _saveDataAndNavigate,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color.fromARGB(255, 37, 93, 51), // ปรับสีปุ่ม
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
