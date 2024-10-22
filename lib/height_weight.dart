import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // นำเข้า Firebase Firestore
import 'package:firebase_auth/firebase_auth.dart'; // นำเข้า Firebase Auth
import 'birthdate_page.dart';

class HeightWeightPage extends StatefulWidget {
  const HeightWeightPage({Key? key}) : super(key: key);

  @override
  _HeightWeightPageState createState() => _HeightWeightPageState();
}

class _HeightWeightPageState extends State<HeightWeightPage> {
  double _height = 170;
  double _weight = 70;
  String _name = '';
  bool _isSaving = false; // แสดงสถานะการบันทึก

  // ฟังก์ชันบันทึกข้อมูลใน Firestore
  void _saveDataAndNavigate() async {
    if (_name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _name,
          'height': _height,
          'weight': _weight,
          'roll': 'user',
        }, SetOptions(merge: true)); // ใช้ merge เพื่อไม่ลบข้อมูลเดิม

        // หลังจากบันทึกข้อมูลเสร็จแล้ว นำทางไปยัง BirthdatePage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BirthdatePage(
              name: _name,
              height: _height,
              weight: _weight,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Height & Weight'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
                onChanged: (value) {
                  setState(() {
                    _name = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Text('Height: ${_height.toStringAsFixed(1)} cm'),
              Slider(
                value: _height,
                min: 100,
                max: 250,
                divisions: 150,
                onChanged: (value) {
                  setState(() {
                    _height = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Text('Weight: ${_weight.toStringAsFixed(1)} kg'),
              Slider(
                value: _weight,
                min: 30,
                max: 200,
                divisions: 170,
                onChanged: (value) {
                  setState(() {
                    _weight = value;
                  });
                },
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
      ),
    );
  }
}
