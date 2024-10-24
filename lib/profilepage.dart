import 'package:fl_chart/fl_chart.dart'; // สำหรับใช้กราฟ
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:foodbalance4/AdminScreen.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'dart:math';

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
  TextEditingController _carbohydrateController = TextEditingController();
  TextEditingController _proteinController = TextEditingController();
  TextEditingController _sugarController = TextEditingController();
  TextEditingController _tdeeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _getDailyBackupData();
    _getTDEE(); // ดึงค่า TDEE จาก Firestore
    _getGoalDataFromFirestore(); // ดึงข้อมูลเป้าหมายจาก Firestore
  }

  Future<void> _getGoalDataFromFirestore() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userRecord = await FirebaseFirestore.instance
          .collection('user_record')
          .doc(user.uid)
          .get();
      setState(() {
        // กำหนดค่าให้ TextEditingControllers
        _carbohydrateController.text = (userRecord['carbohydrate'] ?? 0).toString();
        _proteinController.text = (userRecord['protein'] ?? 0).toString();
        _sugarController.text = (userRecord['sugar'] ?? 0).toString();
        _tdeeController.text = (userRecord['tdee'] ?? 0).toString();
      });
    }
  }

  Future<void> _saveGoalDataToFirestore() async {
    if (currentUser != null) {
      await FirebaseFirestore.instance
          .collection('user_record')
          .doc(currentUser!.uid)
          .update({
        'carbohydrate': double.parse(_carbohydrateController.text),
        'protein': double.parse(_proteinController.text),
        'sugar': double.parse(_sugarController.text),
        'tdee': double.parse(_tdeeController.text),
      });
    }
  }

  Future<void> _showEditDialog(
      BuildContext context, String label, TextEditingController controller) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit $label'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: label,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
  onPressed: () async {
    await _saveGoalDataToFirestore(); // Save the updated value to Firestore
    Navigator.of(context).pop();
  },
  child: Text('Save'),
),

          ],
        );
      },
    );
  }

  Widget _buildGoalEditField(BuildContext context,
    {required IconData icon,
    required String label,
    required TextEditingController controller}) {
  return GestureDetector(
    onTap: () {
      _showEditDialog(context, label, controller); // แสดง Dialog เมื่อกดที่ไอคอน
    },
    child: AbsorbPointer(
      child: TextField(
        controller: controller,
        readOnly: true, // ทำให้เป็น readOnly เพื่อให้กดไอคอนเพื่อแก้ไขแทน
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color.fromARGB(255, 255, 255, 255)), // ตั้งค่าสีของไอคอน
          labelText: label,
          labelStyle: TextStyle(color: const Color.fromARGB(255, 255, 255, 255)), // ตั้งค่าสีของ label
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: const Color.fromARGB(255, 255, 255, 255), // ตั้งค่าสีของขอบเมื่อไม่ได้เลือก
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.orange, // ตั้งค่าสีของขอบเมื่อเลือก TextField
            ),
          ),
        ),
        style: TextStyle(
          color: const Color.fromARGB(255, 255, 255, 255), // ตั้งค่าสีของข้อความ
        ),
      ),
    ),
  );
}


  // ดึงข้อมูลผู้ใช้ที่ล็อกอินอยู่จาก Firebase Auth และดึงข้อมูลจาก Firestore
  Future<void> _getCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUser = user;
      });

      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
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
      DocumentSnapshot userRecord = await FirebaseFirestore.instance
          .collection('user_record')
          .doc(user.uid)
          .get();
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
                                                  icon: const Icon(Icons.admin_panel_settings,
                                                      color: Color.fromARGB(255, 13, 93, 49)),
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
                    // คอนเทนเนอร์สำหรับ Edit Your Goal
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      child: Container(
                        width: 350,
                        height: 210,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color.fromARGB(255, 13, 93, 49),
                              const Color.fromARGB(255, 152, 234, 212),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ส่วนการแก้ไขเป้าหมาย
                            Container(
                              padding: const EdgeInsets.all(0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.edit, color: Colors.white, size: 18),
                                          SizedBox(width: 5),
                                          Text(
                                            'Edit Your Goal',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: _buildGoalEditField(
                                          context,
                                          icon: FontAwesome.bowl_rice_solid,
                                          label: "Carb",
                                            controller: _carbohydrateController, // ใช้ controller ที่เก็บค่า carb
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Expanded(
                                        child: _buildGoalEditField(
                                          context,
                                          icon: FontAwesome.drumstick_bite_solid,
                                          label: "Protein",
                                          controller: _proteinController, // ใช้ controller ที่เก็บค่า protein
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: _buildGoalEditField(
                                          context,
                                          icon: FontAwesome.candy_cane_solid,
                                          label: "Sugar",
                                          controller: _sugarController, // ใช้ controller ที่เก็บค่า sugar
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Expanded(
                                        child: _buildGoalEditField(
                                          context,
                                          icon: FontAwesome.fire_flame_curved_solid,
                                          label: "TDEE",
                                          controller: _tdeeController, // ใช้ controller ที่เก็บค่า tdee
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // กราฟแสดงข้อมูลการกิน
                    const SizedBox(height: 30),
                    const Text(
                      'พัฒนาการด้านการกิน ( Callories )',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
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
                      child: chartData.isNotEmpty
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
                                          color: const Color.fromARGB(255, 68, 129, 57),
                                          strokeWidth: 2,
                                          dashArray: [5, 5], // สร้างเส้นแบบประ
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : const Center(child: CircularProgressIndicator()),
                    ),
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
                          child: const Text(
                            'Log Out',
                            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Center(
                        child: ElevatedButton(
                          onPressed: () {
                            _showDeleteAccountDialog(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 50),
                            backgroundColor: const Color.fromARGB(255, 255, 255, 255), // สีแดงสำหรับปุ่มลบบัญชี
                          ),
                          child: const Text(
                            'Delete Account',
                            style: TextStyle(color: Color.fromARGB(255, 255, 0, 0)),
                          ),
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

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text('Are you sure you want to delete your account? This action is irreversible.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _deleteAccount(context);
                Navigator.of(context).pop();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

// ฟังก์ชันสำหรับดึงข้อมูลจาก daily_backup สำหรับกราฟ
Future<void> _getDailyBackupData() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    String userId = user.uid;

    // ดึงข้อมูลตามวัน
    QuerySnapshot backupSnapshots = await FirebaseFirestore.instance
        .collection('user_data')
        .doc(userId)
        .collection('daily_backup')
        .orderBy('backup_timestamp', descending: true)
        .get();

    Map<String, double> dailyMax = {}; // เก็บค่า TDEE สูงสุดในแต่ละวัน
    List<String> labels = [];

    for (var doc in backupSnapshots.docs) {
      var data = doc.data() as Map<String, dynamic>;
      double userEat = data['user_record']?['user_eat']?.toDouble() ?? 0;

      Timestamp timestamp = data['backup_timestamp'] ?? Timestamp.now();
      DateTime date = timestamp.toDate();
      String formattedDate = DateFormat('MM/dd').format(date);

      // ตรวจสอบค่า TDEE สูงสุดในวันนั้น
      if (dailyMax.containsKey(formattedDate)) {
        dailyMax[formattedDate] = max(dailyMax[formattedDate]!, userEat);
      } else {
        dailyMax[formattedDate] = userEat;
      }
    }

    // สร้างจุดข้อมูลสำหรับกราฟจาก dailyMax
    int index = 0;
    dailyMax.forEach((date, value) {
      labels.add(date);
      chartData.add(FlSpot(index.toDouble(), value));
      index++;
    });

    setState(() {
      chartData = chartData.reversed.toList(); // เรียงข้อมูลใหม่เพื่อให้แสดงล่าสุดไปเก่าที่สุด
      xLabels = labels.reversed.toList(); // เรียงวันที่ใหม่
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


  Future<void> _deleteAccount(BuildContext context) async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {
        // ลบข้อมูลผู้ใช้จาก Firestore
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).delete();
        await FirebaseFirestore.instance.collection('user_record').doc(currentUser.uid).delete();

        // ลบผู้ใช้จาก Firebase Authentication
        await currentUser.delete();

        // ลบข้อมูลใน SharedPreferences ถ้ามี
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // ออกจากระบบและนำทางกลับไปที่หน้าล็อกอิน
        Navigator.pushReplacementNamed(context, '/login');
      } catch (e) {
        print('Failed to delete account: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: Unable to delete account. Please try again.'),
        ));
      }
    }
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
