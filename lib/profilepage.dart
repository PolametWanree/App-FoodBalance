import 'package:fl_chart/fl_chart.dart'; // สำหรับใช้กราฟ
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:foodbalance4/AdminScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ProfilePage(),
    );
  }
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? currentUser;
  Map<String, dynamic>? userData;
  File? _image;
  final picker = ImagePicker();
  TextEditingController _nameController = TextEditingController();
  bool isEditing = false; // สำหรับควบคุมโหมดการแก้ไข
  List<FlSpot> chartData = [];
  List<String> xLabels = [];
  double? tdeeValue; // เก็บค่า TDEE จาก Firestore

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _getDailyBackupData();
    _getTDEE(); // ดึงค่า TDEE จาก Firestore
  }

  // ดึงข้อมูลผู้ใช้ที่ล็อกอินอยู่จาก Firebase Auth และดึงข้อมูลจาก Firestore
  Future<void> _getCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUser = user;
      });

      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        userData = userDoc.data() as Map<String, dynamic>?;
        if (userData != null) {
          _nameController.text = userData!['name'] ?? '';
        }
      });
    }
  }

  // ดึงค่า TDEE จาก collection user_record
  Future<void> _getTDEE() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userRecord = await FirebaseFirestore.instance.collection('user_record').doc(user.uid).get();
      setState(() {
        tdeeValue = (userRecord['tdee'] ?? 0).toDouble();
      });
    }
  }

  // ฟังก์ชันเลือกและอัปเดตรูปโปรไฟล์
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      // TODO: อัปโหลดรูปไปยัง Firebase Storage และอัปเดต URL รูปใน Firestore
    }
  }

  // ฟังก์ชันสำหรับดึงข้อมูลจาก daily_backup สำหรับกราฟ
  Future<void> _getDailyBackupData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;
      QuerySnapshot backupSnapshots = await FirebaseFirestore.instance
          .collection('user_data')
          .doc(userId)
          .collection('daily_backup')
          .orderBy('backup_timestamp', descending: true)
          .limit(7)
          .get();

      List<FlSpot> spots = [];
      List<String> labels = [];
      int index = 0;

      for (var doc in backupSnapshots.docs) {
        var data = doc.data() as Map<String, dynamic>;
        double userEat = data['user_record']?['user_eat']?.toDouble() ?? 0;

        Timestamp timestamp = data['backup_timestamp'] ?? Timestamp.now();
        DateTime date = timestamp.toDate();
        String formattedDate = DateFormat('MM/dd').format(date);

        labels.add(formattedDate);
        spots.add(FlSpot(index.toDouble(), userEat));
        index++;
      }

      setState(() {
        chartData = spots.reversed.toList();
        xLabels = labels.reversed.toList();
      });
    }
  }

  // ฟังก์ชันบันทึกข้อมูลผู้ใช้เมื่อกดบันทึก
  Future<void> _saveProfile() async {
    if (currentUser != null && _nameController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
        'name': _nameController.text,
        // TODO: อัปเดต URL รูปโปรไฟล์ถ้ามี
      });
      setState(() {
        isEditing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: userData != null
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // กล่องรูปโปรไฟล์และข้อมูลผู้ใช้
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: isEditing ? _pickImage : null, // กดที่รูปเพื่อเปลี่ยนรูป
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundImage: _image != null
                                      ? FileImage(_image!)
                                      : AssetImage('assets/images/GG.png') as ImageProvider,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (isEditing)
                                          Expanded(
                                            child: TextField(
                                              controller: _nameController,
                                              decoration: InputDecoration(
                                                border: OutlineInputBorder(),
                                                labelText: 'Name',
                                              ),
                                            ),
                                          )
                                        else
                                          Row(
                                            children: [
                                              Text(
                                                userData!['name'] ?? 'No name',
                                                style: const TextStyle(
                                                    fontSize: 22, fontWeight: FontWeight.bold),
                                              ),
                                              // ปุ่มสำหรับแอดมินหลังชื่อผู้ใช้
                                              if (userData!['roll'] == 'admin')
                                                IconButton(
                                                  icon: const Icon(Icons.admin_panel_settings, color: Color.fromARGB(255, 13, 93, 49)),
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => AdminScreen(),
                                                      ),
                                                    );
                                                  },
                                                ),
                                            ],
                                          ),
                                        Transform.translate(
                                          offset: const Offset(0, 0),
                                          child: Text(
                                            currentUser!.email ?? 'No email',
                                            style: const TextStyle(
                                                fontSize: 14, color: Colors.grey),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Age: ${userData!['age'] ?? 'N/A'}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      'Gender: ${userData!['gender'] ?? 'N/A'}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      'Height: ${userData!['height'] ?? 'N/A'} cm',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      'Weight: ${userData!['weight'] ?? 'N/A'} kg',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      'Activity Level: ${userData!['activity_level'] ?? 'N/A'}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isEditing = !isEditing; // สลับโหมดแก้ไข
                                if (!isEditing) {
                                  _saveProfile(); // บันทึกข้อมูลเมื่อออกจากโหมดแก้ไข
                                }
                              });
                            },
                            child: Icon(
                              isEditing ? Icons.check : Icons.edit,
                              color: const Color.fromARGB(255, 13, 93, 49),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'พัฒนาการด้านการกิน ( Callories )',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    chartData.isNotEmpty
                        ? SizedBox(
                            height: 250,
                            child: LineChart(
                              LineChartData(
                                minY: 0,
                                maxY: 4000,
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: true,
                                  horizontalInterval: 500,
                                  verticalInterval: 1,
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey.withOpacity(0.3),
                                      strokeWidth: 1,
                                    );
                                  },
                                  getDrawingVerticalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey.withOpacity(0.3),
                                      strokeWidth: 1,
                                    );
                                  },
                                ),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 32,
                                      interval: 1,
                                      getTitlesWidget: (value, _) {
                                        if (value.toInt() < xLabels.length) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              xLabels[value.toInt()],
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          );
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                lineTouchData: LineTouchData(
                                  touchTooltipData: LineTouchTooltipData(
                                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                                      return touchedSpots.map((spot) {
                                        return LineTooltipItem(
                                          '${spot.y.toStringAsFixed(0)} แคลลอรี่',
                                          const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        );
                                      }).toList();
                                    },
                                  ),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: chartData,
                                    isCurved: true,
                                    barWidth: 4,
                                    color: const Color.fromARGB(255, 42, 84, 175),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color.fromARGB(255, 31, 160, 66).withOpacity(0.5),
                                          const Color.fromARGB(255, 52, 187, 240).withOpacity(0.5),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                ],
                                extraLinesData: ExtraLinesData(
                                  horizontalLines: [
                                    if (tdeeValue != null) // ตรวจสอบว่าค่า TDEE มีอยู่
                                      HorizontalLine(
                                        y: tdeeValue!,
                                        color: Colors.red,
                                        strokeWidth: 2,
                                        dashArray: [5, 5], // สร้างเส้นแบบประ
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : const Center(child: CircularProgressIndicator()),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Center(
                        child: ElevatedButton(
                          onPressed: () {
                            _logout(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 50),
                          ),
                          child: const Text('Log Out'),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _logout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();

                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false);

                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
  }
}
