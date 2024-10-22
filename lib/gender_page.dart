import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // นำเข้า Firebase Firestore
import 'package:firebase_auth/firebase_auth.dart'; // นำเข้า Firebase Auth
import 'activity_level_page.dart';

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
      appBar: AppBar(
        title: const Text('Gender'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedGender,
              hint: const Text('Select Gender'),
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _isSaving
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _saveDataAndNavigate,
                    child: const Text('Next'),
                  ),
          ],
        ),
      ),
    );
  }
}
