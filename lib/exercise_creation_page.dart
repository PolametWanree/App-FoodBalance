import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class ExerciseCreationPage extends StatefulWidget {
  const ExerciseCreationPage({Key? key}) : super(key: key);

  @override
  _ExerciseCreationPageState createState() => _ExerciseCreationPageState();
}

class _ExerciseCreationPageState extends State<ExerciseCreationPage> {
  String _exerciseName = '';
  double _caloriesBurn = 100; // เริ่มต้นที่ 100 แคลอรี่
  double _duration = 30; // เริ่มต้นที่ 30 นาที
  String? _difficultyLevel;
  bool _isSaving = false;

  void _saveExercise() async {
    if (_exerciseName.isEmpty || _difficultyLevel == null) {
      // แสดงข้อความ error ถ้าข้อมูลไม่ครบ
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

    setState(() {
      _isSaving = true;
    });

    try {
      // สร้าง exercise_id
      String exerciseId = const Uuid().v4();

      // บันทึกข้อมูลท่าออกกำลังกายไปยัง Firestore
      await FirebaseFirestore.instance.collection('exercises').doc(exerciseId).set({
        'exercise_id': exerciseId,
        'exercise_name': _exerciseName,
        'calories_burn': _caloriesBurn,
        'duration': _duration,
        'difficulty_level': _difficultyLevel,
      });

      // รีเซ็ตค่า input หลังบันทึกสำเร็จ
      setState(() {
        _exerciseName = '';
        _caloriesBurn = 100;
        _duration = 30;
        _difficultyLevel = null;
        _isSaving = false;
      });

      // แสดงข้อความบันทึกสำเร็จ
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Exercise created successfully!'),
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
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      // แสดงข้อความ error ถ้าบันทึกล้มเหลว
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Exercise'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Exercise Name',
              ),
              onChanged: (value) {
                setState(() {
                  _exerciseName = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Text('Calories Burn: ${_caloriesBurn.toStringAsFixed(1)} kcal'),
            Slider(
              value: _caloriesBurn,
              min: 50,
              max: 1000,
              divisions: 95,
              onChanged: (value) {
                setState(() {
                  _caloriesBurn = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Text('Duration: ${_duration.toStringAsFixed(1)} minutes'),
            Slider(
              value: _duration,
              min: 5,
              max: 120,
              divisions: 115,
              onChanged: (value) {
                setState(() {
                  _duration = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _difficultyLevel,
              isExpanded: true,
              hint: const Text('Select Difficulty Level'),
              items: const [
                DropdownMenuItem(
                  value: 'Easy',
                  child: Text('Easy'),
                ),
                DropdownMenuItem(
                  value: 'Medium',
                  child: Text('Medium'),
                ),
                DropdownMenuItem(
                  value: 'Hard',
                  child: Text('Hard'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _difficultyLevel = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Difficulty Level',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _isSaving
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _saveExercise,
                    child: const Text('Save Exercise'),
                  ),
          ],
        ),
      ),
    );
  }
}
