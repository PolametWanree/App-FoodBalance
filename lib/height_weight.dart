import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // ใช้สำหรับจัดการวันที่
import 'package:uuid/uuid.dart'; // ใช้สำหรับสุ่ม user_id

class HeightWeightPage extends StatefulWidget {
  const HeightWeightPage({Key? key}) : super(key: key);

  @override
  _HeightWeightPageState createState() => _HeightWeightPageState();
}

class _HeightWeightPageState extends State<HeightWeightPage> {
  double _height = 170;
  double _weight = 70;
  String _name = '';
  DateTime? _birthdate;
  String? _selectedGender;
  String? _selectedActivityLevel;
  bool _isSaving = false;

  // ฟังก์ชันคำนวณ BMR
  double _calculateBMR() {
    int age = DateTime.now().year - _birthdate!.year;
    if (DateTime.now().isBefore(DateTime(DateTime.now().year, _birthdate!.month, _birthdate!.day))) {
      age--;
    }

    if (_selectedGender == 'Male') {
      return 88.362 + (13.397 * _weight) + (4.799 * _height) - (5.677 * age);
    } else {
      return 447.593 + (9.247 * _weight) + (3.098 * _height) - (4.330 * age);
    }
  }

  // ฟังก์ชันคำนวณ TDEE
  double _calculateTDEE(double bmr) {
    switch (_selectedActivityLevel) {
      case 'Sedentary':
        return bmr * 1.2;
      case 'Lightly active':
        return bmr * 1.375;
      case 'Moderately active':
        return bmr * 1.55;
      case 'Very active':
        return bmr * 1.725;
      case 'Super active':
        return bmr * 1.9;
      default:
        return bmr * 1.2;
    }
  }

void _saveData() async {
  if (_birthdate == null || _selectedGender == null || _selectedActivityLevel == null) {
    // แสดงข้อความ error ถ้าเลือกข้อมูลไม่ครบ
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Incomplete Information'),
        content: const Text('Please complete all fields.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return;
  }

  // คำนวณอายุ
   int age = DateTime.now().year - _birthdate!.year;
  if (DateTime.now().isBefore(DateTime(DateTime.now().year, _birthdate!.month, _birthdate!.day))) {
    age--;
  }

  setState(() {
    _isSaving = true;
  });

  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Generate a random user_id
      String userId = const Uuid().v4();

      // คำนวณ BMR และ TDEE
      double bmr = _calculateBMR();
      int tdee = _calculateTDEE(bmr).round();

      // บันทึกข้อมูลพื้นฐานไปยัง collection users
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'user_id': userId,
        'name': _name,
        'height': _height,
        'weight': _weight,
        'birthdate': _birthdate,
        'age': age,
        'gender': _selectedGender,
        'activity_level': _selectedActivityLevel,
      });

      // บันทึก TDEE ไปยัง collection user_record
      await FirebaseFirestore.instance.collection('user_record').doc(user.uid).set({
        'user_id': userId,
        'tdee': tdee, // บันทึก TDEE
        'user_eat': 0, // เริ่มต้น user_eat ที่ 0
        'timestamp': FieldValue.serverTimestamp(), // บันทึก timestamp
      });

      // เปลี่ยนหน้าไปยัง main page
      Navigator.pushReplacementNamed(context, '/main');
    }
  } catch (e) {
    setState(() {
      _isSaving = false;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Failed'),
        content: const Text('An error occurred. Please try again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}


  void _selectBirthdate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthdate) {
      setState(() {
        _birthdate = picked;
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
              GestureDetector(
                onTap: () => _selectBirthdate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Birthdate',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _birthdate == null
                        ? 'Select your birthdate'
                        : DateFormat.yMMMd().format(_birthdate!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                isExpanded: true, // แก้ไขให้ dropdown ขยายเต็มความกว้างที่มี
                hint: const Text('Select Gender'),
                items: const [
                  DropdownMenuItem(
                    value: 'Male',
                    child: Text('Male'),
                  ),
                  DropdownMenuItem(
                    value: 'Female',
                    child: Text('Female'),
                  ),
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
              DropdownButtonFormField<String>(
                value: _selectedActivityLevel,
                isExpanded: true, // แก้ไขให้ dropdown ขยายเต็มความกว้างที่มี
                hint: const Text('Select Activity Level'),
                items: const [
                  DropdownMenuItem(
                    value: 'Sedentary',
                    child: Text('Sedentary (little or no exercise)'),
                  ),
                  DropdownMenuItem(
                    value: 'Lightly active',
                    child: Text('Lightly active (1-3 days/week)'),
                  ),
                  DropdownMenuItem(
                    value: 'Moderately active',
                    child: Text('Moderately active (3-5 days/week)'),
                  ),
                  DropdownMenuItem(
                    value: 'Very active',
                    child: Text('Very active (6-7 days/week)'),
                  ),
                  DropdownMenuItem(
                    value: 'Super active',
                    child: Text('Super active (physical job or twice/day exercise)'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedActivityLevel = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Activity Level',
                  border: OutlineInputBorder(),
                ),
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
                      onPressed: _saveData,
                      child: const Text('Save'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
