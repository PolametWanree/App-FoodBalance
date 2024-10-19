import 'package:flutter/material.dart';
import 'package:foodbalance4/AddFoodPage.dart';
import 'package:foodbalance4/adminAdd.dart';
import 'exercise_creation_page.dart'; // นำเข้าหน้า ExerciseCreationPage

class AdminScreen extends StatelessWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // นำทางไปยังหน้า AddFoodPage
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddFoodPage()),
                );
              },
              child: const Text('Add Food'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // นำทางไปยังหน้า ExerciseCreationPage
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExerciseCreationPage()),
                );
              },
              child: const Text('Create Exercise'),
            ),
            ElevatedButton(
              onPressed: () {
                // นำทางไปยังหน้า ExerciseCreationPage
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddAllFoodPage()),
                );
              },
              child: const Text('Create Food But All'), 
            ),
          ],
        ),
      ),
    );
  }
}
