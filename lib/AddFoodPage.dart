import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddFoodPage extends StatefulWidget {
  @override
  _AddFoodPageState createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _imageNameController = TextEditingController();

  // เพิ่ม TextEditingController สำหรับข้อมูลโภชนาการ
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _proteinsController = TextEditingController();
  final TextEditingController _fatsController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController(); // เพิ่ม TextEditingController สำหรับแคลอรี่

  // วิตามิน
  final TextEditingController _vitaminAController = TextEditingController();
  final TextEditingController _vitaminBController = TextEditingController();
  final TextEditingController _vitaminCController = TextEditingController();
  final TextEditingController _vitaminDController = TextEditingController();
  final TextEditingController _vitaminEController = TextEditingController();
  final TextEditingController _vitaminKController = TextEditingController();

  // แร่ธาตุ
  final TextEditingController _calciumController = TextEditingController();
  final TextEditingController _potassiumController = TextEditingController();
  final TextEditingController _sodiumController = TextEditingController();
  final TextEditingController _ironController = TextEditingController();
  final TextEditingController _magnesiumController = TextEditingController();

  // ใยอาหาร
  final TextEditingController _fiberController = TextEditingController();

  void _addFood() {
    if (_formKey.currentState!.validate()) {
      FirebaseFirestore.instance.collection('food').add({
        'name': _foodNameController.text.isNotEmpty ? _foodNameController.text : '-',
        'type': _typeController.text.isNotEmpty ? _typeController.text : '-',
        'image': _imageNameController.text.isNotEmpty ? _imageNameController.text : '-',
        'nutrition': {
          'calories': _caloriesController.text.isNotEmpty ? _caloriesController.text : '-', // เพิ่มแคลอรี่
          'carbohydrates': _carbsController.text.isNotEmpty ? _carbsController.text : '-',
          'proteins': _proteinsController.text.isNotEmpty ? _proteinsController.text : '-',
          'fats': _fatsController.text.isNotEmpty ? _fatsController.text : '-',
          'vitamins': {
            'vitaminA': _vitaminAController.text.isNotEmpty ? _vitaminAController.text : '-',
            'vitaminB': _vitaminBController.text.isNotEmpty ? _vitaminBController.text : '-',
            'vitaminC': _vitaminCController.text.isNotEmpty ? _vitaminCController.text : '-',
            'vitaminD': _vitaminDController.text.isNotEmpty ? _vitaminDController.text : '-',
            'vitaminE': _vitaminEController.text.isNotEmpty ? _vitaminEController.text : '-',
            'vitaminK': _vitaminKController.text.isNotEmpty ? _vitaminKController.text : '-',
          },
          'minerals': {
            'calcium': _calciumController.text.isNotEmpty ? _calciumController.text : '-',
            'potassium': _potassiumController.text.isNotEmpty ? _potassiumController.text : '-',
            'sodium': _sodiumController.text.isNotEmpty ? _sodiumController.text : '-',
            'iron': _ironController.text.isNotEmpty ? _ironController.text : '-',
            'magnesium': _magnesiumController.text.isNotEmpty ? _magnesiumController.text : '-',
          },
          'fiber': _fiberController.text.isNotEmpty ? _fiberController.text : '-',
        },
      }).then((value) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('อาหารถูกเพิ่มเรียบร้อย')),
        );
        _clearFields();
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการเพิ่มข้อมูล: $error')),
        );
      });
    }
  }

  void _clearFields() {
    _foodNameController.clear();
    _typeController.clear();
    _carbsController.clear();
    _proteinsController.clear();
    _fatsController.clear();
    _caloriesController.clear(); // เคลียร์ข้อมูลแคลอรี่
    _vitaminAController.clear();
    _vitaminBController.clear();
    _vitaminCController.clear();
    _vitaminDController.clear();
    _vitaminEController.clear();
    _vitaminKController.clear();
    _calciumController.clear();
    _potassiumController.clear();
    _sodiumController.clear();
    _ironController.clear();
    _magnesiumController.clear();
    _fiberController.clear();
    _imageNameController.clear();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เพิ่มข้อมูลอาหาร'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _foodNameController,
                decoration: InputDecoration(labelText: 'ชื่ออาหาร'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกชื่ออาหาร';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _typeController,
                decoration: InputDecoration(labelText: 'ประเภท'),
              ),
              TextFormField(
                controller: _imageNameController,
                decoration: InputDecoration(labelText: 'ชื่อรูปภาพ'),
              ),
              
              Text('ข้อมูลโภชนาการ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _carbsController,
                decoration: InputDecoration(labelText: 'คาร์โบไฮเดรต (g)'),
              ),
              TextFormField(
                controller: _proteinsController,
                decoration: InputDecoration(labelText: 'โปรตีน (g)'),
              ),
              TextFormField(
                controller: _fatsController,
                decoration: InputDecoration(labelText: 'ไขมัน (g)'),
              ),
              TextFormField(
                controller: _caloriesController, // ฟิลด์สำหรับแคลอรี่
                decoration: InputDecoration(labelText: 'แคลอรี่ (kcal)'),
              ),
              Text('วิตามิน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _vitaminAController,
                decoration: InputDecoration(labelText: 'วิตามิน A'),
              ),
              TextFormField(
                controller: _vitaminBController,
                decoration: InputDecoration(labelText: 'วิตามิน B complex'),
              ),
              TextFormField(
                controller: _vitaminCController,
                decoration: InputDecoration(labelText: 'วิตามิน C'),
              ),
              TextFormField(
                controller: _vitaminDController,
                decoration: InputDecoration(labelText: 'วิตามิน D'),
              ),
              TextFormField(
                controller: _vitaminEController,
                decoration: InputDecoration(labelText: 'วิตามิน E'),
              ),
              TextFormField(
                controller: _vitaminKController,
                decoration: InputDecoration(labelText: 'วิตามิน K'),
              ),
              Text('แร่ธาตุ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _calciumController,
                decoration: InputDecoration(labelText: 'แคลเซียม (mg)'),
              ),
              TextFormField(
                controller: _potassiumController,
                decoration: InputDecoration(labelText: 'โพแทสเซียม (mg)'),
              ),
              TextFormField(
                controller: _sodiumController,
                decoration: InputDecoration(labelText: 'โซเดียม (mg)'),
              ),
              TextFormField(
                controller: _ironController,
                decoration: InputDecoration(labelText: 'เหล็ก (mg)'),
              ),
              TextFormField(
                controller: _magnesiumController,
                decoration: InputDecoration(labelText: 'แมกนีเซียม (mg)'),
              ),
              TextFormField(
                controller: _fiberController,
                decoration: InputDecoration(labelText: 'ใยอาหาร (g)'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addFood,
                child: Text('เพิ่มอาหาร'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
