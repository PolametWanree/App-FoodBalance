import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // ใช้สำหรับจัดการวันที่

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
  String? _selectedGender; // ตัวแปรสำหรับเก็บเพศ
  bool _isSaving = false;

  void _saveData() async {
    if (_birthdate == null || _selectedGender == null) {
      // Show an error if birthdate or gender is not selected
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Incomplete Information'),
          content: const Text('Please select your birthdate and gender.'),
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
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _name,
          'height': _height,
          'weight': _weight,
          'birthdate': _birthdate, // Save birthdate
          'age': age, // Save calculated age
          'gender': _selectedGender, // Save gender
        });

        // Navigate to the main page after saving
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
      body: Padding(
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
            // Dropdown สำหรับเลือกเพศ
            DropdownButtonFormField<String>(
              value: _selectedGender,
              hint: const Text('Select Gender'),
              items: [
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
    );
  }
}
