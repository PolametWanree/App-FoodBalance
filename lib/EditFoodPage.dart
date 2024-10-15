import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditFoodPage extends StatefulWidget {
  final String foodId;

  EditFoodPage({required this.foodId});

  @override
  _EditFoodPageState createState() => _EditFoodPageState();
}

class _EditFoodPageState extends State<EditFoodPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _typeController = TextEditingController();
  TextEditingController _caloriesController = TextEditingController();
  TextEditingController _proteinsController = TextEditingController();
  TextEditingController _carbohydratesController = TextEditingController();
  TextEditingController _fatsController = TextEditingController();
  TextEditingController _sugarController = TextEditingController();
  TextEditingController _fiberController = TextEditingController();

  // เพิ่ม TextEditingController สำหรับ vitamins และ minerals
  TextEditingController _vitaminAController = TextEditingController();
  TextEditingController _vitaminBController = TextEditingController();
  TextEditingController _vitaminCController = TextEditingController();
  TextEditingController _vitaminDController = TextEditingController();
  TextEditingController _vitaminEController = TextEditingController();
  TextEditingController _vitaminKController = TextEditingController();
  TextEditingController _calciumController = TextEditingController();
  TextEditingController _potassiumController = TextEditingController();
  TextEditingController _sodiumController = TextEditingController();
  TextEditingController _ironController = TextEditingController();
  TextEditingController _magnesiumController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFoodData(); // ดึงข้อมูลจาก Firestore
  }

  Future<void> _loadFoodData() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('food')
        .doc(widget.foodId)
        .get();
    var foodItem = doc.data() as Map<String, dynamic>;

    _nameController.text = foodItem['name'] ?? '';
    _typeController.text = foodItem['type'] ?? '';
    _caloriesController.text = foodItem['nutrition']['calories'].toString();
    _proteinsController.text = foodItem['nutrition']['proteins'].toString();
    _carbohydratesController.text = foodItem['nutrition']['carbohydrates'].toString();
    _fatsController.text = foodItem['nutrition']['fats'].toString();
    _sugarController.text = foodItem['nutrition']['sugar'].toString();
    _fiberController.text = foodItem['nutrition']['fiber'].toString();

    // ดึงข้อมูล vitamins และ minerals
    _vitaminAController.text = foodItem['nutrition']['vitamins']['vitaminA'].toString();
    _vitaminBController.text = foodItem['nutrition']['vitamins']['vitaminB'].toString();
    _vitaminCController.text = foodItem['nutrition']['vitamins']['vitaminC'].toString();
    _vitaminDController.text = foodItem['nutrition']['vitamins']['vitaminD'] ?? "-";
    _vitaminEController.text = foodItem['nutrition']['vitamins']['vitaminE'].toString();
    _vitaminKController.text = foodItem['nutrition']['vitamins']['vitaminK'].toString();

    _calciumController.text = foodItem['nutrition']['minerals']['calcium'].toString();
    _potassiumController.text = foodItem['nutrition']['minerals']['potassium'].toString();
    _sodiumController.text = foodItem['nutrition']['minerals']['sodium'].toString();
    _ironController.text = foodItem['nutrition']['minerals']['iron'].toString();
    _magnesiumController.text = foodItem['nutrition']['minerals']['magnesium'].toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('แก้ไขข้อมูลอาหาร'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_nameController, 'ชื่ออาหาร'),
              _buildTextField(_typeController, 'ประเภทอาหาร'),
              _buildTextField(_caloriesController, 'แคลอรี่', isNumeric: true),
              _buildTextField(_proteinsController, 'โปรตีน (g)', isNumeric: true),
              _buildTextField(_carbohydratesController, 'คาร์โบไฮเดรต (g)', isNumeric: true),
              _buildTextField(_fatsController, 'ไขมัน (g)', isNumeric: true),
              _buildTextField(_sugarController, 'น้ำตาล (g)', isNumeric: true),
              _buildTextField(_fiberController, 'ใยอาหาร (g)', isNumeric: true),

              // เพิ่มส่วน vitamins
              Text('วิตามิน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildTextField(_vitaminAController, 'วิตามิน A (µg)', isNumeric: true),
              _buildTextField(_vitaminBController, 'วิตามิน B (mg)', isNumeric: true),
              _buildTextField(_vitaminCController, 'วิตามิน C (mg)', isNumeric: true),
              _buildTextField(_vitaminDController, 'วิตามิน D (µg)', isNumeric: false),  // แก้ให้สามารถกรอก "-"
              _buildTextField(_vitaminEController, 'วิตามิน E (mg)', isNumeric: true),
              _buildTextField(_vitaminKController, 'วิตามิน K (µg)', isNumeric: true),

              // เพิ่มส่วน minerals
              Text('แร่ธาตุ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildTextField(_calciumController, 'แคลเซียม (mg)', isNumeric: true),
              _buildTextField(_potassiumController, 'โพแทสเซียม (mg)', isNumeric: true),
              _buildTextField(_sodiumController, 'โซเดียม (mg)', isNumeric: true),
              _buildTextField(_ironController, 'เหล็ก (mg)', isNumeric: true),
              _buildTextField(_magnesiumController, 'แมกนีเซียม (mg)', isNumeric: true),

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveChanges,
                child: Text('บันทึก'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumeric = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'กรุณากรอก $label';
        }
        return null;
      },
    );
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      try {
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          String userId = currentUser.uid;

          // เพิ่มข้อมูลอาหารเข้าไปใน user_addFood
          Map<String, dynamic> foodData = {
            'food_name': _nameController.text,
            'food_type': _typeController.text,
            'kcal': _caloriesController.text, // บันทึก kcal เป็น string
            'nutrition': {
              'calories': _caloriesController.text,
              'proteins': _proteinsController.text,
              'carbohydrates': _carbohydratesController.text,
              'fats': _fatsController.text,
              'fiber': _fiberController.text,
              'sugar': _sugarController.text,
              'vitamins': {
                'vitaminA': _vitaminAController.text,
                'vitaminB': _vitaminBController.text,
                'vitaminC': _vitaminCController.text,
                'vitaminD': _vitaminDController.text,
                'vitaminE': _vitaminEController.text,
                'vitaminK': _vitaminKController.text,
              },
              'minerals': {
                'calcium': _calciumController.text,
                'potassium': _potassiumController.text,
                'sodium': _sodiumController.text,
                'iron': _ironController.text,
                'magnesium': _magnesiumController.text,
              },
            },
            'added_at': Timestamp.now(),
            'user_id': userId,
          };

          await FirebaseFirestore.instance.collection('user_addFood').add(foodData);

          // อัปเดตค่า user_eat, carbohydrate_eat, protein_eat, และ sugar_eat ใน user_record
          await updateUserEat(context, _caloriesController.text, _carbohydratesController.text, _proteinsController.text, _sugarController.text);

          // อัปเดตค่า consumed ใน user_consumed
          await updateConsumedCount(context);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('บันทึกข้อมูลเรียบร้อย')),
          );

          Navigator.of(context).pop();
        }
      } catch (e) {
        print("Failed to save food item: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล')),
        );
      }
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
}
