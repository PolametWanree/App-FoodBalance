import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
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
  int _favoritesCount = 0;
  int _userEat = 0;

  double calculateCalories(int steps, double weight) {
    double strideLength = 0.5; // ความยาวก้าวขา (สมมติ)
    double distance = steps * strideLength / 1000; // ระยะทางที่เดิน (กิโลเมตร)
    double met = 3.8; // ค่า MET สำหรับการเดิน
    return met * weight * distance; // คำนวณแคลอรี่ที่เผาผลาญ
  }

  @override
void initState() {
  super.initState();
  loadStepGoalFromPreferences(); // โหลดค่าเป้าหมายจาก SharedPreferences
  resetBurnedIfNewDay(context);
  resetDaily(context);
  resetConsumed(context);
  loadWeightFromFirestore(); // ดึงข้อมูลน้ำหนัก
  loadStepsFromPreferences();
  loadStepsFromFirestore();
  startTracking();
  loadStepsFromFirestore();
  loadFavoritesCount();
  loadUserEat();
}

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _positionSubscription?.cancel();
    FlutterBackground.disableBackgroundExecution(); // หยุด background service
    super.dispose();
  }

  void _simulatePastDate() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      String userId = currentUser.uid;

      DateTime pastDate = DateTime.now().subtract(Duration(days: 1));
      Timestamp pastTimestamp = Timestamp.fromDate(pastDate);

      await FirebaseFirestore.instance.collection('user_step').doc(userId).update({
        'timestamp': pastTimestamp,
      });

      await FirebaseFirestore.instance.collection('user_record').doc(userId).update({
        'timestamp': pastTimestamp,
      });
    }
  }

  void startTracking() {
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      trackSteps(event);
    });
    monitorSpeed();
  }

    Future<void> saveStepGoalToPreferences(int stepGoal) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setInt('stepGoal', stepGoal);
}

void showFoodDetails(BuildContext context, Map<String, dynamic> foodItem) async {
  String? imageUrl = await _getImageUrl(foodItem['image'] ?? '');

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 1,
              height: MediaQuery.of(context).size.height * 0.85,
              padding: EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'รายละเอียดอาหาร',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  imageUrl != null
                      ? Image.network(imageUrl)
                      : Text('ไม่พบรูปภาพ'),
                  SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ชื่ออาหาร: ${foodItem['food_name'] ?? '-'}',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue),
                          ),
                          Text('ประเภท: ${foodItem['food_type'] ?? '-'}',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.black54)),
                          SizedBox(height: 10),
                          Text('โภชนาการ',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                          buildProgressBar('คาร์โบไฮเดรต',
                              foodItem['nutrition']['carbohydrates'], 275),
                          buildProgressBar('โปรตีน',
                              foodItem['nutrition']['proteins'], 50),
                          buildProgressBar('ไขมัน',
                              foodItem['nutrition']['fats'], 70),
                          buildProgressBar('kcal',
                              foodItem['nutrition']['calories'], 2000),
                          buildProgressBar('น้ำตาล',
                              foodItem['nutrition']['sugar'], 25),
                          SizedBox(height: 10),
                          Text('วิตามิน',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                          buildProgressBar('วิตามิน A',
                              foodItem['nutrition']['vitamins']['vitaminA'], 900),
                          buildProgressBar('วิตามิน B',
                              foodItem['nutrition']['vitamins']['vitaminB'], 2.4),
                          buildProgressBar('วิตามิน C',
                              foodItem['nutrition']['vitamins']['vitaminC'], 90),
                          buildProgressBar('วิตามิน D',
                              foodItem['nutrition']['vitamins']['vitaminD'], 20),
                          buildProgressBar('วิตามิน E',
                              foodItem['nutrition']['vitamins']['vitaminE'], 15),
                          buildProgressBar('วิตามิน K',
                              foodItem['nutrition']['vitamins']['vitaminK'], 120),
                          SizedBox(height: 10),
                          Text('แร่ธาตุ',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                          buildProgressBar('แคลเซียม',
                              foodItem['nutrition']['minerals']['calcium'], 1000),
                          buildProgressBar('โพแทสเซียม',
                              foodItem['nutrition']['minerals']['potassium'], 3500),
                          buildProgressBar('โซเดียม',
                              foodItem['nutrition']['minerals']['sodium'], 2300),
                          buildProgressBar('เหล็ก',
                              foodItem['nutrition']['minerals']['iron'], 18),
                          buildProgressBar('แมกนีเซียม',
                              foodItem['nutrition']['minerals']['magnesium'], 400),
                          buildProgressBar('ใยอาหาร',
                              foodItem['nutrition']['fiber'], 25),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(); // ปิด dialog
                      },
                      child: Text('ปิด', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> loadStepGoalFromPreferences() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  setState(() {
    _stepGoal = prefs.getInt('stepGoal') ?? 10000; // ค่าเริ่มต้นคือ 10000 ก้าว
  });
}


    Future<void> loadFavoritesCount() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      String userId = currentUser.uid;
      DocumentReference favoritesRef = FirebaseFirestore.instance.collection('user_favorites').doc(userId);

      try {
        DocumentSnapshot doc = await favoritesRef.get();
        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>?;
          setState(() {
            _favoritesCount = (data?['favorites'] as List<dynamic>?)?.length ?? 0;
          });
        }
      } catch (e) {
        print("Failed to load favorites count: $e");
      }
    }
  }
  

    Future<void> loadUserEat() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      String userId = currentUser.uid;
      DocumentReference userRecordRef = FirebaseFirestore.instance.collection('user_record').doc(userId);

      try {
        DocumentSnapshot doc = await userRecordRef.get();
        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>?;
          setState(() {
            _userEat = data?['user_eat'] ?? 0;
          });
        }
      } catch (e) {
        print("Failed to load user eat: $e");
      }
    }
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
            _weight = data?['weight']?.toDouble() ?? 70;
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
      _steps = prefs.getInt('steps') ?? 0;
    });
  }

  Future<void> saveStepsToPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('steps', _steps);
  }

  Future<void> startBackgroundService() async {
    bool hasPermissions = await FlutterBackground.hasPermissions;
    if (!hasPermissions) {
      await FlutterBackground.initialize();
    }

    FlutterBackground.enableBackgroundExecution();
  }

  void trackSteps(AccelerometerEvent event) {
    if (_isDriving) {
      return;
    }

    double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    if ((magnitude - _previousMagnitude).abs() > 3) {
      setState(() {
        _steps++;
      });
      saveStepsToFirestore();
      saveStepsToPreferences();

      double caloriesBurned = calculateCalories(_steps, _weight);
      saveCaloriesToFirestore(caloriesBurned);
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
      double speed = position.speed * 3.6;

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

          if (data != null && data.containsKey('timestamp') && data['timestamp'] != null) {
            Timestamp lastUpdatedTimestamp = data['timestamp'];
            DateTime lastUpdatedDate = lastUpdatedTimestamp.toDate();
            DateTime now = DateTime.now();

            if (lastUpdatedDate.day != now.day || lastUpdatedDate.month != now.month || lastUpdatedDate.year != now.year) {
              setState(() {
                _steps = 0;
              });
              saveStepsToFirestore();
            } else {
              setState(() {
                _steps = data['steps'] ?? 0;
              });
            }
          } else {
            setState(() {
              _steps = data?['steps'] ?? 0;
            });
          }
          saveStepsToPreferences();
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
        DocumentSnapshot doc = await stepRef.get();

        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>?;

          if (data != null && data.containsKey('timestamp')) {
            Timestamp lastUpdatedTimestamp = data['timestamp'];
            DateTime lastUpdatedDate = lastUpdatedTimestamp.toDate();
            DateTime now = DateTime.now();

            if (lastUpdatedDate.day != now.day || lastUpdatedDate.month != now.month || lastUpdatedDate.year != now.year) {
              await backupAllUserDataBeforeReset(context);

              setState(() {
                _steps = 0;
              });
            }
          }
        }

        await stepRef.set({
          'steps': _steps,
          'timestamp': FieldValue.serverTimestamp(),
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

        DocumentReference userBurnedRef = FirebaseFirestore.instance.collection('user_burned').doc(userId);

        DocumentSnapshot doc = await userBurnedRef.get();

        if (doc.exists) {
          Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

          if (data != null && data.containsKey('lastUpdated')) {
            Timestamp lastUpdatedTimestamp = data['lastUpdated'];
            DateTime lastUpdatedDate = lastUpdatedTimestamp.toDate();

            DateTime now = DateTime.now();

            if (lastUpdatedDate.day != now.day || lastUpdatedDate.month != now.month || lastUpdatedDate.year != now.year) {
              await backupAllUserDataBeforeReset(context);

              await userBurnedRef.set({
                'burned': 0,
                'lastUpdated': Timestamp.now(),
              }, SetOptions(merge: true));
            }
          }
        }
      }
    } catch (e) {
      print("Failed to reset burned: $e");
    }
  }

  Future<void> resetDaily(BuildContext context) async {
  try {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      String userId = currentUser.uid;

      // ตรวจสอบ timestamp ใน user_record
      DocumentReference userRecordRef = FirebaseFirestore.instance.collection('user_record').doc(userId);
      DocumentSnapshot recordDoc = await userRecordRef.get();

      if (recordDoc.exists) {
        Map<String, dynamic>? data = recordDoc.data() as Map<String, dynamic>?;

        if (data != null && data.containsKey('timestamp')) {
          Timestamp lastUpdatedTimestamp = data['timestamp'];
          DateTime lastUpdatedDate = lastUpdatedTimestamp.toDate();
          DateTime now = DateTime.now();

          // ถ้าวันที่ไม่ตรงกันให้รีเซ็ตค่า
          if (lastUpdatedDate.day != now.day || lastUpdatedDate.month != now.month || lastUpdatedDate.year != now.year) {
            await backupAllUserDataBeforeReset(context);

            // อัปเดตค่าใน user_record ให้เป็น 0
            await userRecordRef.set({
              'user_eat': 0,
              'carbohydrate_eat': 0,
              'protein_eat': 0,
              'sugar_eat': 0,
              'timestamp': Timestamp.now(),
            }, SetOptions(merge: true));

            // อัปเดตค่า steps ให้เป็น 0 ใน user_step
            DocumentReference userStepRef = FirebaseFirestore.instance.collection('user_step').doc(userId);
            await userStepRef.set({
              'steps': 0,
              'timestamp': Timestamp.now(),
            }, SetOptions(merge: true));

            setState(() {
              _steps = 0; // อัปเดตค่า steps ใน UI ด้วย
            });
          }
        }
      }
    }
  } catch (e) {
    print("Failed to reset daily values: $e");
  }
}

  Future<void> backupAllUserDataBeforeReset(BuildContext context) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        String userId = currentUser.uid;

        DocumentReference userRecordRef = FirebaseFirestore.instance.collection('user_record').doc(userId);
        DocumentReference userStepRef = FirebaseFirestore.instance.collection('user_step').doc(userId);
        DocumentReference userBurnedRef = FirebaseFirestore.instance.collection('user_burned').doc(userId);
        DocumentReference userConsumedRef = FirebaseFirestore.instance.collection('user_consumed').doc(userId);

        DocumentSnapshot userRecordDoc = await userRecordRef.get();
        DocumentSnapshot userStepDoc = await userStepRef.get();
        DocumentSnapshot userBurnedDoc = await userBurnedRef.get();
        DocumentSnapshot userConsumedDoc = await userConsumedRef.get();

        Map<String, dynamic> backupData = {
          'user_record': userRecordDoc.exists ? userRecordDoc.data() : {},
          'user_step': userStepDoc.exists ? userStepDoc.data() : {},
          'user_burned': userBurnedDoc.exists ? userBurnedDoc.data() : {},
          'user_consumed': userConsumedDoc.exists ? userConsumedDoc.data() : {},
          'backup_timestamp': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('user_data')
            .doc(userId)
            .collection('daily_backup')
            .add(backupData);

        print("Backup data saved successfully!");
      }
    } catch (e) {
      print("Failed to backup user data: $e");
    }
  }

  Future<void> resetConsumed(BuildContext context) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        String userId = currentUser.uid;

        DocumentReference userBurnedRef = FirebaseFirestore.instance.collection('user_consumed').doc(userId);

        DocumentSnapshot doc = await userBurnedRef.get();

        if (doc.exists) {
          Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

          if (data != null && data.containsKey('lastUpdated')) {
            Timestamp lastUpdatedTimestamp = data['lastUpdated'];
            DateTime lastUpdatedDate = lastUpdatedTimestamp.toDate();

            DateTime now = DateTime.now();

            if (lastUpdatedDate.day != now.day || lastUpdatedDate.month != now.month || lastUpdatedDate.year != now.year) {
              await backupAllUserDataBeforeReset(context);

              await userBurnedRef.set({
                'count': 0,
                'lastUpdated': Timestamp.now(),
              }, SetOptions(merge: true));
            }
          }
        }
      }
    } catch (e) {}
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
                _stepGoal = int.tryParse(goalController.text) ?? 10000;
              });
              saveStepGoalToPreferences(_stepGoal); // บันทึกค่าเป้าหมายใหม่ใน SharedPreferences
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}


  Future<String> _getImageUrl(String imagePath) async {
  try {
    // ดึง URL จาก Firebase Storage
    String downloadURL = await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
    return downloadURL;
  } catch (e) {
    print('Failed to load image URL: $e');
    return '';
  }
}


  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Transform.translate(
              offset: Offset(0, -70),
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: Colors.transparent,
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
              offset: Offset(110, 210),
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
        progress1 -= 10;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;
    double progress = (_steps / _stepGoal).clamp(0.0, 1.0);

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
                Text('$_favoritesCount'),
              ],
            ),
            Row(
              children: [
                Icon(FontAwesome.utensils_solid, color: Colors.grey),
                SizedBox(width: 5),
                Text('$_userEat'),
              ],
            ),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.green),
                SizedBox(width: 5),
                Text('${TimeOfDay.now().hour}h'),
              ],
            ),
          ],
        ),
      ),
      body: Container(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              child: Container(
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
                                .collection('user_record')
                                .doc(FirebaseAuth.instance.currentUser?.uid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                var data = snapshot.data!.data() as Map<String, dynamic>?;
                                var userEat = data?['user_eat'] ?? 0;
                                var tdee = data?['tdee'] ?? 2000;

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
      var kcalRemaining = userEat >= tdee ? (userEat - tdee).toStringAsFixed(0) : (tdee - userEat).toStringAsFixed(0);

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
                              StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('user_consumed')
                                    .doc(FirebaseAuth.instance.currentUser?.uid)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    var data = snapshot.data!.data() as Map<String, dynamic>?;
                                    var consumed = data?['count'] ?? 0;
                                    return Text(
                                      '$consumed',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    );
                                  } else {
                                    return Text(
                                      '0',
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
                              StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('user_burned')
                                    .doc(FirebaseAuth.instance.currentUser?.uid)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    var data = snapshot.data!.data() as Map<String, dynamic>?;
                                    var burned = data?['burned'] ?? 0;
                                    return Text(
                                      '$burned',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    );
                                  } else {
                                    return Text(
                                      '0',
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
                width: 350,
                height: 130,
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

                          var carb = data?['carbohydrate'] ?? 0;
                          var carbEat = data?['carbohydrate_eat'] ?? 0;

                          double progressCarb = carbEat >= carb ? 100 : (carbEat / carb) * 100;

                          return SizedBox(
                            height: 80,
                            width: 80,
                            child: CustomPaint(
                              painter: FullCircleProgress(progressCarb, const Color.fromARGB(255, 255, 178, 46)),
                              child: Center(
                                child: Text(
                                  '🍞',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
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

                          var protein = data?['protein'] ?? 0;
                          var proteinEat = data?['protein_eat'] ?? 0;

                          double progressProtein = proteinEat >= protein ? 100 : (proteinEat / protein) * 100;

                          return SizedBox(
                            height: 80,
                            width: 80,
                            child: CustomPaint(
                              painter: FullCircleProgress(progressProtein, Colors.red),
                              child: Center(
                                child: Text(
                                  '🥩',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
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

                          var sugar = data?['sugar'] ?? 0;
                          var sugarEat = data?['sugar_eat'] ?? 0;

                          double progressSugar = sugarEat >= sugar ? 100 : (sugarEat / sugar) * 100;

                          return SizedBox(
                            height: 80,
                            width: 80,
                            child: CustomPaint(
                              painter: FullCircleProgress(progressSugar, const Color.fromARGB(255, 138, 77, 55)),
                              child: Center(
                                child: Text(
                                  '🍫',
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
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
                SizedBox(width: 5),
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
                _showEditStepGoalDialog(context);
              },
            ),
          ],
        ),
        SizedBox(height: 1),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('user_step')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var data = snapshot.data!.data() as Map<String, dynamic>?;
                  int steps = data?['steps'] ?? 0;
                  double progress = (steps / _stepGoal).clamp(0.0, 1.0);

                  return Row(
                    children: [
                      Text(
                        ' $steps ก้าว',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'เป้าหมาย: $_stepGoal ก้าว',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: const Color.fromARGB(255, 42, 43, 42)),
                      ),
                    ],
                  );
                } else {
                  return Text(
                    'Loading...',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }
              },
            ),
          ],
        ),
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('user_step')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    var data = snapshot.data!.data() as Map<String, dynamic>?;
                    int steps = data?['steps'] ?? 0;
                    double progress = (steps / _stepGoal).clamp(0.0, 1.0);

                    return LinearProgressIndicator(
                      value: progress,
                      minHeight: 18,
                      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                      color: const Color(0xFF31C38B),
                    );
                  } else {
                    return LinearProgressIndicator(
                      value: 0,
                      minHeight: 18,
                      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                      color: const Color(0xFF31C38B),
                    );
                  }
                },
              ),
            ),
            Positioned(
              left: progress * 338,
              top: 2,
              child: Icon(
                TeenyIcons.heart,
                color: const Color.fromARGB(255, 32, 93, 69),
                size: 15,
              ),
            ),
          ],
        ),
        SizedBox(height: 5),
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
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      Icon(FontAwesome.fire_solid, color: Colors.red, size: 15),
                      SizedBox(width: 5),
                      Text(
                        ' ${caloriesBurned.toStringAsFixed(0)} แคลอรี่',
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
                alignment: Alignment.centerLeft,
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

            // แสดงประวัติการกินอาหาร
            Padding(
  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
  child: Container(
    width: 350,
    height: 120,
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
    padding: const EdgeInsets.all(10),
    child: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_addFood')
          .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var foodItems = snapshot.data!.docs;

          // แปลงเป็น List<Map<String, dynamic>> และจัดเรียงตาม timestamp
          var sortedFoodItems = foodItems.map((doc) => doc.data() as Map<String, dynamic>).toList()
            ..sort((a, b) {
              Timestamp aTimestamp = a['added_at'] as Timestamp;
              Timestamp bTimestamp = b['added_at'] as Timestamp;
              return bTimestamp.compareTo(aTimestamp); // เรียงจากใหม่ไปเก่า
            });

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sortedFoodItems.length,
            itemBuilder: (context, index) {
  var foodData = sortedFoodItems[index];
  
  return GestureDetector(
    onTap: () {
      showFoodDetails(context, foodData); // เรียกใช้ฟังก์ชันแสดงรายละเอียดอาหาร
    },
    child: Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 200,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${foodData['food_name']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text('${foodData['kcal']} แคลอรี่'),
                    SizedBox(width: 4),
                    Icon(
                      FontAwesome.fire_solid,
                      color: Colors.red,
                      size: 15,
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  '${foodData['added_at'].toDate().hour}:${foodData['added_at'].toDate().minute}',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
},
          );
        } else if (snapshot.hasError) {
          return Text('Error loading food history');
        } else {
          return CircularProgressIndicator();
        }
      },
    ),
  ),
),




          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(home: MainMenu()));
}
