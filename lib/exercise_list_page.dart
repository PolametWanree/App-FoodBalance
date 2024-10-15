import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExerciseListPage extends StatefulWidget {
  const ExerciseListPage({Key? key}) : super(key: key);

  @override
  _ExerciseListPageState createState() => _ExerciseListPageState();
}

// ฟังก์ชันอัปเดต burned ใน collection user_burned
Future<void> updateBurnedCount(BuildContext context) async {
  try {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      String userId = currentUser.uid;

      DocumentReference userBurnedRef =
          FirebaseFirestore.instance.collection('user_burned').doc(userId);

      DocumentSnapshot doc = await userBurnedRef.get();
      int currentBurnedCount = 0;

      if (doc.exists) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('burned')) {
          currentBurnedCount = data['burned'] ?? 0;
        }
      }

      await userBurnedRef.set({
        'burned': currentBurnedCount + 1, // เพิ่มค่า burned ทีละ 1
        'lastUpdated': Timestamp.now(), // เก็บเวลาปัจจุบัน
      }, SetOptions(merge: true));
    }
  } catch (e) {
    print("Failed to update burned count: $e");
  }
}


class _ExerciseListPageState extends State<ExerciseListPage> {
  // ฟังก์ชันสำหรับการอัปเดตการลบ user_eat ใน Firestore โดยใช้ auth แทน userId
  Future<void> _subtractUserEat(double caloriesBurn) async {
    try {
      // ดึงผู้ใช้ที่ล็อกอินอยู่ใน FirebaseAuth
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        // ถ้าไม่มีผู้ใช้ที่ล็อกอินอยู่
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      // ใช้ `user.uid` จากการ auth แทน userId
      String uid = user.uid;

      // ดึงข้อมูลปัจจุบันของ `user_eat` จาก Firestore โดยใช้ `uid`
      DocumentSnapshot userRecord = await FirebaseFirestore.instance
          .collection('user_record')
          .doc(uid) // ใช้ `uid` แทน `userId`
          .get();

      if (userRecord.exists) {
        int currentEat = (userRecord.data() as Map<String, dynamic>)['user_eat']?.toInt() ?? 0;

        // แปลง caloriesBurn เป็นจำนวนเต็มก่อนลบ
        int caloriesBurnInt = caloriesBurn.toInt();

        // ตรวจสอบว่าค่าที่ลบจะไม่ต่ำกว่า 0
        int newEatValue = currentEat - caloriesBurnInt;
        if (newEatValue < 0) {
          newEatValue = 0; // ป้องกันไม่ให้ค่าติดลบ
        }

        // อัปเดตค่าลบใน `user_eat`
        await FirebaseFirestore.instance.collection('user_record').doc(uid).update({
          'user_eat': newEatValue,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully subtracted $caloriesBurnInt kcal from user_eat')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User record not found')),
        );
      }
    } catch (e) {
      print("Failed to update user_eat: $e"); // แสดงผลในคอนโซล
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update user_eat')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise List'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('exercises').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error occurred!'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final exercises = snapshot.data!.docs;

          if (exercises.isEmpty) {
            return const Center(child: Text('No exercises found.'));
          }

          return ListView.builder(
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              var exercise = exercises[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: ListTile(
                  title: Text(exercise['exercise_name'] ?? 'No Name'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Calories Burn: ${exercise['calories_burn']} kcal'),
                      Text('Duration: ${exercise['duration']} minutes'),
                      Text('Difficulty: ${exercise['difficulty_level']}'),
                    ],
                  ),
                  trailing: IconButton(
                      icon: const Icon(Icons.add), // ปุ่ม + สำหรับการลบ calories_burn กับ user_eat
                      onPressed: () {
                        double caloriesBurn = exercise['calories_burn'];
                        _subtractUserEat(caloriesBurn); // อัปเดตการลบค่าจาก user_eat
                        updateBurnedCount(context); // เพิ่มการเรียกฟังก์ชันอัปเดต burned หลังจากการลบ user_eat
                      },
                    ),

                ),
              );
            },
          );
        },
      ),
    );
  }
}

