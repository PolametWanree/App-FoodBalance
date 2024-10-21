import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart'; // ใช้สำหรับดึงข้อมูลจาก Firestore
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:geolocator/geolocator.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tflite.dart';
import 'dart:math';


class SpeechBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    Path path = Path();
    path.moveTo(20, 0); // เริ่มวาดที่จุดบนซ้าย
    path.lineTo(size.width - 20, 0); // เส้นตรงด้านบน
    path.quadraticBezierTo(size.width, 0, size.width, 20); // มุมโค้งบนขวา
    path.lineTo(size.width, size.height - 20); // เส้นตรงด้านขวา
    path.quadraticBezierTo(size.width, size.height, size.width - 20, size.height); // มุมโค้งล่างขวา
    path.lineTo(60, size.height); // เส้นตรงล่างซ้าย (หลบหางกล่อง)
    path.quadraticBezierTo(120, size.height + 30, 40, size.height); // หางกล่องข้อความโค้งและชี้ไปทางขวา
    path.lineTo(20, size.height); // กลับไปยังเส้นล่างซ้าย
    path.lineTo(20, size.height); // เส้นล่างซ้ายก่อนถึงมุมล่างซ้าย
    path.quadraticBezierTo(0, size.height, 0, size.height - 20); // มุมโค้งล่างซ้าย
    path.lineTo(0, 20); // เส้นตรงด้านซ้าย
    path.quadraticBezierTo(0, 0, 20, 0); // มุมโค้งบนซ้าย

    canvas.drawPath(path, paint); // วาดเส้นตาม path ที่กำหนด

    Paint borderPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class HalfCircleProgress extends CustomPainter {
  final double progress;

  HalfCircleProgress(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    Paint baseCircle = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..color = Colors.grey.shade300;

    Paint progressCircle = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = Colors.green;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width / 2, size.height * 0.7), radius: size.width / 2.5),
      3.14, // เริ่มที่ 180 องศา (ครึ่งวงกลม)
      3.14, // จบที่ 180 องศา (ครึ่งวงกลม)
      false,
      baseCircle,
    );

    // วาด progress (ความก้าวหน้า)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width / 2, size.height * 0.7), radius: size.width / 2.5),
      3.14, // เริ่มที่ 180 องศา
      3.14 * (progress / 100), // กำหนด progress ที่ต้องการ (จาก 0 - 100)
      false,
      progressCircle,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

// เพิ่ม FullCircleProgress ที่จะใช้ใน Container ใหม่
class FullCircleProgress extends CustomPainter {
  final double progress;
  final Color color;


  FullCircleProgress(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    Paint baseCircle = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = const Color.fromARGB(255, 255, 255, 255);

    Paint progressCircle = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = color;

    // วาดพื้นฐานวงกลม
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.width / 2.5),
      0, // เริ่มที่ 0 องศา
      6.28, // 360 องศา (วงกลมเต็ม)
      false,
      baseCircle,
    );

    // วาด progress วงกลม
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.width / 2.5),
      -1.57, // เริ่มที่ 270 องศา (ด้านบน)
      6.28 * (progress / 100), // คำนวณตาม progress ที่ส่งมา (0 - 100)
      false,
      progressCircle,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class MainMenu extends StatefulWidget {
  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  double progress1 = 50; // เริ่มต้น progress ที่ 50%
  double progress2 = 30; // Progress สำหรับวงที่ 2
  double progress3 = 70; // Progress สำหรับวงที่ 3
  int _steps = 0;
  double _previousMagnitude = 0;
  bool _isDriving = false;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<Position>? _positionSubscription;
  int _stepGoal = 10000; // กำหนดค่าเริ่มต้นของเป้าหมายการเดิน
  double _weight = 70; // กำหนดค่าเริ่มต้น
  double calculateCalories(int steps, double weight) {
  double strideLength = 0.5; // ความยาวก้าวขา (สมมติ)
  double distance = steps * strideLength / 1000; // ระยะทางที่เดิน (กิโลเมตร)
  double met = 3.8; // ค่า MET สำหรับการเดิน
  return met * weight * distance; // คำนวณแคลอรี่ที่เผาผลาญ
}


//นี่คือส่วนในการรีเซตค่า burned ทุกครั้งที่ขึ้นวันใหม่ เพื่อให้แอพมีความเป็น daily use มากขึ้น


   @override
  void initState() {
    super.initState();
    resetBurnedIfNewDay(context);
    resetDaily(context);
    resetConsumed(context);
      loadWeightFromFirestore(); // ดึงข้อมูลน้ำหนัก
      loadStepsFromPreferences();
    loadStepsFromFirestore();
    startTracking();
  }


   @override
  void dispose() {
    // ปิดการฟังข้อมูลเมื่อ widget ถูกทำลาย
    _accelerometerSubscription?.cancel();
    _positionSubscription?.cancel();
    FlutterBackground.disableBackgroundExecution(); // หยุด background service
    super.dispose();
  }

   void startTracking() {
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      trackSteps(event);
    });
    monitorSpeed();
  }

Future<void> saveCaloriesToFirestore(double caloriesBurned) async {
  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    String userId = currentUser.uid;
    DocumentReference stepRef = FirebaseFirestore.instance.collection('user_step').doc(userId);

    try {
      await stepRef.set({
        'calories_burned': caloriesBurned,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("Calories saved successfully!");
    } catch (e) {
      print("Failed to save calories: $e");
    }
  }
}

  Future<void> loadWeightFromFirestore() async {
  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    String userId = currentUser.uid;
    DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    try {
      DocumentSnapshot doc = await userRef.get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>?;
        setState(() {
          _weight = data?['weight']?.toDouble() ?? 70; // ดึงข้อมูลน้ำหนักจาก Firestore
        });
      }
    } catch (e) {
      print("Failed to load weight: $e");
    }
  }
}

  Future<void> loadStepsFromPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _steps = prefs.getInt('steps') ?? 0; // ตั้งค่า _steps จากค่าที่บันทึกไว้ในเครื่อง
    });
  }

  Future<void> saveStepsToPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('steps', _steps);
  }

  Future<void> startBackgroundService() async {
    bool hasPermissions = await FlutterBackground.hasPermissions;
    if (!hasPermissions) {
      // Request permission for background usage
      await FlutterBackground.initialize();
    }

    FlutterBackground.enableBackgroundExecution(); // Start background execution
  }

    void trackSteps(AccelerometerEvent event) {
  if (_isDriving) {
    // ไม่ต้องนับก้าวขณะขับรถ
    return;
  }

  double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
  if ((magnitude - _previousMagnitude).abs() > 3) {
    setState(() {
      _steps++;
    });
    saveStepsToFirestore(); // Save steps to Firestore
    saveStepsToPreferences(); // Save steps to SharedPreferences
    
    // คำนวณแคลอรี่ที่ถูกเผาผลาญ
    double caloriesBurned = calculateCalories(_steps, _weight);
    saveCaloriesToFirestore(caloriesBurned); // Save calories to Firestore
  }
  _previousMagnitude = magnitude;
}

   void monitorSpeed() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (!serviceEnabled || permission == LocationPermission.deniedForever) {
      return;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    _positionSubscription = Geolocator.getPositionStream().listen((Position position) {
      double speed = position.speed * 3.6; // Convert to km/h

      setState(() {
        _isDriving = speed > 20;
      });
    });
  }

Future<void> loadStepsFromFirestore() async {
  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    String userId = currentUser.uid;
    DocumentReference stepRef = FirebaseFirestore.instance.collection('user_step').doc(userId);

    try {
      DocumentSnapshot doc = await stepRef.get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>?;

        if (data != null && data.containsKey('timestamp')) {
          Timestamp lastUpdatedTimestamp = data['timestamp'];
          DateTime lastUpdatedDate = lastUpdatedTimestamp.toDate();
          DateTime now = DateTime.now();

          // ตรวจสอบว่าวันเปลี่ยนหรือยัง
          if (lastUpdatedDate.day != now.day || lastUpdatedDate.month != now.month || lastUpdatedDate.year != now.year) {
            // ถ้าเป็นวันใหม่ ให้รีเซ็ตค่า steps เป็น 0
            setState(() {
              _steps = 0;
            });
            saveStepsToFirestore(); // บันทึกค่า steps ที่รีเซ็ตแล้วลง Firestore
          } else {
            setState(() {
              _steps = data['steps'] ?? 0; // ตั้งค่า _steps จากข้อมูลที่บันทึกใน Firestore
            });
          }
        } else {
          setState(() {
            _steps = data?['steps'] ?? 0; // ตั้งค่า _steps จากข้อมูลที่บันทึกใน Firestore
          });
        }
        saveStepsToPreferences(); // บันทึกลงใน SharedPreferences ด้วย
      }
    } catch (e) {
      print("Failed to load steps: $e");
    }
  }
}



  Future<void> saveStepsToFirestore() async {
  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    String userId = currentUser.uid;
    DocumentReference stepRef = FirebaseFirestore.instance.collection('user_step').doc(userId);

    try {
      // ดึงข้อมูลจาก Firestore เพื่อเช็ควันที่ล่าสุดที่บันทึก
      DocumentSnapshot doc = await stepRef.get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>?;

        if (data != null && data.containsKey('timestamp')) {
          Timestamp lastUpdatedTimestamp = data['timestamp'];
          DateTime lastUpdatedDate = lastUpdatedTimestamp.toDate();
          DateTime now = DateTime.now();

          // ตรวจสอบว่าวันเปลี่ยนหรือยัง
          if (lastUpdatedDate.day != now.day || lastUpdatedDate.month != now.month || lastUpdatedDate.year != now.year) {
            // ถ้าเป็นวันใหม่ ให้รีเซ็ตจำนวนก้าวเป็น 0
            setState(() {
              _steps = 0;
            });
          }
        }
      }

      // บันทึกจำนวนก้าวใหม่ลง Firestore ไม่ว่าจำนวนก้าวจะถูกรีเซ็ตหรือไม่ก็ตาม
      await stepRef.set({
        'steps': _steps,
        'timestamp': FieldValue.serverTimestamp(), // อัปเดตวันที่ล่าสุด
      }, SetOptions(merge: true));

      print("Steps saved successfully!");
    } catch (e) {
      print("Failed to save steps: $e");
    }
  }
}




 Future<void> resetBurnedIfNewDay(BuildContext context) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        String userId = currentUser.uid;

        DocumentReference userBurnedRef =
            FirebaseFirestore.instance.collection('user_burned').doc(userId);

        DocumentSnapshot doc = await userBurnedRef.get();

        if (doc.exists) {
          Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

          if (data != null && data.containsKey('lastUpdated')) {
            Timestamp lastUpdatedTimestamp = data['lastUpdated'];
            DateTime lastUpdatedDate = lastUpdatedTimestamp.toDate();

            DateTime now = DateTime.now();

            // ตรวจสอบว่าวันเปลี่ยนหรือยัง
            if (lastUpdatedDate.day != now.day || lastUpdatedDate.month != now.month || lastUpdatedDate.year != now.year) {
              // ถ้าเป็นวันใหม่ ให้รีเซ็ตค่า burned เป็น 0
              await userBurnedRef.set({
                'burned': 0, // รีเซ็ต burned เป็น 0
                'lastUpdated': Timestamp.now(), // อัปเดต lastUpdated เป็นเวลาปัจจุบัน
              }, SetOptions(merge: true));
  
            }
          }
        }
      }
    } catch (e) {
    }
  }

Future<void> resetDaily(BuildContext context) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        String userId = currentUser.uid;

        DocumentReference userBurnedRef =
            FirebaseFirestore.instance.collection('user_record').doc(userId);

        DocumentSnapshot doc = await userBurnedRef.get();

        if (doc.exists) {
          Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

          if (data != null && data.containsKey('timestamp')) {
            Timestamp lastUpdatedTimestamp = data['timestamp'];
            DateTime lastUpdatedDate = lastUpdatedTimestamp.toDate();

            DateTime now = DateTime.now();

            // ตรวจสอบว่าวันเปลี่ยนหรือยัง
            if (lastUpdatedDate.day != now.day || lastUpdatedDate.month != now.month || lastUpdatedDate.year != now.year) {
              // ถ้าเป็นวันใหม่ ให้รีเซ็ตค่า burned เป็น 0
              await userBurnedRef.set({
                'user_eat': 0, // รีเซ็ต burned เป็น 0
                'carbohydrate_eat': 0,
                'protein_eat': 0,
                'sugar_eat': 0,
                'timestamp': Timestamp.now(), // อัปเดต lastUpdated เป็นเวลาปัจจุบัน
              }, SetOptions(merge: true));
  
            }
          }
        }
      }
    } catch (e) {
    }
  }


Future<void> resetConsumed(BuildContext context) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        String userId = currentUser.uid;

        DocumentReference userBurnedRef =
            FirebaseFirestore.instance.collection('user_consumed').doc(userId);

        DocumentSnapshot doc = await userBurnedRef.get();

        if (doc.exists) {
          Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

          if (data != null && data.containsKey('lastUpdated')) {
            Timestamp lastUpdatedTimestamp = data['lastUpdated'];
            DateTime lastUpdatedDate = lastUpdatedTimestamp.toDate();

            DateTime now = DateTime.now();

            // ตรวจสอบว่าวันเปลี่ยนหรือยัง
            if (lastUpdatedDate.day != now.day || lastUpdatedDate.month != now.month || lastUpdatedDate.year != now.year) {
              // ถ้าเป็นวันใหม่ ให้รีเซ็ตค่า burned เป็น 0
              await userBurnedRef.set({
                'count': 0, // รีเซ็ต burned เป็น 0
                'timestamp': Timestamp.now(), // อัปเดต lastUpdated เป็นเวลาปัจจุบัน
              }, SetOptions(merge: true));
  
            }
          }
        }
      }
    } catch (e) {
    }
  }


void _showEditStepGoalDialog(BuildContext context) {
  TextEditingController goalController = TextEditingController(text: _stepGoal.toString());

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Edit Step Goal'),
        content: TextField(
          controller: goalController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter your new step goal',
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Save'),
            onPressed: () {
              setState(() {
                _stepGoal = int.tryParse(goalController.text) ?? 10000; // อัปเดตค่าเป้าหมาย
              });
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}


  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54, // พื้นหลังแบบโปร่งแสง
      builder: (BuildContext context) {
        return Stack(
          children: [
            Transform.translate(
              offset: Offset(0, -70), // ปรับตำแหน่งของ Dialog
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: Colors.transparent, // กำหนดพื้นหลังเป็นโปร่งใส
                child: Container(
                  width: 300,
                  height: 200,
                  child: CustomPaint(
                    painter: SpeechBubblePainter(),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "ทำดีมาก!",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text("คุณกินอาหารถึงแคลอรี่ตามที่กำหนดไว้แล้ว!"),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(110, 210), // ปรับตำแหน่งของรูปภาพ
              child: Image.asset(
                'assets/images/3.png',
                height: 550,
                width: 230,
              ),
            ),
          ],
        );
      },
    );
  }

  void _decreaseProgress() {
    setState(() {
      if (progress1 > 0) {
        progress1 -= 10; // ลด progress ทีละ 10%
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // รับ userId จาก Firebase Authentication
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;
  double progress = (_steps / _stepGoal).clamp(0.0, 1.0); // คำนวณ progress เป็นเปอร์เซ็นต์



    return Scaffold(
      backgroundColor: Color.fromARGB(255, 241, 255, 244),
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                SizedBox(width: 5),
                Text('0'),
              ],
            ),
            Row(
              children: [
                Icon(Icons.local_fire_department, color: Colors.grey),
                SizedBox(width: 5),
                Text('0'),
              ],
            ),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.green),
                SizedBox(width: 5),
                Text('0h'),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Container(
              /////////////////ปรับ กล่องขาวๆ decoration: BoxDecoration ให้เป็นกล่องสีขาวๆ/////////////////////
              width: 350,
              height: 150,
                decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                  Colors.white,
                  Colors.grey.shade200,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(31, 0, 0, 0),
                    blurRadius: 5,
                    spreadRadius: 5,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              padding: EdgeInsets.all(50),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 50,
                        width: 165,
                        child: StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('user_record') // ตรวจสอบว่าชื่อ collection ถูกต้อง
                              .doc(FirebaseAuth.instance.currentUser?.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              var data = snapshot.data!.data() as Map<String, dynamic>?;
                              var userEat = data?['user_eat'] ?? 0;
                              var tdee = data?['tdee'] ?? 2000; // ตรวจสอบค่า tdee ของผู้ใช้

                              // คำนวณเปอร์เซ็นต์ความคืบหน้า
                              double progress = userEat >= tdee ? 100 : (userEat / tdee) * 100;

                              return CustomPaint(
                                painter: HalfCircleProgress(progress),
                              );
                            } else {
                              return Center(child: CircularProgressIndicator());
                            }
                          },
                        ),
                      ),
                      // ใช้ StreamBuilder เพื่อดึงข้อมูล TDEE ของผู้ใช้
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('user_record')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            var data = snapshot.data!.data() as Map<String, dynamic>?;
                            var tdee = data?['tdee'] ?? 0;
                            var userEat = data?['user_eat'] ?? 0;
                            var kcalRemaining = userEat >= tdee ? userEat - tdee : tdee - userEat; // คำนวณค่าคงเหลือ

                            return Column(
                              children: [
                                Transform.translate(
                                  offset: Offset(0, -5),
                                  child: Text(
                                    '$kcalRemaining',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Transform.translate(
                                  offset: Offset(0, -2),
                                  child: Text(
                                    userEat >= tdee ? 'kcal to burn' : 'kcal remaining',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                Transform.translate(
                                  offset: Offset(0, -20),
                                  child: Text(
                                    'Loading...',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Transform.translate(
                                  offset: Offset(0, -2),
                                  child: Text(
                                    'kcal remaining',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                      Transform.translate(
                        offset: Offset(-120, 0),
                        child: Column(
                          children: [
                            // ใช้ StreamBuilder เพื่อแสดงข้อมูล consumed
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('user_consumed') // ตรวจสอบว่าใช้ collection ชื่อนี้จริง ๆ
                                  .doc(FirebaseAuth.instance.currentUser?.uid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  var data = snapshot.data!.data() as Map<String, dynamic>?;
                                  var consumed = data?['count'] ?? 0; // ตรวจสอบให้แน่ใจว่า 'count' คือฟิลด์ที่เก็บค่า consumed
                                  return Text(
                                    '$consumed',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  );
                                } else {
                                  return Text(
                                    '0', // แสดงค่าเริ่มต้นเป็น 0 ถ้าไม่สามารถดึงข้อมูลได้
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  );
                                }
                              },
                            ),
                            Text(
                              'Consumed',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(120, 0),
                        child: Column(
                          children: [
                            // ใช้ StreamBuilder เพื่อแสดงข้อมูล consumed
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('user_burned') // ตรวจสอบว่าใช้ collection ชื่อนี้จริง ๆ
                                  .doc(FirebaseAuth.instance.currentUser?.uid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  var data = snapshot.data!.data() as Map<String, dynamic>?;
                                  var burned = data?['burned'] ?? 0; // ตรวจสอบให้แน่ใจว่า 'burned' คือฟิลด์ที่เก็บค่า burned
                                  return Text(
                                    '$burned',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  );
                                } else {
                                  return Text(
                                    '0', // แสดงค่าเริ่มต้นเป็น 0 ถ้าไม่สามารถดึงข้อมูลได้
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  );
                                }
                              },
                            ),
                            Text(
                              'Burned',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
            child: Container(
              // Container ที่เพิ่มกราฟวงกลม 3 วง
              width: 350,
              height: 130, // เพิ่มความสูงให้เหมาะกับกราฟวงกลม
                decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                  const Color.fromARGB(255, 13, 93, 49),
                const Color.fromARGB(255, 152, 234, 212),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                color: const Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(12),
                
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('user_record')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        var data = snapshot.data!.data() as Map<String, dynamic>?;

                        // การดึงค่าของ carbohydrate และ carbohydrate_eat
                        var carb = data?['carbohydrate'] ?? 0;
                        var carbEat = data?['carbohydrate_eat'] ?? 0;

                        // คำนวณเปอร์เซ็นต์ความคืบหน้าสำหรับ carbohydrate
                        double progressCarb = carbEat >= carb ? 100 : (carbEat / carb) * 100;

                        return SizedBox(
                          height: 80,
                          width: 80,
                            child: CustomPaint(
                              painter: FullCircleProgress(progressCarb, const Color.fromARGB(255, 255, 178, 46)), // วงกลมที่ 1
                              child: Center(
                                child: Text(
                                  '🍞', // แสดงเปอร์เซ็นต์ความคืบหน้าในกราฟวงกลม
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black, // เปลี่ยนสีตัวอักษรตามที่ต้องการ
                                    shadows: [
                                      Shadow(
                                        blurRadius: 10.0,
                                        color: Colors.black.withOpacity(0.5),
                                        offset: Offset(2.0, 2.0),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                      } else {
                        return Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('user_record')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        var data = snapshot.data!.data() as Map<String, dynamic>?;

                        // การดึงค่าของ protein และ protein_eat
                        var protein = data?['protein'] ?? 0;
                        var proteinEat = data?['protein_eat'] ?? 0;

                        // คำนวณเปอร์เซ็นต์ความคืบหน้าสำหรับ protein
                        double progressProtein = proteinEat >= protein ? 100 : (proteinEat / protein) * 100;

                        return SizedBox(
                          height: 80,
                          width: 80,
                          child: CustomPaint(
                              painter: FullCircleProgress(progressProtein,Colors.red), // วงกลมที่ 1
                              child: Center(
                                child: Text(
                                  '🥩', // แสดงเปอร์เซ็นต์ความคืบหน้าในกราฟวงกลม
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black, // เปลี่ยนสีตัวอักษรตามที่ต้องการ
                                    shadows: [
                                      Shadow(
                                        blurRadius: 10.0,
                                        color: Colors.black.withOpacity(0.5),
                                        offset: Offset(2.0, 2.0),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                      } else {
                        return Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('user_record')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        var data = snapshot.data!.data() as Map<String, dynamic>?;

                        // การดึงค่าของ sugar และ sugar_eat
                        var sugar = data?['sugar'] ?? 0;
                        var sugarEat = data?['sugar_eat'] ?? 0;

                        // คำนวณเปอร์เซ็นต์ความคืบหน้าสำหรับ sugar
                        double progressSugar = sugarEat >= sugar ? 100 : (sugarEat / sugar) * 100;

                        return SizedBox(
                          height: 80,
                          width: 80,
                          child: CustomPaint(
                              painter: FullCircleProgress(progressSugar,const Color.fromARGB(255, 138, 77, 55)), // วงกลมที่ 1
                              child: Center(
                                child: Text(
                                  '🍫', // แสดงเปอร์เซ็นต์ความคืบหน้าในกราฟวงกลม
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black, // เปลี่ยนสีตัวอักษรตามที่ต้องการ
                                    shadows: [
                                      Shadow(
                                        blurRadius: 10.0,
                                        color: Colors.black.withOpacity(0.5),
                                        offset: Offset(2.0, 2.0),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                      } else {
                        return Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
          child: Container(
            width: 350,
            height: 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(
              colors: [
                // const Color.fromARGB(255, 54, 214, 150),x
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
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Row(
      children: [
        Icon(Icons.directions_walk, color: Colors.white),
        SizedBox(width: 5), // ระยะห่างระหว่างไอคอนและข้อความ
        Text(
          'Steps Today',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    ),
    IconButton(
      icon: Icon(Icons.edit, color: const Color.fromARGB(255, 255, 255, 255)),
      iconSize: 20,
      onPressed: () {
        _showEditStepGoalDialog(context); // เปิด Dialog เพื่อแก้ไขเป้าหมาย
      },
    ),
  ],
),

                SizedBox(height: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ' $_steps ก้าว',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'เป้าหมาย: $_stepGoal ก้าว',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: const Color.fromARGB(255, 42, 43, 42)),
                    ),
                  ],
                ),
Stack(
  children: [
    ClipRRect(
      borderRadius: BorderRadius.circular(20), // กำหนดมุมโค้งของ Progress Bar
      child: LinearProgressIndicator(
        value: progress, // ค่า progress ที่คำนวณได้
        minHeight: 18, // ความหนาของ Progress Bar
        backgroundColor: const Color.fromARGB(255, 255, 255, 255), // สีพื้นหลังของ Progress Bar
        color: const Color(0xFF31C38B), // สีของ Progress Bar
      ),
    ),
    Positioned(
      left: progress * 338, // คำนวณตำแหน่งไอคอนตามค่า progress
      top: 2, // ปรับตำแหน่งแนวตั้ง
      child: Icon(
        TeenyIcons.heart, // ไอคอนรูปวิ่ง
        color: const Color.fromARGB(255, 32, 93, 69), // สีของไอคอน
        size: 15, // ขนาดของไอคอน
      ),
    ),
    
  ],
),
SizedBox(height: 5),
// การแสดงแคลอรี่ที่เผาผลาญ
StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('user_step')
      .doc(FirebaseAuth.instance.currentUser?.uid)
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      var data = snapshot.data!.data() as Map<String, dynamic>?;
      double caloriesBurned = data?['calories_burned'] ?? 0.0;

      return Align(
        alignment: Alignment.centerLeft, // จัดตำแหน่งไปทางซ้าย
        child: Container(
          padding: EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 255, 255), // Fill color
            borderRadius: BorderRadius.circular(25),
          ),
            child: Row(
            children: [
              Icon(FontAwesome.fire_solid, color: Colors.red, size: 15), // Add FontAwesome icon
              SizedBox(width: 5), // Add some spacing between the icon and the text
              Text(
            ' ${caloriesBurned.toStringAsFixed(0)} แคลลอรี่',
            style: TextStyle(
              fontSize: 15,
              color: const Color.fromARGB(255, 0, 0, 0),
            ),
          ),
            ],
        ),
         
      ),
      );
    } else {
      return Align(
        alignment: Alignment.centerLeft, // จัดตำแหน่งไปทางซ้าย
        child: Text(
          'Calories Burned: 0.0 kcal',
          style: TextStyle(fontSize: 18, color: const Color.fromARGB(255, 212, 41, 41)),
        ),
      );
    }
  },
),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }
  
}



void main() {
  runApp(MaterialApp(home: MainMenu()));
}
