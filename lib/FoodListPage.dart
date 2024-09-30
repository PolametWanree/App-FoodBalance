import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ใช้สำหรับดึงข้อมูลผู้ใช้ที่ล็อกอิน

class FoodListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายการอาหาร'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('food').snapshots(),
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
              return ListTile(
                title: Text(foodItem['name'] ?? '-'),
                subtitle: Text('ประเภท: ${foodItem['type'] ?? '-'}'),
                onTap: () {
                  showFoodDetails(context, foodItems[index].id);
                },
              );
            },
          );
        },
      ),
    );
  }

  void showFoodDetails(BuildContext context, String foodId) async {
    DocumentSnapshot docSnapshot = await FirebaseFirestore.instance.collection('food').doc(foodId).get();
    var foodItem = docSnapshot.data() as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.80,
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
                SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ชื่ออาหาร: ${foodItem['name'] ?? '-'}',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        Text('ประเภท: ${foodItem['type'] ?? '-'}', style: TextStyle(fontSize: 16, color: Colors.black54)),
                        SizedBox(height: 10),
                        Text('โภชนาการ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                        
                        buildProgressBar('คาร์โบไฮเดรต', foodItem['nutrition']['carbohydrates'], 275),
                        buildProgressBar('โปรตีน', foodItem['nutrition']['proteins'], 50),
                        buildProgressBar('ไขมัน', foodItem['nutrition']['fats'], 70),
                        buildProgressBar('kcal', foodItem['nutrition']['calories'], 2000),
                        SizedBox(height: 10),
                        Text('วิตามิน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                        buildProgressBar('วิตามิน A', foodItem['nutrition']['vitamins']['vitaminA'], 900),
                        buildProgressBar('วิตามิน B', foodItem['nutrition']['vitamins']['vitaminB'], 2.4),
                        buildProgressBar('วิตามิน C', foodItem['nutrition']['vitamins']['vitaminC'], 90),
                        buildProgressBar('วิตามิน D', foodItem['nutrition']['vitamins']['vitaminD'], 20),
                        buildProgressBar('วิตามิน E', foodItem['nutrition']['vitamins']['vitaminE'], 15),
                        buildProgressBar('วิตามิน K', foodItem['nutrition']['vitamins']['vitaminK'], 120),
                        
                        SizedBox(height: 10),
                        Text('แร่ธาตุ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                        buildProgressBar('แคลเซียม', foodItem['nutrition']['minerals']['calcium'], 1000),
                        buildProgressBar('โพแทสเซียม', foodItem['nutrition']['minerals']['potassium'], 3500),
                        buildProgressBar('โซเดียม', foodItem['nutrition']['minerals']['sodium'], 2300),
                        buildProgressBar('เหล็ก', foodItem['nutrition']['minerals']['iron'], 18),
                        buildProgressBar('แมกนีเซียม', foodItem['nutrition']['minerals']['magnesium'], 400),
                        
                        SizedBox(height: 10),
                        buildProgressBar('ใยอาหาร', foodItem['nutrition']['fiber'], 25),
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
                          backgroundColor: Colors.blue, 
                        ),
                        onPressed: () async {
                          await addFoodToHistory(context, foodItem);  // เพิ่มอาหารในประวัติ
                          await updateUserEat(context, foodItem['nutrition']['calories']);  // อัปเดต user_eat ใน user_record
                          await updateConsumedCount(context);  // อัปเดต consumed ใน user_consumed

                          // แสดง SnackBar ก่อนปิด dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('เพิ่มอาหารเรียบร้อยแล้ว')),
                          );

                          Navigator.of(context).pop(); // ปิด dialog หลังจากการทำงานเสร็จสิ้น
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
      // ดึง user ID จาก FirebaseAuth
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        String userId = currentUser.uid;

        // บันทึกข้อมูลอาหารลง Firestore พร้อม user_id
        await FirebaseFirestore.instance.collection('user_addFood').add({
          'food_name': foodItem['name'] ?? '-',      // ชื่ออาหาร
          'food_type': foodItem['type'] ?? '-',      // ประเภทอาหาร
          'nutrition': foodItem['nutrition'] ?? {},  // ข้อมูลโภชนาการทั้งหมด
          'added_at': DateTime.now(),                // วันที่และเวลาที่เพิ่ม
          'user_id': userId,                         // user ID ของผู้ใช้ที่ล็อกอิน
          'kcal': foodItem['nutrition']['calories'], // พลังงานที่ได้จากอาหาร
        });
      }
    } catch (e) {
      print("Failed to add food item to history: $e");
    }
  }

  // ฟังก์ชันอัปเดต user_eat ใน collection user_record
  // ฟังก์ชันอัปเดต user_eat ใน collection user_record
Future<void> updateUserEat(BuildContext context, dynamic kcal) async {
  try {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      String userId = currentUser.uid;

      DocumentReference userRecordRef = FirebaseFirestore.instance.collection('user_record').doc(userId);

      // ดึงข้อมูล user_eat ที่มีอยู่
      DocumentSnapshot doc = await userRecordRef.get();
      int currentUserEat = 0;
      if (doc.exists) {
        currentUserEat = doc.get('user_eat') ?? 0;
      }

      int kcalValue = (kcal != null && kcal is String) ? int.parse(kcal) : (kcal ?? 0);

      // Debug print
      print("Current user_eat: $currentUserEat");
      print("Kcal to add: $kcalValue");

      // อัปเดตฟิลด์ 'user_eat'
      await userRecordRef.update({
        'user_eat': currentUserEat + kcalValue,
        'timestamp': Timestamp.now(),  // อัปเดต timestamp ด้วย
      }).then((_) {
        print("Successfully updated user_eat.");
      }).catchError((error) {
        print("Failed to update user_eat: $error");
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

      DocumentReference userConsumedRef = FirebaseFirestore.instance.collection('user_consumed').doc(userId);

      // ดึงข้อมูลปัจจุบัน
      DocumentSnapshot doc = await userConsumedRef.get();
      int currentCount = 0;

      if (doc.exists) {
        // แปลงข้อมูลที่ได้เป็น Map ก่อนใช้ containsKey
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('count')) {
          currentCount = data['count'] ?? 0;
        }
      }

      // อัปเดตหรือสร้างฟิลด์ 'count'
      await userConsumedRef.set({
        'count': currentCount + 1,
        'lastUpdated': Timestamp.now(),  // อัปเดต timestamp ด้วย
      }, SetOptions(merge: true)); // merge = true จะอัปเดตฟิลด์ที่มีอยู่แล้วโดยไม่ลบฟิลด์อื่น ๆ

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('อัปเดต count สำเร็จ')),
      );
    }
  } catch (e) {
    print("Failed to update consumed count: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปเดต count')),
    );
  }
}


  // ฟังก์ชันสร้าง progress bar
  Widget buildProgressBar(String label, dynamic value, double recommended) {
    double? parsedValue = value != null ? double.tryParse(value.toString()) : null;
    double progress = parsedValue != null ? (parsedValue / recommended).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${parsedValue?.toStringAsFixed(1) ?? '-'} (${(progress * 100).toStringAsFixed(1)}%)', style: TextStyle(fontSize: 16)),
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
