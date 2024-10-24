import 'package:flutter/material.dart';
import 'weight_page.dart';

class HeightWeightPage extends StatefulWidget {
  const HeightWeightPage({Key? key}) : super(key: key);

  @override
  _HeightWeightPageState createState() => _HeightWeightPageState();
}

class _HeightWeightPageState extends State<HeightWeightPage> {
  int _selectedHeight = 170; // ค่าเริ่มต้นของความสูง
  String _name = '';

  // ฟังก์ชันนำทางไปยังหน้าเลือกน้ำหนัก
  void _goToWeightPage() {
    if (_name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    // นำทางไปยังหน้าเลือกน้ำหนัก
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WeightPage(
          name: _name,
          height: _selectedHeight,
        ),
      ),
    );
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      labelStyle: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                      filled: true,
                      fillColor: Color.fromARGB(255, 255, 255, 255),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _name = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Height: $_selectedHeight cm',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 255, 255, 255)),
                ),
                // ส่วนเลือกความสูง
                Container(
                  height: 150, // กำหนดความสูงของล้อหมุน
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 50,
                    perspective: 0.005,
                    diameterRatio: 1.2,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedHeight = 150 + index; // เริ่มจาก 150 ซม.
                      });
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) {
                        final height = 150 + index;
                        final isSelected = height == _selectedHeight;

                        return Center(
                          child: Text(
                            '$height cm',
                            style: TextStyle(
                              fontSize: isSelected ? 24 : 18,
                              color: isSelected
                                  ? const Color.fromARGB(255, 255, 255, 255)
                                  : Colors.black54,
                            ),
                          ),
                        );
                      },
                      childCount: 101, // ช่วงระหว่าง 150 ถึง 250
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                ElevatedButton(
                  onPressed: _goToWeightPage,
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
          // เส้นแดงที่อยู่ตรงกลางของ ruler slider
          Center(
            child: Container(
              height: 4, // ความสูงของเส้นกลาง
              color: const Color.fromARGB(255, 255, 255, 255),
              margin: const EdgeInsets.symmetric(horizontal: 40),
            ),
          ),
          // เส้นบรรทัดที่ด้านขวา
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // สร้าง 5 เส้นไม้บรรทัด โดยใช้ Transform เพื่อปรับตำแหน่ง
                Transform.translate(
                  offset: const Offset(0, 50), // ไม่มีการเลื่อน
                  child: Container(
                    width: 70,
                    height: 2,
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, 60), // เลื่อนขึ้น
                  child: Container(
                    width: 60,
                    height: 2,
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, 70), // เลื่อนขึ้น
                  child: Container(
                    width: 100,
                    height: 2,
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, 80), // เลื่อนลง
                  child: Container(
                    width: 60,
                    height: 2,
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, 90), // ไม่มีการเลื่อน
                  child: Container(
                    width: 70,
                    height: 2,
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
