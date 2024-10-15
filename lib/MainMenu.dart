import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart'; // ใช้สำหรับดึงข้อมูลจาก Firestore
import 'package:firebase_auth/firebase_auth.dart';
import 'tflite.dart';

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
      ..strokeWidth = 12
      ..color = Colors.grey.shade300;

    Paint progressCircle = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
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
      ..color = Colors.grey.shade300;

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



//นี่คือส่วนในการรีเซตค่า burned ทุกครั้งที่ขึ้นวันใหม่ เพื่อให้แอพมีความเป็น daily use มากขึ้น

 @override
  void initState() {
    super.initState();
    // เรียกใช้ resetBurnedIfNewDay ใน initState ของ MainMenu
    resetBurnedIfNewDay(context);
    resetDaily(context);
    resetConsumed(context);
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
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
                          height: 70,
                          width: 70,
                            child: CustomPaint(
                              painter: FullCircleProgress(progressCarb, const Color.fromARGB(255, 255, 178, 46)), // วงกลมที่ 1
                              child: Center(
                                child: Text(
                                  '🍞', // แสดงเปอร์เซ็นต์ความคืบหน้าในกราฟวงกลม
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black, // เปลี่ยนสีตัวอักษรตามที่ต้องการ
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
                          height: 70,
                          width: 70,
                          child: CustomPaint(
                              painter: FullCircleProgress(progressProtein,Colors.red), // วงกลมที่ 1
                              child: Center(
                                child: Text(
                                  '🥩', // แสดงเปอร์เซ็นต์ความคืบหน้าในกราฟวงกลม
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black, // เปลี่ยนสีตัวอักษรตามที่ต้องการ
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
                          height: 70,
                          width: 70,
                          child: CustomPaint(
                              painter: FullCircleProgress(progressSugar,const Color.fromARGB(255, 138, 77, 55)), // วงกลมที่ 1
                              child: Center(
                                child: Text(
                                  '🍫', // แสดงเปอร์เซ็นต์ความคืบหน้าในกราฟวงกลม
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black, // เปลี่ยนสีตัวอักษรตามที่ต้องการ
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
        ],
      ),
    );
  }
}



void main() {
  runApp(MaterialApp(home: MainMenu()));
}
