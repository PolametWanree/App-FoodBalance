import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart'; // ใช้สำหรับดึงข้อมูลจาก Firestore
import 'package:firebase_auth/firebase_auth.dart';

import 'tflite.dart'; // ใช้สำหรับการล็อกอินของผู้ใช้

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

class MainMenu extends StatefulWidget {
  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  double progress = 50; // เริ่มต้น progress ที่ 50%

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

  void _increaseProgress() {
    setState(() {
      progress += 10; // เพิ่ม progress ทีละ 10%
if (progress >= 100) {
  progress = 100; // ทำให้แน่ใจว่า progress จะไม่เกิน 100%
  _showCompletionDialog(); // แสดง Alert เมื่อถึง 100%
}

    });
  }

  void _decreaseProgress() {
    setState(() {
      if (progress > 0) {
        progress -= 10; // ลด progress ทีละ 10%
      }
    });
  }

  // ฟังก์ชันดึงข้อมูล TDEE ของผู้ใช้แต่ละคนจาก Firestore
  Stream<DocumentSnapshot> _getUserTDEE(String userId) {
    return FirebaseFirestore.instance
        .collection('user_record')
        .doc(userId)
        .snapshots();
  }

  // ฟังก์ชันดึงข้อมูล consumed ของผู้ใช้แต่ละคนจาก Firestore
  Stream<DocumentSnapshot> _getUserConsumedCount(String userId) {
    return FirebaseFirestore.instance
        .collection('user_consumed') // ตรวจสอบว่าใช้ collection ชื่อนี้จริง ๆ
        .doc(userId)
        .snapshots();
  }

  void checkAndResetUserConsumedCount(String userId) async {
  DocumentSnapshot snapshot = await FirebaseFirestore.instance
      .collection('user_consumed')
      .doc(userId)
      .get();

  if (snapshot.exists) {
    var data = snapshot.data() as Map<String, dynamic>?;
    var lastUpdated = data?['lastUpdated'] as Timestamp?;

    if (lastUpdated != null) {
      DateTime lastUpdateDate = lastUpdated.toDate();
      DateTime currentDate = DateTime.now();

      // ตรวจสอบว่าวันปัจจุบันกับวันสุดท้ายที่อัปเดตต่างกันหรือไม่
      if (lastUpdateDate.day != currentDate.day ||
          lastUpdateDate.month != currentDate.month ||
          lastUpdateDate.year != currentDate.year) {
        // ถ้าวันใหม่ ให้รีเซ็ต count เป็น 0
        await FirebaseFirestore.instance
            .collection('user_consumed')
            .doc(userId)
            .update({
          'count': 0,
          'lastUpdated': Timestamp.fromDate(currentDate), // อัปเดตวันที่ใหม่
        });
      }
    }
  }
}


  // ฟังก์ชันตรวจสอบและรีเซ็ตค่า user_eat เมื่อขึ้นวันใหม่
  void checkAndResetUserEat(String userId) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('user_record')
        .doc(userId)
        .get();

    if (snapshot.exists) {
      var data = snapshot.data() as Map<String, dynamic>?;
      var timestamp = data?['timestamp'] as Timestamp?;

      if (timestamp != null) {
        DateTime lastUpdateDate = timestamp.toDate();
        DateTime currentDate = DateTime.now();

        // ตรวจสอบว่าวันปัจจุบันกับวันสุดท้ายที่อัปเดตต่างกันหรือไม่
        if (lastUpdateDate.day != currentDate.day ||
            lastUpdateDate.month != currentDate.month ||
            lastUpdateDate.year != currentDate.year) {
          // ถ้าวันใหม่ ให้รีเซ็ต user_eat เป็น 0
          await FirebaseFirestore.instance
              .collection('user_record')
              .doc(userId)
              .update({
            'user_eat': 0,
            'timestamp': Timestamp.fromDate(currentDate), // อัปเดตวันที่ใหม่
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // รับ userId จาก Firebase Authentication
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    // เรียกฟังก์ชันตรวจสอบและรีเซ็ต user_eat เมื่อขึ้นวันใหม่
    checkAndResetUserEat(userId ?? '');
    checkAndResetUserConsumedCount(userId ?? '');

    return Scaffold(
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
              height: 180,
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
                              .doc(userId)
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
                        stream: _getUserTDEE(userId ?? ''),
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
                              stream: _getUserConsumedCount(userId ?? ''),
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
                            Text(
                              '0',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Burned',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                        Transform.translate(
                        offset: Offset(0, 60), // Adjust the offset as needed
                        child: SizedBox(
                          width: 160, // Adjust the width as needed
                          height: 50, // Adjust the height as needed
                          child: ElevatedButton(
                    
                          onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ImageScannerPage()), // ลิงก์ไปยังหน้า ImageScannerPage
                          );
                          },
                          child: Text(
                          'Add Meal',
                          style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 91, 172, 123), // กำหนดสีปุ่ม
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12), // ปรับมุมโค้งของปุ่ม
                          ),
                          ),
                        ),
                        ),
                        ),
                    ],

                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            "ประวัติการบริโภคอาหาร",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          // ดึงข้อมูลของผู้ใช้ที่ล็อกอิน
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getUserFoodHistory(userId ?? ''), // ใช้ userId ในการกรองข้อมูล
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var foodHistory = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: foodHistory.length,
                  itemBuilder: (context, index) {
                    var food = foodHistory[index].data() as Map<String, dynamic>;

                    // เช็คว่า 'added_at' มีค่าเป็น null หรือไม่
                    Timestamp? timestamp = food['added_at'] as Timestamp?;
                    String formattedDate = '';

                    // ถ้ามีค่า 'added_at' ให้ทำการแปลงเป็น DateTime และกำหนดรูปแบบวันที่
                    if (timestamp != null) {
                      DateTime addedAt = timestamp.toDate(); // แปลงเป็น DateTime
                      formattedDate = "${addedAt.day}/${addedAt.month}/${addedAt.year} ${addedAt.hour}:${addedAt.minute}";
                    } else {
                      formattedDate = 'ไม่มีข้อมูลเวลา'; // หากไม่มีข้อมูล ให้แสดงข้อความนี้แทน
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                food['food_name'] ?? '-',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'เพิ่มเมื่อ: $formattedDate',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getUserFoodHistory(String userId) {
    return FirebaseFirestore.instance
        .collection('user_addFood')
        .where('user_id', isEqualTo: userId) // กรองเฉพาะข้อมูลของผู้ใช้ที่ล็อกอิน
        .snapshots();
  }
}

void main() {
  runApp(MaterialApp(home: MainMenu()));
}
