import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FoodDetailPage(foodId: foodItems[index].id),
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
}

class FoodDetailPage extends StatelessWidget {
  final String foodId;

  FoodDetailPage({required this.foodId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียดอาหาร'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('food').doc(foodId).get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          var foodItem = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ชื่ออาหาร: ${foodItem['name'] ?? '-'}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('ประเภท: ${foodItem['type'] ?? '-'}', style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                Text('โภชนาการ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('คาร์โบไฮเดรต: ${foodItem['nutrition']['carbohydrates'] ?? '-'} g'),
                Text('โปรตีน: ${foodItem['nutrition']['proteins'] ?? '-'} g'),
                Text('ไขมัน: ${foodItem['nutrition']['fats'] ?? '-'} g'),
                SizedBox(height: 10),
                Text('วิตามิน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('วิตามิน A: ${foodItem['nutrition']['vitamins']['vitaminA'] ?? '-'}'),
                Text('วิตามิน B: ${foodItem['nutrition']['vitamins']['vitaminB'] ?? '-'}'),
                Text('วิตามิน C: ${foodItem['nutrition']['vitamins']['vitaminC'] ?? '-'}'),
                Text('วิตามิน D: ${foodItem['nutrition']['vitamins']['vitaminD'] ?? '-'}'),
                Text('วิตามิน E: ${foodItem['nutrition']['vitamins']['vitaminE'] ?? '-'}'),
                Text('วิตามิน K: ${foodItem['nutrition']['vitamins']['vitaminK'] ?? '-'}'),
                SizedBox(height: 10),
                Text('แร่ธาตุ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('แคลเซียม: ${foodItem['nutrition']['minerals']['calcium'] ?? '-'} mg'),
                Text('โพแทสเซียม: ${foodItem['nutrition']['minerals']['potassium'] ?? '-'} mg'),
                Text('โซเดียม: ${foodItem['nutrition']['minerals']['sodium'] ?? '-'} mg'),
                Text('เหล็ก: ${foodItem['nutrition']['minerals']['iron'] ?? '-'} mg'),
                Text('แมกนีเซียม: ${foodItem['nutrition']['minerals']['magnesium'] ?? '-'} mg'),
                SizedBox(height: 10),
                Text('ใยอาหาร: ${foodItem['nutrition']['fiber'] ?? '-'} g'),
              ],
            ),
          );
        },
      ),
    );
  }
}
