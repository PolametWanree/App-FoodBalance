import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FoodManagementPage extends StatefulWidget {
  @override
  _FoodManagementPageState createState() => _FoodManagementPageState();
}

class _FoodManagementPageState extends State<FoodManagementPage> {
  TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Food Management"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                labelText: 'Search Food...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: (searchQuery.isEmpty)
                  ? FirebaseFirestore.instance.collection('food').snapshots()
                  : FirebaseFirestore.instance
                      .collection('food')
                      .where('name', isGreaterThanOrEqualTo: searchQuery)
                      .where('name', isLessThanOrEqualTo: searchQuery + '\uf8ff')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final foodItems = snapshot.data!.docs;

                if (foodItems.isEmpty) {
                  return Center(child: Text("No food items found."));
                }

                return ListView.builder(
                  itemCount: foodItems.length,
                  itemBuilder: (context, index) {
                    var foodItem = foodItems[index].data() as Map<String, dynamic>;

                    return FutureBuilder<String?>(
                      future: _getImageUrl(foodItem['image'] ?? ''),
                      builder: (context, snapshot) {
                        String? imageUrl = snapshot.data;

                        return Card(
                          margin: EdgeInsets.all(8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 3,
                          child: ListTile(
                            leading: imageUrl != null
                                ? Image.network(
                                    imageUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
                                : Icon(Icons.image, size: 50),
                            title: Text(foodItem['name'] ?? '-'),
                            subtitle: Text.rich(
                              TextSpan(
                                text: 'Calories: ',
                                style: TextStyle(color: Colors.black),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: '${foodItem['nutrition'] != null ? foodItem['nutrition']['calories'] ?? '-' : '-'}',
                                    style: TextStyle(color: Colors.green),
                                  ),
                                ],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    _editFoodItem(context, foodItems[index].id, foodItem);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _deleteFoodItem(context, foodItems[index].id);
                                  },
                                ),
                              ],
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
          ),
        ],
      ),
    );
  }

  Future<String?> _getImageUrl(String imageName) async {
    try {
      String downloadURL = await FirebaseStorage.instance
          .ref(imageName)
          .getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('Error fetching image URL: $e');
      return null;
    }
  }

  // ฟังก์ชันแก้ไขข้อมูลอาหาร พร้อมฟิลด์ที่ครบถ้วน
  void _editFoodItem(BuildContext context, String foodId, Map<String, dynamic> foodItem) {
  TextEditingController _nameController = TextEditingController(text: foodItem['name']);
  TextEditingController _caloriesController = TextEditingController(text: foodItem['nutrition']?['calories']?.toString() ?? '0');
  TextEditingController _carbohydratesController = TextEditingController(text: foodItem['nutrition']?['carbohydrates'] ?? '0');
  TextEditingController _fatsController = TextEditingController(text: foodItem['nutrition']?['fats'] ?? '0');
  TextEditingController _fiberController = TextEditingController(text: foodItem['nutrition']?['fiber'] ?? '0');
  TextEditingController _sugarController = TextEditingController(text: foodItem['nutrition']?['sugar'] ?? '0');
  TextEditingController _proteinsController = TextEditingController(text: foodItem['nutrition']?['proteins'] ?? '0');
  TextEditingController _calciumController = TextEditingController(text: foodItem['nutrition']?['minerals']?['calcium'] ?? '0');
  TextEditingController _ironController = TextEditingController(text: foodItem['nutrition']?['minerals']?['iron'] ?? '0');
  TextEditingController _magnesiumController = TextEditingController(text: foodItem['nutrition']?['minerals']?['magnesium'] ?? '0');
  TextEditingController _potassiumController = TextEditingController(text: foodItem['nutrition']?['minerals']?['potassium'] ?? '0');
  TextEditingController _sodiumController = TextEditingController(text: foodItem['nutrition']?['minerals']?['sodium'] ?? '0');
  TextEditingController _vitaminAController = TextEditingController(text: foodItem['nutrition']?['vitamins']?['vitaminA'] ?? '0');
  TextEditingController _vitaminBController = TextEditingController(text: foodItem['nutrition']?['vitamins']?['vitaminB'] ?? '0');
  TextEditingController _vitaminCController = TextEditingController(text: foodItem['nutrition']?['vitamins']?['vitaminC'] ?? '0');
  TextEditingController _vitaminDController = TextEditingController(text: foodItem['nutrition']?['vitamins']?['vitaminD'] ?? '0');
  TextEditingController _vitaminEController = TextEditingController(text: foodItem['nutrition']?['vitamins']?['vitaminE'] ?? '0');
  TextEditingController _vitaminKController = TextEditingController(text: foodItem['nutrition']?['vitamins']?['vitaminK'] ?? '0');

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Edit Food Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField('Food Name', _nameController),
              _buildTextField('Calories', _caloriesController),
              _buildTextField('Carbohydrates', _carbohydratesController),
              _buildTextField('Fats', _fatsController),
              _buildTextField('Fiber', _fiberController),
              _buildTextField('Sugar', _sugarController),
              _buildTextField('Proteins', _proteinsController),
              _buildTextField('Calcium', _calciumController),
              _buildTextField('Iron', _ironController),
              _buildTextField('Magnesium', _magnesiumController),
              _buildTextField('Potassium', _potassiumController),
              _buildTextField('Sodium', _sodiumController),
              _buildTextField('Vitamin A', _vitaminAController),
              _buildTextField('Vitamin B', _vitaminBController),
              _buildTextField('Vitamin C', _vitaminCController),
              _buildTextField('Vitamin D', _vitaminDController),
              _buildTextField('Vitamin E', _vitaminEController),
              _buildTextField('Vitamin K', _vitaminKController),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: Text('Save'),
            onPressed: () {
              _saveFoodItem(
                foodId,
                _nameController.text,
                _caloriesController.text,
                _carbohydratesController.text,
                _fatsController.text,
                _fiberController.text,
                _sugarController.text,
                _proteinsController.text,
                _calciumController.text,
                _ironController.text,
                _magnesiumController.text,
                _potassiumController.text,
                _sodiumController.text,
                _vitaminAController.text,
                _vitaminBController.text,
                _vitaminCController.text,
                _vitaminDController.text,
                _vitaminEController.text,
                _vitaminKController.text,
              );
              Navigator.pop(context);
            },
          ),
        ],
      );
    },
  );
}


  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
        ),
      ),
    );
  }

  // ฟังก์ชันบันทึกการแก้ไขกลับไปยัง Firestore
  Future<void> _saveFoodItem(
      String foodId,
      String name,
      String calories,
      String carbohydrates,
      String fats,
      String fiber,
      String sugar,
      String proteins,
      String calcium,
      String iron,
      String magnesium,
      String potassium,
      String sodium,
      String vitaminA,
      String vitaminB,
      String vitaminC,
      String vitaminD,
      String vitaminE,
      String vitaminK) async {
    try {
      await FirebaseFirestore.instance.collection('food').doc(foodId).update({
        'name': name,
        'nutrition.calories': int.tryParse(calories) ?? 0,
        'nutrition.carbohydrates': carbohydrates,
        'nutrition.fats': fats,
        'nutrition.fiber': fiber,
        'nutrition.sugar': sugar,
        'nutrition.proteins': proteins,
        'minerals.calcium': calcium,
        'minerals.iron': iron,
        'minerals.magnesium': magnesium,
        'minerals.potassium': potassium,
        'minerals.sodium': sodium,
        'vitamins.vitaminA': vitaminA,
        'vitamins.vitaminB': vitaminB,
        'vitamins.vitaminC': vitaminC,
        'vitamins.vitaminD': vitaminD,
        'vitamins.vitaminE': vitaminE,
        'vitamins.vitaminK': vitaminK,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Food item updated successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update food item: $e')));
    }
  }

  void _deleteFoodItem(BuildContext context, String foodId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Food Item'),
          content: Text('Are you sure you want to delete this food item?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                _confirmDeleteFoodItem(foodId);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteFoodItem(String foodId) async {
    try {
      await FirebaseFirestore.instance.collection('food').doc(foodId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Food item deleted successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete food item: $e')));
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
            padding: EdgeInsets.all(15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Food Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                imageUrl != null
                    ? Image.network(imageUrl)
                    : Text('Image not found'),
                SizedBox(height: 16),
                Text('Name: ${foodItem['name'] ?? '-'}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Type: ${foodItem['type'] ?? '-'}',
                    style: TextStyle(fontSize: 16, color: Colors.black54)),
                SizedBox(height: 10),
                Text('Nutrition Info',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green)),
                Text('Calories: ${foodItem['nutrition']['calories'] ?? '-'}'),
                Text('Carbohydrates: ${foodItem['nutrition']['carbohydrates'] ?? '-'}'),
                Text('Proteins: ${foodItem['nutrition']['proteins'] ?? '-'}'),
                Text('Fats: ${foodItem['nutrition']['fats'] ?? '-'}'),
                SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}
