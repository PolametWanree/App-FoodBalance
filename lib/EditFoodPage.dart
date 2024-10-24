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

    // ตั้งค่า name และ type ไม่สามารถแก้ไขได้
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
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0), // เพิ่ม padding ให้กับฟอร์ม
              children: [
                // TextField สำหรับชื่ออาหาร ไม่สามารถแก้ไขได้
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'ชื่ออาหาร',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true, // ทำให้ไม่สามารถแก้ไขได้
                ),
                SizedBox(height: 12),
                
                // TextField สำหรับประเภทอาหาร ไม่สามารถแก้ไขได้
                TextFormField(
                  controller: _typeController,
                  decoration: InputDecoration(
                    labelText: 'ประเภทอาหาร',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true, // ทำให้ไม่สามารถแก้ไขได้
                ),
                SizedBox(height: 12),

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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 13, 93, 49), // สีปุ่ม
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // ขอบมน
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(
                    'บันทึก',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0), // ระยะห่างระหว่าง TextField
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), // ขอบมน
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: const Color.fromARGB(255, 13, 93, 49)),
          ),
        ),
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        // ไม่ต้อง validate ถ้าผู้ใช้ไม่ได้พิมพ์ จะถูกแทนที่ด้วย "-"
      ),
    );
  }

  Future<void> _saveChanges() async {
    // ไม่ต้อง validate ค่าในฟิลด์
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
            'calories': _caloriesController.text.isEmpty ? '-' : _caloriesController.text,
            'proteins': _proteinsController.text.isEmpty ? '-' : _proteinsController.text,
            'carbohydrates': _carbohydratesController.text.isEmpty ? '-' : _carbohydratesController.text,
            'fats': _fatsController.text.isEmpty ? '-' : _fatsController.text,
            'fiber': _fiberController.text.isEmpty ? '-' : _fiberController.text,
            'sugar': _sugarController.text.isEmpty ? '-' : _sugarController.text,
            'vitamins': {
              'vitaminA': _vitaminAController.text.isEmpty ? '-' : _vitaminAController.text,
              'vitaminB': _vitaminBController.text.isEmpty ? '-' : _vitaminBController.text,
              'vitaminC': _vitaminCController.text.isEmpty ? '-' : _vitaminCController.text,
              'vitaminD': _vitaminDController.text.isEmpty ? '-' : _vitaminDController.text,
              'vitaminE': _vitaminEController.text.isEmpty ? '-' : _vitaminEController.text,
              'vitaminK': _vitaminKController.text.isEmpty ? '-' : _vitaminKController.text,
            },
            'minerals': {
              'calcium': _calciumController.text.isEmpty ? '-' : _calciumController.text,
              'potassium': _potassiumController.text.isEmpty ? '-' : _potassiumController.text,
              'sodium': _sodiumController.text.isEmpty ? '-' : _sodiumController.text,
              'iron': _ironController.text.isEmpty ? '-' : _ironController.text,
              'magnesium': _magnesiumController.text.isEmpty ? '-' : _magnesiumController.text,
            },
          },
          'added_at': Timestamp.now(),
          'user_id': userId,
        };

        await FirebaseFirestore.instance.collection('user_addFood').add(foodData);

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
