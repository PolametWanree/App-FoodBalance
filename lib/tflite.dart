import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:foodbalance4/EditFoodPage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img; // ใช้สำหรับประมวลผลภาพ
import 'package:cloud_firestore/cloud_firestore.dart'; // ใช้สำหรับดึงข้อมูลจาก Firestore
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart'; // ใช้สำหรับดึงข้อมูลผู้ใช้ที่ล็อกอิน


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
    var output = List.filled(48, 0.0).reshape([1, 48]);

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
  Future<void> pickImageFromCamera() async {
  XFile? image = await ImagePicker().pickImage(source: ImageSource.camera);
  if (image != null) {
    await scanImage(image);
  }
}

Future<void> pickImageFromGallery() async {
  XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
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
                      showFoodDetails(foodId); // แสดงรายละเอียดในรูปแบบ dialog แทน
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

Future<String?> _getImageUrl(String imageName) async {
    try {
      String downloadURL = await FirebaseStorage.instance
          .ref(imageName) // ดึง URL ของรูปภาพตามชื่อที่เก็บใน Firestore
          .getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('Error fetching image URL: $e');
      return null;
    }
  }

  // ฟังก์ชันแสดงรายละเอียดอาหารในรูปแบบ Dialog
  void showFoodDetails(String foodId) async {
    DocumentSnapshot docSnapshot = await FirebaseFirestore.instance.collection('food').doc(foodId).get();
    var foodItem = docSnapshot.data() as Map<String, dynamic>;

    String? imageUrl = await _getImageUrl(foodItem['image']);
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 1,
            height: MediaQuery.of(context).size.height * 0.85,
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
                SizedBox(height: 20),
                // แสดงรูปภาพที่ดึงจาก Firebase Storage
                imageUrl != null
                    ? Image.network(imageUrl)
                    : Text('ไม่พบรูปภาพ'),
                SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ชื่ออาหาร: ${foodItem['name'] ?? '-'}',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue),
                        ),
                        Text('ประเภท: ${foodItem['type'] ?? '-'}',
                            style:
                                TextStyle(fontSize: 16, color: Colors.black54)),
                        SizedBox(height: 10),
                        Text('โภชนาการ',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),

                        buildProgressBar(
                            'คาร์โบไฮเดรต',
                            foodItem['nutrition']['carbohydrates'],
                            275),
                        buildProgressBar(
                            'โปรตีน', foodItem['nutrition']['proteins'], 50),
                        buildProgressBar(
                            'ไขมัน', foodItem['nutrition']['fats'], 70),
                        buildProgressBar(
                            'kcal', foodItem['nutrition']['calories'], 2000),
                        buildProgressBar(
                            'น้ำตาล', foodItem['nutrition']['sugar'], 25),
                        SizedBox(height: 10),
                        Text('วิตามิน',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                        buildProgressBar('วิตามิน A',
                            foodItem['nutrition']['vitamins']['vitaminA'], 900),
                        buildProgressBar('วิตามิน B',
                            foodItem['nutrition']['vitamins']['vitaminB'], 2.4),
                        buildProgressBar('วิตามิน C',
                            foodItem['nutrition']['vitamins']['vitaminC'], 90),
                        buildProgressBar('วิตามิน D',
                            foodItem['nutrition']['vitamins']['vitaminD'], 20),
                        buildProgressBar('วิตามิน E',
                            foodItem['nutrition']['vitamins']['vitaminE'], 15),
                        buildProgressBar('วิตามิน K',
                            foodItem['nutrition']['vitamins']['vitaminK'], 120),

                        SizedBox(height: 10),
                        Text('แร่ธาตุ',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                        buildProgressBar('แคลเซียม',
                            foodItem['nutrition']['minerals']['calcium'], 1000),
                        buildProgressBar(
                            'โพแทสเซียม',
                            foodItem['nutrition']['minerals']['potassium'],
                            3500),
                        buildProgressBar('โซเดียม',
                            foodItem['nutrition']['minerals']['sodium'], 2300),
                        buildProgressBar('เหล็ก',
                            foodItem['nutrition']['minerals']['iron'], 18),
                        buildProgressBar('แมกนีเซียม',
                            foodItem['nutrition']['minerals']['magnesium'], 400),

                        SizedBox(height: 10),
                        buildProgressBar(
                            'ใยอาหาร', foodItem['nutrition']['fiber'], 25),
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
                                      backgroundColor: Colors.orangeAccent,
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop(); // ปิด dialog
                                      // นำทางไปยังหน้าแก้ไข
                                      Navigator.of(context).push(MaterialPageRoute(
                                        builder: (context) => EditFoodPage(foodId: foodId),
                                      ));
                                    },
                                    child: Text('แก้ไข', style: TextStyle(color: Colors.white)),
                                  ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        onPressed: () async {
                          await addFoodToHistory(foodItem); // Correct, only foodItem is passed
await updateUserEat(
  FirebaseAuth.instance.currentUser!.uid, // Pass userId instead of context
  foodItem['nutrition']['calories'], 
  foodItem['nutrition']['carbohydrates'], 
  foodItem['nutrition']['proteins'], 
  foodItem['nutrition']['sugar']
); // Correct, passing userId instead of context
                          await updateConsumedCount(); // อัปเดต consumed ใน user_consumed

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('เพิ่มอาหารเรียบร้อยแล้ว')),
                          );

                          Navigator.of(context).pop(); // ปิด dialog
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

// ฟังก์ชันอัปเดตค่า user_eat ใน Firestore
// ฟังก์ชันอัปเดตค่า user_eat ใน Firestore
// อัปเดตฟังก์ชันให้รับค่าทั้งหมด 5 อาร์กิวเมนต์
Future<void> updateUserEat(String userId, dynamic kcal, dynamic carbohydrates, dynamic proteins, dynamic sugar) async {
  try {
    DocumentReference userRecordRef = FirebaseFirestore.instance.collection('user_record').doc(userId);
    DocumentSnapshot userRecordSnapshot = await userRecordRef.get();

    if (userRecordSnapshot.exists) {
      var data = userRecordSnapshot.data() as Map<String, dynamic>;
      int currentUserEat = data['user_eat'] ?? 0;
      int currentCarbohydratesEat = data['carbohydrate_eat'] ?? 0;
      int currentProteinsEat = data['protein_eat'] ?? 0;
      int currentSugarEat = data['sugar_eat'] ?? 0;

      // แปลงค่า kcal, carbohydrates, proteins, และ sugar ให้เป็นตัวเลข
      int kcalValue = (kcal != null && kcal is String) ? int.parse(kcal) : (kcal ?? 0);
      int carbohydratesValue = (carbohydrates != null && carbohydrates is String) ? int.parse(carbohydrates) : (carbohydrates ?? 0);
      int proteinsValue = (proteins != null && proteins is String) ? int.parse(proteins) : (proteins ?? 0);
      int sugarValue = (sugar != null && sugar is String) ? int.parse(sugar) : (sugar ?? 0);

      // อัปเดตค่าลง Firestore
      await userRecordRef.update({
        'user_eat': currentUserEat + kcalValue,
        'carbohydrate_eat': currentCarbohydratesEat + carbohydratesValue,
        'protein_eat': currentProteinsEat + proteinsValue,
        'sugar_eat': currentSugarEat + sugarValue,
        'timestamp': Timestamp.now(),
      });
    }
  } catch (e) {
    print('Error updating user_eat: $e');
  }
}



  // ฟังก์ชันบันทึกข้อมูลอาหารลง Firestore พร้อมแนบวันที่และช่วงเวลา
// ฟังก์ชันบันทึกข้อมูลอาหารลง Firestore พร้อมแนบวันที่และช่วงเวลา
Future<void> addFoodToHistory(Map<String, dynamic> foodItem) async {
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

      // เพิ่มการอัปเดต user_eat ใน user_record
      await updateUserEat(
          userId, 
          foodItem['nutrition']['calories'], 
          foodItem['nutrition']['carbohydrates'], 
          foodItem['nutrition']['proteins'], 
          foodItem['nutrition']['sugar']
        );// ส่งค่า kcal ไปบวกกับค่าเดิม

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เพิ่มอาหารเรียบร้อยแล้ว')),
      );
    } else {
      // กรณีที่ไม่พบผู้ใช้ที่ล็อกอิน
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถดึงข้อมูลผู้ใช้ได้')),
      );
    }
  } catch (e) {
    print('Error adding food: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('เกิดข้อผิดพลาดในการเพิ่มอาหาร')),
    );
  }
}

// ฟังก์ชันบันทึก count ของการเพิ่มอาหารลง Firestore พร้อมแนบวันที่และช่วงเวลา
Future<void> updateConsumedCount() async {
  try {
    // ดึง user ID จาก FirebaseAuth
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      String userId = currentUser.uid;

      // ดึงข้อมูลปัจจุบันจาก Firestore
      DocumentReference userDocRef = FirebaseFirestore.instance.collection('user_consumed').doc(userId);
      DocumentSnapshot userDocSnapshot = await userDocRef.get();

      int currentCount = 0;
      DateTime now = DateTime.now();

      // เช็คว่ามีข้อมูลอยู่ใน Firestore หรือไม่
      if (userDocSnapshot.exists) {
        var data = userDocSnapshot.data() as Map<String, dynamic>;

        // ดึงข้อมูล count และวันที่ที่เก็บไว้
        currentCount = data['count'] ?? 0;
        DateTime lastUpdated = (data['lastUpdated'] as Timestamp).toDate();

        // ถ้าขึ้นวันใหม่จะทำการรีเซ็ต count
        if (now.day != lastUpdated.day || now.month != lastUpdated.month || now.year != lastUpdated.year) {
          currentCount = 0;
        }
      }

      // เพิ่ม count ครั้งละ 1
      currentCount++;

      // บันทึกข้อมูลใหม่ลง Firestore
      await userDocRef.set({
        'count': currentCount,                // จำนวนการกดเพิ่ม
        'lastUpdated': now,                   // วันที่และเวลาที่อัปเดต
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เพิ่มอาหารและนับการบริโภคสำเร็จ')),
      );
    } else {
      // กรณีที่ไม่พบผู้ใช้ที่ล็อกอิน
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถดึงข้อมูลผู้ใช้ได้')),
      );
    }
  } catch (e) {
    print('Error updating consumed count: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('เกิดข้อผิดพลาดในการนับการบริโภค')),
    );
  }
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
              onPressed: pickImageFromCamera,
              child: Text('สแกนภาพจากกล้อง'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: pickImageFromGallery,
              child: Text('เลือกภาพจากแกลเลอรี่'),
            ),
          ],
        ),
      ),
    );
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
          borderRadius: BorderRadius.circular(10),  // ทำขอบมน
          child: Container(
            height: 10,  // ปรับขนาดหลอดให้ใหญ่ขึ้น
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
