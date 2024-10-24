import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // นำเข้า Firebase Firestore
import 'package:firebase_auth/firebase_auth.dart'; // นำเข้า Firebase Auth
import 'birthdate_page.dart'; // นำเข้า BirthdatePage หลังจากบันทึกข้อมูลเสร็จ

class WeightPage extends StatefulWidget {
  final String name;
  final int height; // ใช้เป็น int ได้ ไม่จำเป็นต้องเปลี่ยน

  const WeightPage({Key? key, required this.name, required this.height}) : super(key: key);

  @override
  _WeightPageState createState() => _WeightPageState();
}

class _WeightPageState extends State<WeightPage> {
  double _selectedWeight = 70.0; // ค่าเริ่มต้นของน้ำหนัก
  bool _isSaving = false; // แสดงสถานะการบันทึก
  PageController _pageController = PageController(viewportFraction: 0.3, initialPage: 20); // เริ่มต้นที่ index 20 (70 kg)

  // ฟังก์ชันบันทึกข้อมูลใน Firestore และนำทางไปยังหน้า BirthdatePage
  void _saveDataAndNavigate() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': widget.name,
          'height': widget.height.toDouble(), // แปลง height เป็น double
          'weight': _selectedWeight, // ใช้ _selectedWeight เป็น double
          'roll': 'user',
        }, SetOptions(merge: true)); // ใช้ merge เพื่อไม่ลบข้อมูลเดิม

        // นำทางไปยัง BirthdatePage หลังจากบันทึกเสร็จแล้ว
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BirthdatePage(
              name: widget.name,
              height: widget.height.toDouble(), // แปลง height เป็น double
              weight: _selectedWeight, // ใช้ _selectedWeight เป็น double
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save data: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // แบ็คกราวด์เป็นรูปภาพ
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/BG.png'),
                fit: BoxFit.cover,
                alignment: Alignment(0.0, -2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 100),
                Text(
                  'Weight: ${_selectedWeight.toInt()} kg',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 20),
                // ส่วนเลือกน้ำหนักแบบแนวนอน
                SizedBox(
                  height: 100,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedWeight = (50 + index).toDouble(); // เปลี่ยนค่าน้ำหนักตามหน้าเริ่มที่ 50
                      });
                    },
                    itemBuilder: (context, index) {
                      final weight = 50 + index; // ค่าน้ำหนักที่จะแสดง
                      return Center(
                        child: Text(
                          '$weight kg',
                          style: TextStyle(
                            fontSize: weight == _selectedWeight ? 24 : 18,
                            color: weight == _selectedWeight
                                ? const Color.fromARGB(255, 255, 255, 255)
                                : Colors.black54,
                          ),
                        ),
                      );
                    },
                    itemCount: 171, // น้ำหนักตั้งแต่ 50 ถึง 220 (220 - 50 + 1)
                  ),
                ),
                const SizedBox(height: 20),

                _isSaving
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _saveDataAndNavigate,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Next',
                          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                        ),
                      ),
              ],
            ),
          ),
          // เส้นแดงที่อยู่ตรงกลาง
          Align(
            alignment: Alignment.center,
            child: Container(
              height: 2,
              color: const Color.fromARGB(255, 255, 255, 255),
              margin: const EdgeInsets.symmetric(horizontal: 40),
            ),
          ),
          // เส้นแนวตั้งที่ด้านขวา
          Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // สร้าง 5 เส้นไม้บรรทัด โดยใช้ Transform เพื่อปรับตำแหน่ง
                Transform.translate(
                  offset: const Offset(-30, 80), // เส้นแรก
                  child: Container(
                    width: 2,
                    height: 30, // ความสูง
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(-15, 80), // เส้นที่สอง
                  child: Container(
                    width: 2,
                    height: 20, // ความสูง
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, 80), // เส้นกลาง
                  child: Container(
                    width: 2,
                    height: 40, // ความสูง
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(15, 80), // เส้นที่สี่
                  child: Container(
                    width: 2,
                    height: 20, // ความสูง
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(30, 80), // เส้นที่ห้า
                  child: Container(
                    width: 2,
                    height: 30, // ความสูง
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
