import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FoodHistoryPage extends StatefulWidget {
  @override
  _FoodHistoryPageState createState() => _FoodHistoryPageState();
}

class _FoodHistoryPageState extends State<FoodHistoryPage> {
  Future<List<Map<String, dynamic>>> fetchFoodHistory() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      String userId = currentUser.uid;

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('user_food_history')
          .where('user_id', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Food Consumption History"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Your food consumption history",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchFoodHistory(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error loading data"));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text("No food history available"));
                  }

                  List<Map<String, dynamic>> foodHistory = snapshot.data!;

                  return ListView.builder(
                    shrinkWrap: true, // Ensures it fits within the container
                    physics: NeverScrollableScrollPhysics(), // Disable scrolling inside ListView
                    itemCount: foodHistory.length,
                    itemBuilder: (context, index) {
                      var foodItem = foodHistory[index];
                      return ListTile(
                        title: Text(foodItem['food_name']),
                        subtitle: Text(
                          "Calories: ${foodItem['calories']} kcal, Proteins: ${foodItem['proteins']} g, Carbs: ${foodItem['carbohydrates']} g",
                        ),
                        trailing: Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(foodItem['timestamp'].toDate()),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: FoodHistoryPage(),
  ));
}
