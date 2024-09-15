import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img; // ใช้สำหรับประมวลผลภาพ
import 'package:cloud_firestore/cloud_firestore.dart'; // ใช้สำหรับดึงข้อมูลจาก Firestore
import 'dart:io';

class ImageScannerPage extends StatefulWidget {
  @override
  _ImageScannerPageState createState() => _ImageScannerPageState();
}

class _ImageScannerPageState extends State<ImageScannerPage> {
  Interpreter? interpreter;
  List<String> labels = []; // ป้ายชื่อจาก labels.txt
  String? resultText;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadModelAndLabels(); // โหลดโมเดลและ labels เมื่อหน้าเริ่มทำงาน
  }

  // โหลดโมเดลและ labels
  Future<void> loadModelAndLabels() async {
    try {
      // โหลดโมเดล
      interpreter = await Interpreter.fromAsset('assets/tflite/model_unquant.tflite');
      print('Model loaded successfully');

      // โหลด labels
      String labelsData = await DefaultAssetBundle.of(context).loadString('assets/tflite/labels.txt');
      labels = labelsData.split('\n');
      print('Labels loaded successfully');
    } catch (e) {
      print('Failed to load model or labels: $e');
    }
  }

  // ฟังก์ชันสแกนภาพ
  Future<void> scanImage(XFile imageFile) async {
    setState(() {
      isLoading = true;
    });

    // โหลดภาพและแปลงเป็น byte data
    Uint8List imageBytes = await imageFile.readAsBytes();

    // Process the image data here (resize, normalize, etc.) as required by the model.
    var inputImage = _processImage(imageBytes);

    // Prepare output buffer สำหรับโมเดลที่มีคลาส 3
    var output = List.filled(3, 0.0).reshape([1, 3]);

    // Run the model if interpreter is available
    if (interpreter != null) {
      interpreter!.run(inputImage, output);
    }

    // ตรวจสอบผลลัพธ์จากโมเดล
    print('Model output: $output');

    // Find the index of the highest probability using manual comparison
    int maxIndex = 0;
    double maxValue = output[0][0];
    for (int i = 1; i < output[0].length; i++) {
      if (output[0][i] > maxValue) {
        maxValue = output[0][i];
        maxIndex = i;
      }
    }

    // Set the result text
    String predictedFood = labels[maxIndex];
    setState(() {
      resultText = predictedFood;
      isLoading = false;
    });

    // เช็คข้อมูลใน Firestore
    checkFoodInFirestore(predictedFood);
  }

  // ฟังก์ชันแปลงภาพและทำการ preprocessing
  List<List<List<List<double>>>> _processImage(Uint8List imageBytes) {
    img.Image? image = img.decodeImage(imageBytes);

    // Resize the image to 224x224 (assumed model input size)
    img.Image resizedImage = img.copyResize(image!, width: 224, height: 224);

    List<List<List<List<double>>>> input = List.generate(1, (i) =>
      List.generate(224, (y) =>
        List.generate(224, (x) {
          img.Pixel pixel = resizedImage.getPixel(x, y);
          return [
            pixel.r.toDouble() / 255.0,
            pixel.g.toDouble() / 255.0,
            pixel.b.toDouble() / 255.0
          ];
        })
      )
    );

    return input;
  }

  // ฟังก์ชันเลือกหรือถ่ายภาพ
  Future<void> pickImage() async {
    XFile? image = await ImagePicker().pickImage(source: ImageSource.camera);
    if (image != null) {
      await scanImage(image);
    }
  }

  // เช็คว่าชื่ออาหารที่สแกนตรงกับข้อมูลใน Firestore หรือไม่
  Future<void> checkFoodInFirestore(String predictedFood) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('food')
        .where('name', isEqualTo: predictedFood)
        .get();

    if (snapshot.docs.isNotEmpty) {
      // ถ้าพบข้อมูลอาหารใน Firestore
      showFoodConfirmation(snapshot.docs.first.id, predictedFood);
    } else {
      // ถ้าไม่พบข้อมูล
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่พบข้อมูลในฐานข้อมูล')),
      );
    }
  }

  // แสดงข้อความสไลด์เพื่อสอบถามว่าผู้ใช้ต้องการยืนยันหรือไม่
  void showFoodConfirmation(String foodId, String foodName) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('อาหารจากภาพคือ "$foodName" ใช่หรือไม่?'),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, // Set the button color to green
                      ),
                      onPressed: () {
                        Navigator.pop(context); // ปิด BottomSheet
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FoodDetailPage(foodId: foodId),
                          ),
                        );
                      },
                        child: Text(
                        'ใช่',
                        style: TextStyle(color: Colors.white),
                        ),
                    ),
                    TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red, // Set the button color to red
                    ),
                    onPressed: () {
                      Navigator.pop(context); // ปิด BottomSheet
                    },
                    child: Text(
                      'ไม่ใช่',
                      style: TextStyle(color: Colors.white),
                    ),
                    ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Food Scanner'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) CircularProgressIndicator(),
            if (resultText != null)
              Text(
                'ผลลัพธ์: $resultText',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: pickImage,
              child: Text('สแกนภาพจากกล้อง'),
            ),
          ],
        ),
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
