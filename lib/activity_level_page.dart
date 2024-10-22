import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityLevelPage extends StatefulWidget {
  final String name;
  final double height;
  final double weight;
  final DateTime birthdate;
  final String gender;

  const ActivityLevelPage({
    Key? key,
    required this.name,
    required this.height,
    required this.weight,
    required this.birthdate,
    required this.gender,
  }) : super(key: key);

  @override
  _ActivityLevelPageState createState() => _ActivityLevelPageState();
}

class _ActivityLevelPageState extends State<ActivityLevelPage> {
  int _selectedActivityLevel = 1; // กำหนดค่าเริ่มต้นเป็น 1
  bool _isSaving = false;

  // ฟังก์ชันเลือกไอคอนไฟตามระดับที่เลือก
  IconData _getFireIcon(int level) {
    return Icons.whatshot; // ไอคอนไฟ
  }

  // ฟังก์ชันเลือกสีของไอคอนตามระดับที่เลือก
  Color _getFireColor(int level) {
    switch (level) {
      case 1:
        return Colors.blue; // ไฟสีฟ้า
      case 2:
        return Colors.green; // ไฟสีเขียว
      case 3:
        return Colors.yellow; // ไฟสีเหลือง
      case 4:
        return Colors.orange; // ไฟสีส้ม
      case 5:
        return Colors.red; // ไฟสีแดง
      default:
        return Colors.blue;
    }
  }

  // ฟังก์ชันแปลงตัวเลขระดับกิจกรรมเป็นคำพูดและความถี่การออกกำลังกาย
  String _getActivityLevelText(int level) {
    switch (level) {
      case 1:
        return 'Sedentary: Little or no exercise';
      case 2:
        return 'Lightly active: 1-3 times/week';
      case 3:
        return 'Moderately active: 3-5 times/week';
      case 4:
        return 'Very active: 6-7 times/week';
      case 5:
        return 'Super active: Physical job or twice/day exercise';
      default:
        return 'Sedentary: Little or no exercise';
    }
  }

  // ฟังก์ชันคำนวณ BMR
  double _calculateBMR() {
    int age = DateTime.now().year - widget.birthdate.year;
    if (DateTime.now().isBefore(DateTime(DateTime.now().year, widget.birthdate.month, widget.birthdate.day))) {
      age--;
    }

    if (widget.gender == 'Male') {
      return 88.362 + (13.397 * widget.weight) + (4.799 * widget.height) - (5.677 * age);
    } else {
      return 447.593 + (9.247 * widget.weight) + (3.098 * widget.height) - (4.330 * age);
    }
  }

  // ฟังก์ชันคำนวณ TDEE
  double _calculateTDEE(double bmr) {
    switch (_selectedActivityLevel) {
      case 1:
        return bmr * 1.2;
      case 2:
        return bmr * 1.375;
      case 3:
        return bmr * 1.55;
      case 4:
        return bmr * 1.725;
      case 5:
        return bmr * 1.9;
      default:
        return bmr * 1.2;
    }
  }

  // ฟังก์ชันคำนวณโปรตีนที่ต้องการต่อวัน
  double _calculateProtein() {
    return 0.8 * widget.weight;
  }

  // ฟังก์ชันคำนวณคาร์โบไฮเดรตที่ต้องการต่อวัน
  double _calculateCarbohydrate(double tdee) {
    return (tdee * 0.55) / 4; // 55% ของ TDEE แบ่งเป็นกรัม (1 กรัมคาร์โบไฮเดรตให้พลังงาน 4 แคลอรี่)
  }

  // ฟังก์ชันคำนวณน้ำตาลที่แนะนำต่อวัน (แนะนำจาก WHO)
  double _calculateSugar() {
    return 25; // 25 กรัมต่อวันเป็นค่าที่แนะนำโดย WHO
  }

  void _saveData() async {
    if (_selectedActivityLevel == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Please select your activity level'),
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
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // คำนวณค่า BMR, TDEE, โปรตีน, น้ำตาล, และคาร์โบไฮเดรต
        double bmr = _calculateBMR();
        int tdee = _calculateTDEE(bmr).round(); // ทำให้ TDEE เป็นจำนวนเต็ม
        double protein = _calculateProtein();
        double sugar = _calculateSugar();
        double carbohydrate = _calculateCarbohydrate(tdee.toDouble());

        // แปลงระดับกิจกรรมจากตัวเลขเป็นคำพูด
        String activityLevelText = _getActivityLevelText(_selectedActivityLevel);

        // บันทึกข้อมูลใหม่ลงใน collection 'users'
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': widget.name,
          'height': widget.height,
          'weight': widget.weight,
          'birthdate': widget.birthdate,
          'gender': widget.gender,
          'activity_level': activityLevelText, // บันทึกระดับกิจกรรมเป็นคำพูด
        }, SetOptions(merge: true)); // ใช้ merge เพื่อไม่ลบข้อมูลเดิม

        // บันทึกข้อมูลใหม่และรวมกับข้อมูลเดิมลงใน 'user_record'
        await FirebaseFirestore.instance.collection('user_record').doc(user.uid).set({
          'user_id': user.uid,
          'tdee': tdee, // TDEE เป็นจำนวนเต็ม
          'protein': protein,
          'sugar': sugar,
          'carbohydrate': carbohydrate.round(),
          'user_eat': 0,
          'protein_eat': 0,
          'sugar_eat': 0,
          'carbohydrate_eat': 0,
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)); // ใช้ merge เพื่อไม่ลบข้อมูลเดิม

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
        title: const Text('Activity Level'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ไอคอนแสดงระดับไฟตาม Activity Level ที่เลือก
            Icon(
              _getFireIcon(_selectedActivityLevel),
              size: 100,
              color: _getFireColor(_selectedActivityLevel),
            ),
            const SizedBox(height: 16),
            // ข้อความแสดงความเข้มข้นของการออกกำลังกายและจำนวนครั้งต่อสัปดาห์
            Text(
              _getActivityLevelText(_selectedActivityLevel),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Slider สำหรับเลือก Activity Level
            Slider(
              value: _selectedActivityLevel.toDouble(), // ทำให้เป็น double เพื่อใช้กับ Slider
              min: 1,
              max: 5,
              divisions: 4,
              label: _selectedActivityLevel.toString(),
              onChanged: (double value) {
                setState(() {
                  _selectedActivityLevel = value.toInt(); // แปลงกลับเป็น int
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
