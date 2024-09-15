import 'package:flutter/material.dart';
import 'dart:ui';

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
                'assets/images/Mascot.PNG',
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
      if (progress < 100) {
        progress += 10; // เพิ่ม progress ทีละ 10%
        if (progress >= 100) {
          _showCompletionDialog(); // แสดง Alert เมื่อถึง 100%
        }
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

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 15),
            child: Container(
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
                        child: CustomPaint(
                          painter: HalfCircleProgress(progress),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(0, -20),
                        child: Text(
                          '3,118',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(0, -2),
                        child: Text(
                          'kcal Remaining',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(-120, 0),
                        child: Column(
                          children: [
                            Text(
                              '0',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                    ],
                  ),
                  Transform.translate(
                    offset: Offset(0, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _decreaseProgress,
                            child: Text(
                              'ลดความก้าวหน้า',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _increaseProgress,
                            child: Text('เพิ่มความก้าวหน้า',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
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
