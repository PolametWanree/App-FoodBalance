import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodbalance4/EditFoodPage.dart'; // ใช้สำหรับดึงข้อมูลผู้ใช้ที่ล็อกอิน

// ย้าย DonutChartPainter ออกมาที่ระดับ top-level
class DonutChartPainter extends CustomPainter {
  final double percentage;
  final String label;
  final Color color;

  DonutChartPainter({required this.percentage, required this.label, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double radius = size.width / 2;
    Paint backgroundPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    Paint foregroundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    // วาดกรอบวงกลมพื้นหลัง (โดนัท)
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, backgroundPaint);

    // วาดกราฟเปอร์เซ็นต์ในลักษณะโดนัท
    double sweepAngle = 2 * 3.1416 * (percentage / 100);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: radius),
      -3.1416 / 2, // เริ่มจากด้านบน
      sweepAngle,
      false,
      foregroundPaint,
    );

    // วาดรูตรงกลางของโดนัท
    Paint innerCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius / 2, innerCirclePaint);

    // วาดข้อความตรงกลาง
    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, size.height / 2 - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
  }
}

class FoodListPage extends StatefulWidget {
  @override
  _FoodListPageState createState() => _FoodListPageState();
}

class _FoodListPageState extends State<FoodListPage> {
  TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              searchQuery = value.toLowerCase(); // อัปเดตการค้นหา
            });
          },
          decoration: InputDecoration(
            hintText: 'ค้นหาอาหาร...',
            hintStyle: TextStyle(color: Colors.white),
            border: InputBorder.none,
          ),
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: (searchQuery.isEmpty)
            ? FirebaseFirestore.instance.collection('food').snapshots()
            : FirebaseFirestore.instance
                .collection('food')
                .where('name', isGreaterThanOrEqualTo: searchQuery)
                .where('name', isLessThanOrEqualTo: searchQuery + '\uf8ff')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final foodItems = snapshot.data!.docs;

          return ListView.builder(
            itemCount: foodItems.length,
            itemBuilder: (context, index) {
              var foodItem = foodItems[index].data() as Map<String, dynamic>;

              // ดึง URL ของรูปภาพจาก Firestore เพื่อใช้ใน leading
              return FutureBuilder<String?>(
                future: _getImageUrl(foodItem['image'] ?? ''),
                builder: (context, snapshot) {
                  String? imageUrl = snapshot.data;

                  return Card(
                    margin: EdgeInsets.all(2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                    child: ListTile(
  leading: imageUrl != null
      ? Image.network(
          imageUrl,
          width: 50, // กำหนดขนาดของรูปภาพ
          height: 50,
          fit: BoxFit.cover,
        )
      : Icon(Icons.image, size: 50), // ถ้าไม่มีรูปภาพจะแสดงไอคอน
  title: Text(foodItem['name'] ?? '-'),
  subtitle: Text.rich(
    TextSpan(
      text: 'แคลลอรี่: ', // ข้อความปกติ
      style: TextStyle(color: Colors.black), // สีของข้อความปกติ
      children: <TextSpan>[
        TextSpan(
          text: '${foodItem['nutrition'] != null ? foodItem['nutrition']['calories'] ?? '-' : '-'}', // ตรวจสอบ null ก่อนเข้าถึงค่าแคลอรี่
          style: TextStyle(
              color: const Color.fromARGB(255, 89, 169, 92)), // สีเฉพาะสำหรับตัวเลขแคลอรี่
        ),
      ],
    ),
  ),
  trailing: Container(
    width: 100, // ขนาดของพื้นที่สำหรับกราฟโดนัททั้งสอง
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // วงแรกสำหรับโปรตีน
        CustomPaint(
          size: Size(40, 40),
          painter: DonutChartPainter(
            percentage: double.tryParse(foodItem['nutrition'] != null ? foodItem['nutrition']['proteins'] ?? '0' : '0') ?? 0,
            label: '🥩', // Empty label
            color: const Color.fromARGB(255, 255, 153, 69),
          ),
        ),
        // วงที่สองสำหรับน้ำตาล
        CustomPaint(
          size: Size(40, 40),
          painter: DonutChartPainter(
            percentage: double.tryParse(foodItem['nutrition'] != null ? foodItem['nutrition']['carbohydrates'] ?? '0' : '0') ?? 0,
            label: '🍞',
            color: const Color.fromARGB(255, 255, 209, 94),
          ),
        ),
      ],
    ),
  ),
onTap: () {
    showFoodDetails(context, foodItems[index].id);
  },
),

                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<String?> _getImageUrl(String imageName) async {
    try {
      String downloadURL = await FirebaseStorage.instance
          .ref(imageName) // ดึง URL ของรูปภาพตามชื่อที่เก็บใน Firestore
          .getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('Error fetching image URL: $e');
      return null;
    }
  }

  void showFoodDetails(BuildContext context, String foodId) async {
    DocumentSnapshot docSnapshot =
        await FirebaseFirestore.instance.collection('food').doc(foodId).get();
    var foodItem = docSnapshot.data() as Map<String, dynamic>;

    String? imageUrl = await _getImageUrl(foodItem['image'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
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
                // แสดงรูปภาพที่ดึงจาก Firebase Storage
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
                          'ชื่ออาหาร: ${foodItem['name'] ?? '-'}',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue),
                        ),
                        Text('ประเภท: ${foodItem['type'] ?? '-'}',
                            style:
                                TextStyle(fontSize: 16, color: Colors.black54)),
                        SizedBox(height: 10),
                        Text('โภชนาการ',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),

                        buildProgressBar(
                            'คาร์โบไฮเดรต',
                            foodItem['nutrition']['carbohydrates'],
                            275),
                        buildProgressBar(
                            'โปรตีน', foodItem['nutrition']['proteins'], 50),
                        buildProgressBar(
                            'ไขมัน', foodItem['nutrition']['fats'], 70),
                        buildProgressBar(
                            'kcal', foodItem['nutrition']['calories'], 2000),
                        buildProgressBar(
                            'น้ำตาล', foodItem['nutrition']['sugar'], 25),
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
                        buildProgressBar(
                            'โพแทสเซียม',
                            foodItem['nutrition']['minerals']['potassium'],
                            3500),
                        buildProgressBar('โซเดียม',
                            foodItem['nutrition']['minerals']['sodium'], 2300),
                        buildProgressBar('เหล็ก',
                            foodItem['nutrition']['minerals']['iron'], 18),
                        buildProgressBar('แมกนีเซียม',
                            foodItem['nutrition']['minerals']['magnesium'], 400),

                        SizedBox(height: 10),
                        buildProgressBar(
                            'ใยอาหาร', foodItem['nutrition']['fiber'], 25),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orangeAccent,
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop(); // ปิด dialog
                                      // นำทางไปยังหน้าแก้ไข
                                      Navigator.of(context).push(MaterialPageRoute(
                                        builder: (context) => EditFoodPage(foodId: foodId),
                                      ));
                                    },
                                    child: Text('แก้ไข', style: TextStyle(color: Colors.white)),
                                  ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        onPressed: () async {
                          await addFoodToHistory(context, foodItem); // เพิ่มอาหารในประวัติ
                          await updateUserEat(
    context, 
    foodItem['nutrition']['calories'], 
    foodItem['nutrition']['carbohydrates'], 
    foodItem['nutrition']['proteins'], 
    foodItem['nutrition']['sugar']
  );  // อัปเดต user_eat ใน user_record
                          await updateConsumedCount(context); // อัปเดต consumed ใน user_consumed

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('เพิ่มอาหารเรียบร้อยแล้ว')),
                          );

                          Navigator.of(context).pop(); // ปิด dialog
                        },
                        child: Text('เพิ่ม', style: TextStyle(color: Colors.white)),
                      ),
                      ElevatedButton(
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ฟังก์ชันเพิ่มอาหารในประวัติ Firestore
  Future<void> addFoodToHistory(BuildContext context, Map<String, dynamic> foodItem) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        String userId = currentUser.uid;

        await FirebaseFirestore.instance.collection('user_addFood').add({
          'food_name': foodItem['name'] ?? '-',
          'food_type': foodItem['type'] ?? '-',
          'nutrition': foodItem['nutrition'] ?? {},
          'added_at': DateTime.now(),
          'user_id': userId,
          'kcal': foodItem['nutrition']['calories'],
        });
      }
    } catch (e) {
      print("Failed to add food item to history: $e");
    }
  }

  // ฟังก์ชันอัปเดต user_eat ใน collection user_record
Future<void> updateUserEat(BuildContext context, dynamic kcal, dynamic carbohydrates, dynamic proteins, dynamic sugar) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        String userId = currentUser.uid;

        DocumentReference userRecordRef =
            FirebaseFirestore.instance.collection('user_record').doc(userId);

        DocumentSnapshot doc = await userRecordRef.get();
         int currentUserEat = 0;
          int currentCarbohydratesEat = 0;
          int currentProteinsEat = 0;
          int currentSugarEat = 0;
        if (doc.exists) {
          currentUserEat = doc.get('user_eat') ?? 0;
          currentCarbohydratesEat = doc.get('carbohydrate_eat') ?? 0;
          currentProteinsEat = doc.get('protein_eat') ?? 0;
          currentSugarEat = doc.get('sugar_eat') ?? 0;
        }

        int kcalValue = (kcal != null && kcal is String) ? int.parse(kcal) : (kcal ?? 0);
        int carbohydratesValue = (carbohydrates != null && carbohydrates is String) ? int.parse(carbohydrates) : (carbohydrates ?? 0);
        int proteinsValue = (proteins != null && proteins is String) ? int.parse(proteins) : (proteins ?? 0);
        int sugarValue = (sugar != null && sugar is String) ? int.parse(sugar) : (sugar ?? 0);
        
        await userRecordRef.update({
          'user_eat': currentUserEat + kcalValue,
          'carbohydrate_eat': currentCarbohydratesEat + carbohydratesValue,
          'protein_eat': currentProteinsEat + proteinsValue,
          'sugar_eat': currentSugarEat + sugarValue,
          'timestamp': Timestamp.now(),
        });
      }
    } catch (e) {
      print("Failed to update user_eat: $e");
    }
  }

  // ฟังก์ชันอัปเดต consumed ใน collection user_consumed
  Future<void> updateConsumedCount(BuildContext context) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        String userId = currentUser.uid;

        DocumentReference userConsumedRef =
            FirebaseFirestore.instance.collection('user_consumed').doc(userId);

        DocumentSnapshot doc = await userConsumedRef.get();
        int currentCount = 0;

        if (doc.exists) {
          Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('count')) {
            currentCount = data['count'] ?? 0;
          }
        }

        await userConsumedRef.set({
          'count': currentCount + 1,
          'lastUpdated': Timestamp.now(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("Failed to update consumed count: $e");
    }
  }

  // ฟังก์ชันสร้าง progress bar
  Widget buildProgressBar(String label, dynamic value, double recommended) {
    double? parsedValue =
        value != null ? double.tryParse(value.toString()) : null;
    double progress =
        parsedValue != null ? (parsedValue / recommended).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            '$label: ${parsedValue?.toStringAsFixed(1) ?? '-'} (${(progress * 100).toStringAsFixed(1)}%)',
            style: TextStyle(fontSize: 16)),
        SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 10,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              color: Colors.green,
            ),
          ),
        ),
        SizedBox(height: 8),
      ],
    );
  }
}
