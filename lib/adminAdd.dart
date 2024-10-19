import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddAllFoodPage extends StatefulWidget {
  @override
  _AddAllFoodPageState createState() => _AddAllFoodPageState();
}

class _AddAllFoodPageState extends State<AddAllFoodPage> {
  final List<Map<String, dynamic>> foodList = [
    {
      'name': 'แกงเขียวหวาน',
      'image': 'แกงเขียวหวาน.jpg',
      'nutrition': {
        'calories': '450',
        'carbohydrates': '18',
        'proteins': '25',
        'fats': '35',
        'fiber': '4',
        'sugar': '7',
        'minerals': {
          'calcium': '60',
          'iron': '2',
          'magnesium': '40',
          'potassium': '250',
          'sodium': '850',
        },
        'vitamins': {
          'vitaminA': '100',
          'vitaminB': '0.4',
          'vitaminC': '5',
          'vitaminD': '-',
          'vitaminE': '1',
          'vitaminK': '10',
        },
      }
    },
    {
      'name': 'แกงเทโพ',
      'image': 'แกงเทโพ.jpg',
      'nutrition': {
        'calories': '300',
        'carbohydrates': '15',
        'proteins': '18',
        'fats': '22',
        'fiber': '5',
        'sugar': '6',
        'minerals': {
          'calcium': '40',
          'iron': '1',
          'magnesium': '30',
          'potassium': '150',
          'sodium': '700',
        },
        'vitamins': {
          'vitaminA': '50',
          'vitaminB': '0.3',
          'vitaminC': '3',
          'vitaminD': '-',
          'vitaminE': '0.5',
          'vitaminK': '5',
        },
      }
    },
    {
      'name': 'แกงเลียง',
      'image': 'แกงเลียง.jpg',
      'nutrition': {
        'calories': '150',
        'carbohydrates': '12',
        'proteins': '10',
        'fats': '5',
        'fiber': '4',
        'sugar': '3',
        'minerals': {
          'calcium': '80',
          'iron': '1.5',
          'magnesium': '35',
          'potassium': '200',
          'sodium': '550',
        },
        'vitamins': {
          'vitaminA': '80',
          'vitaminB': '0.2',
          'vitaminC': '4',
          'vitaminD': '-',
          'vitaminE': '0.3',
          'vitaminK': '7',
        },
      }
    },
    {
      'name': 'แกงจืดเต้าหู้หมูสับ',
      'image': 'แกงจืดเต้าหู้หมูสับ.jpg',
      'nutrition': {
        'calories': '180',
        'carbohydrates': '8',
        'proteins': '15',
        'fats': '10',
        'fiber': '2',
        'sugar': '2',
        'minerals': {
          'calcium': '50',
          'iron': '1',
          'magnesium': '20',
          'potassium': '150',
          'sodium': '600',
        },
        'vitamins': {
          'vitaminA': '60',
          'vitaminB': '0.3',
          'vitaminC': '3',
          'vitaminD': '-',
          'vitaminE': '0.3',
          'vitaminK': '5',
        },
      }
    },
    {
      'name': 'แกงจืดมะระยัดไส้',
      'image': 'แกงจืดมะระยัดไส้.jpg',
      'nutrition': {
        'calories': '170',
        'carbohydrates': '7',
        'proteins': '14',
        'fats': '8',
        'fiber': '3',
        'sugar': '2',
        'minerals': {
          'calcium': '45',
          'iron': '1.2',
          'magnesium': '25',
          'potassium': '160',
          'sodium': '620',
        },
        'vitamins': {
          'vitaminA': '65',
          'vitaminB': '0.3',
          'vitaminC': '3',
          'vitaminD': '-',
          'vitaminE': '0.3',
          'vitaminK': '6',
        },
      }
    },
    {
      'name': 'แกงมัสมั่นไก่',
      'image': 'แกงมัสมั่นไก่.jpg',
      'nutrition': {
        'calories': '550',
        'carbohydrates': '22',
        'proteins': '35',
        'fats': '38',
        'fiber': '3',
        'sugar': '8',
        'minerals': {
          'calcium': '55',
          'iron': '2.5',
          'magnesium': '50',
          'potassium': '300',
          'sodium': '750',
        },
        'vitamins': {
          'vitaminA': '90',
          'vitaminB': '0.4',
          'vitaminC': '5',
          'vitaminD': '-',
          'vitaminE': '1',
          'vitaminK': '9',
        },
      }
    },
    {
      'name': 'แกงส้มชะอมไข่',
      'image': 'แกงส้มชะอมไข่.jpg',
      'nutrition': {
        'calories': '220',
        'carbohydrates': '10',
        'proteins': '12',
        'fats': '15',
        'fiber': '4',
        'sugar': '4',
        'minerals': {
          'calcium': '45',
          'iron': '1.5',
          'magnesium': '30',
          'potassium': '160',
          'sodium': '800',
        },
        'vitamins': {
          'vitaminA': '70',
          'vitaminB': '0.3',
          'vitaminC': '4',
          'vitaminD': '-',
          'vitaminE': '0.3',
          'vitaminK': '6',
        },
      }
    },
    {
      'name': 'ไก่ผัดเม็ดมะม่วงหิมพานต์',
      'image': 'ไก่ผัดเม็ดมะม่วงหิมพานต์.jpg',
      'nutrition': {
        'calories': '450',
        'carbohydrates': '20',
        'proteins': '30',
        'fats': '28',
        'fiber': '5',
        'sugar': '6',
        'minerals': {
          'calcium': '55',
          'iron': '2.2',
          'magnesium': '40',
          'potassium': '300',
          'sodium': '750',
        },
        'vitamins': {
          'vitaminA': '80',
          'vitaminB': '0.4',
          'vitaminC': '6',
          'vitaminD': '-',
          'vitaminE': '1',
          'vitaminK': '8',
        },
      }
    },
    {
      'name': 'ไข่เจียว',
      'image': 'ไข่เจียว.jpg',
      'nutrition': {
        'calories': '250',
        'carbohydrates': '1',
        'proteins': '12',
        'fats': '20',
        'fiber': '0',
        'sugar': '1',
        'minerals': {
          'calcium': '30',
          'iron': '1.5',
          'magnesium': '15',
          'potassium': '100',
          'sodium': '400',
        },
        'vitamins': {
          'vitaminA': '60',
          'vitaminB': '0.3',
          'vitaminC': '0',
          'vitaminD': '-',
          'vitaminE': '0.3',
          'vitaminK': '2',
        },
      }
    },
    {
      'name': 'ไข่ดาว',
      'image': 'ไข่ดาว.jpg',
      'nutrition': {
        'calories': '250',
        'carbohydrates': '1',
        'proteins': '13',
        'fats': '20',
        'fiber': '0',
        'sugar': '1',
        'minerals': {
          'calcium': '30',
          'iron': '1.5',
          'magnesium': '15',
          'potassium': '100',
          'sodium': '400',
        },
        'vitamins': {
          'vitaminA': '60',
          'vitaminB': '0.3',
          'vitaminC': '0',
          'vitaminD': '-',
          'vitaminE': '0.3',
          'vitaminK': '2',
        },
      }
    },
    {
      'name': 'ไข่พะโล้',
      'image': 'ไข่พะโล้.jpg',
      'nutrition': {
        'calories': '300',
        'carbohydrates': '10',
        'proteins': '15',
        'fats': '20',
        'fiber': '0',
        'sugar': '5',
        'minerals': {
          'calcium': '35',
          'iron': '1.8',
          'magnesium': '20',
          'potassium': '150',
          'sodium': '700',
        },
        'vitamins': {
          'vitaminA': '50',
          'vitaminB': '0.3',
          'vitaminC': '2',
          'vitaminD': '-',
          'vitaminE': '0.3',
          'vitaminK': '3',
        },
      }
    },
    {
      'name': 'ไข่ลูกเขย',
      'image': 'ไข่ลูกเขย.jpg',
      'nutrition': {
        'calories': '320',
        'carbohydrates': '12',
        'proteins': '13',
        'fats': '22',
        'fiber': '1',
        'sugar': '6',
        'minerals': {
          'calcium': '35',
          'iron': '1.5',
          'magnesium': '20',
          'potassium': '140',
          'sodium': '600',
        },
        'vitamins': {
          'vitaminA': '55',
          'vitaminB': '0.3',
          'vitaminC': '2',
          'vitaminD': '-',
          'vitaminE': '0.4',
          'vitaminK': '3',
        },
      }
    },
    {
      'name': 'กล้วยบวชชี',
      'image': 'กล้วยบวชชี.jpg',
      'nutrition': {
        'calories': '220',
        'carbohydrates': '30',
        'proteins': '2',
        'fats': '10',
        'fiber': '2',
        'sugar': '25',
        'minerals': {
          'calcium': '20',
          'iron': '0.8',
          'magnesium': '10',
          'potassium': '300',
          'sodium': '50',
        },
        'vitamins': {
          'vitaminA': '30',
          'vitaminB': '0.2',
          'vitaminC': '3',
          'vitaminD': '-',
          'vitaminE': '0.2',
          'vitaminK': '1',
        },
      }
    },
    {
      'name': 'ก๋วยเตี๋ยวคั่วไก่',
      'image': 'ก๋วยเตี๋ยวคั่วไก่.jpg',
      'nutrition': {
        'calories': '450',
        'carbohydrates': '45',
        'proteins': '20',
        'fats': '20',
        'fiber': '3',
        'sugar': '6',
        'minerals': {
          'calcium': '50',
          'iron': '1.8',
          'magnesium': '20',
          'potassium': '150',
          'sodium': '850',
        },
        'vitamins': {
          'vitaminA': '40',
          'vitaminB': '0.3',
          'vitaminC': '2',
          'vitaminD': '-',
          'vitaminE': '0.3',
          'vitaminK': '3',
        },
      }
    },
    {
      'name': 'กะหล่ำปลีผัดน้ำปลา',
      'image': 'กะหล่ำปลีผัดน้ำปลา.jpg',
      'nutrition': {
        'calories': '180',
        'carbohydrates': '12',
        'proteins': '4',
        'fats': '12',
        'fiber': '4',
        'sugar': '4',
        'minerals': {
          'calcium': '35',
          'iron': '1',
          'magnesium': '15',
          'potassium': '120',
          'sodium': '600',
        },
        'vitamins': {
          'vitaminA': '50',
          'vitaminB': '0.2',
          'vitaminC': '20',
          'vitaminD': '-',
          'vitaminE': '0.3',
          'vitaminK': '10',
        },
      }
    },
    {
      'name': 'กุ้งแม่น้ำเผา',
      'image': 'กุ้งแม่น้ำเผา.jpg',
      'nutrition': {
        'calories': '300',
        'carbohydrates': '0',
        'proteins': '25',
        'fats': '20',
        'fiber': '0',
        'sugar': '0',
        'minerals': {
          'calcium': '100',
          'iron': '3',
          'magnesium': '50',
          'potassium': '250',
          'sodium': '700',
        },
        'vitamins': {
          'vitaminA': '200',
          'vitaminB': '1',
          'vitaminC': '0',
          'vitaminD': '-',
          'vitaminE': '1',
          'vitaminK': '10',
        },
      }
    },
    {
      'name': 'กุ้งอบวุ้นเส้น',
      'image': 'กุ้งอบวุ้นเส้น.jpg',
      'nutrition': {
        'calories': '320',
        'carbohydrates': '40',
        'proteins': '15',
        'fats': '12',
        'fiber': '2',
        'sugar': '3',
        'minerals': {
          'calcium': '40',
          'iron': '1.5',
          'magnesium': '25',
          'potassium': '200',
          'sodium': '850',
        },
        'vitamins': {
          'vitaminA': '20',
          'vitaminB': '0.2',
          'vitaminC': '2',
          'vitaminD': '-',
          'vitaminE': '0.2',
          'vitaminK': '2',
        },
      }
    },
    {
      'name': 'ขนมครก',
      'image': 'ขนมครก.jpg',
      'nutrition': {
        'calories': '200',
        'carbohydrates': '30',
        'proteins': '4',
        'fats': '8',
        'fiber': '1',
        'sugar': '20',
        'minerals': {
          'calcium': '10',
          'iron': '0.5',
          'magnesium': '10',
          'potassium': '100',
          'sodium': '100',
        },
        'vitamins': {
          'vitaminA': '10',
          'vitaminB': '0.1',
          'vitaminC': '0',
          'vitaminD': '-',
          'vitaminE': '0.1',
          'vitaminK': '1',
        },
      }
    },
    {
      'name': 'ข้าวเหนียวมะม่วง',
      'image': 'ข้าวเหนียวมะม่วง.jpg',
      'nutrition': {
        'calories': '400',
        'carbohydrates': '70',
        'proteins': '6',
        'fats': '10',
        'fiber': '2',
        'sugar': '30',
        'minerals': {
          'calcium': '20',
          'iron': '1',
          'magnesium': '20',
          'potassium': '300',
          'sodium': '100',
        },
        'vitamins': {
          'vitaminA': '30',
          'vitaminB': '0.3',
          'vitaminC': '20',
          'vitaminD': '-',
          'vitaminE': '0.5',
          'vitaminK': '2',
        },
      }
    },
    {
      'name': 'ข้าวขาหมู',
      'image': 'ข้าวขาหมู.jpg',
      'nutrition': {
        'calories': '600',
        'carbohydrates': '60',
        'proteins': '25',
        'fats': '30',
        'fiber': '2',
        'sugar': '8',
        'minerals': {
          'calcium': '40',
          'iron': '2',
          'magnesium': '30',
          'potassium': '200',
          'sodium': '1000',
        },
        'vitamins': {
          'vitaminA': '50',
          'vitaminB': '0.5',
          'vitaminC': '4',
          'vitaminD': '-',
          'vitaminE': '0.4',
          'vitaminK': '6',
        },
      }
    },
    {
      'name': 'ข้าวคลุกกะปิ',
      'image': 'ข้าวคลุกกะปิ.jpg',
      'nutrition': {
        'calories': '500',
        'carbohydrates': '60',
        'proteins': '20',
        'fats': '15',
        'fiber': '5',
        'sugar': '5',
        'minerals': {
          'calcium': '40',
          'iron': '1.5',
          'magnesium': '30',
          'potassium': '250',
          'sodium': '800',
        },
        'vitamins': {
          'vitaminA': '40',
          'vitaminB': '0.3',
          'vitaminC': '5',
          'vitaminD': '-',
          'vitaminE': '0.3',
          'vitaminK': '4',
        },
      }
    },
    {
      'name': 'ข้าวซอยไก่',
      'image': 'ข้าวซอยไก่.jpg',
      'nutrition': {
        'calories': '550',
        'carbohydrates': '50',
        'proteins': '25',
        'fats': '25',
        'fiber': '4',
        'sugar': '6',
        'minerals': {
          'calcium': '50',
          'iron': '2',
          'magnesium': '30',
          'potassium': '200',
          'sodium': '900',
        },
        'vitamins': {
          'vitaminA': '60',
          'vitaminB': '0.4',
          'vitaminC': '6',
          'vitaminD': '-',
          'vitaminE': '0.3',
          'vitaminK': '5',
        },
      }
    },
    {
      'name': 'ข้าวผัด',
      'image': 'ข้าวผัด.jpg',
      'nutrition': {
        'calories': '450',
        'carbohydrates': '55',
        'proteins': '15',
        'fats': '15',
        'fiber': '2',
        'sugar': '3',
        'minerals': {
          'calcium': '30',
          'iron': '1',
          'magnesium': '20',
          'potassium': '150',
          'sodium': '700',
        },
        'vitamins': {
          'vitaminA': '30',
          'vitaminB': '0.2',
          'vitaminC': '2',
          'vitaminD': '-',
          'vitaminE': '0.2',
          'vitaminK': '2',
        },
      }
    },
    {
      'name': 'ข้าวผัดกุ้ง',
      'image': 'ข้าวผัดกุ้ง.jpg',
      'nutrition': {
        'calories': '500',
        'carbohydrates': '55',
        'proteins': '20',
        'fats': '18',
        'fiber': '2',
        'sugar': '4',
        'minerals': {
          'calcium': '40',
          'iron': '1.5',
          'magnesium': '25',
          'potassium': '180',
          'sodium': '750',
        },
        'vitamins': {
          'vitaminA': '40',
          'vitaminB': '0.3',
          'vitaminC': '3',
          'vitaminD': '-',
          'vitaminE': '0.3',
          'vitaminK': '3',
        },
      }
    },
    {
      'name': 'ข้าวมันไก่',
      'image': 'ข้าวมันไก่.jpg',
      'nutrition': {
        'calories': '600',
        'carbohydrates': '65',
        'proteins': '20',
        'fats': '25',
        'fiber': '1',
        'sugar': '5',
        'minerals': {
          'calcium': '30',
          'iron': '1',
          'magnesium': '20',
          'potassium': '150',
          'sodium': '800',
        },
        'vitamins': {
          'vitaminA': '50',
          'vitaminB': '0.3',
          'vitaminC': '4',
          'vitaminD': '-',
          'vitaminE': '0.3',
          'vitaminK': '3',
        },
      }
    },
    {
      'name': 'ข้าวหมกไก่',
      'image': 'ข้าวหมกไก่.jpg',
      'nutrition': {
        'calories': '500',
        'carbohydrates': '55',
        'proteins': '25',
        'fats': '15',
        'fiber': '3',
        'sugar': '5',
        'minerals': {
          'calcium': '35',
          'iron': '1.5',
          'magnesium': '25',
          'potassium': '180',
          'sodium': '850',
        },
        'vitamins': {
          'vitaminA': '60',
          'vitaminB': '0.3',
          'vitaminC': '5',
          'vitaminD': '-',
          'vitaminE': '0.3',
          'vitaminK': '4',
        },
      }
    },
    {
      'name': 'ต้มข่าไก่',
      'image': 'ต้มข่าไก่.jpg',
      'nutrition': {
        'calories': '350',
        'carbohydrates': '15',
        'proteins': '20',
        'fats': '25',
        'fiber': '2',
        'sugar': '4',
        'minerals': {
          'calcium': '40',
          'iron': '1.5',
          'magnesium': '25',
          'potassium': '200',
          'sodium': '600',
        },
        'vitamins': {
          'vitaminA': '40',
          'vitaminB': '0.3',
          'vitaminC': '3',
          'vitaminD': '-',
          'vitaminE': '0.3',
          'vitaminK': '4',
        },
      }
    },
    {
      'name': 'ต้มยำกุ้ง',
      'image': 'ต้มยำกุ้ง.jpg',
      'nutrition': {
        'calories': '300',
        'carbohydrates': '10',
        'proteins': '20',
        'fats': '15',
        'fiber': '3',
        'sugar': '3',
        'minerals': {
          'calcium': '50',
          'iron': '2',
          'magnesium': '30',
          'potassium': '250',
          'sodium': '750',
        },
        'vitamins': {
          'vitaminA': '40',
          'vitaminB': '0.4',
          'vitaminC': '6',
          'vitaminD': '-',
          'vitaminE': '0.3',
          'vitaminK': '4',
        },
      }
    },
    {
      'name': 'ทอดมัน',
      'image': 'ทอดมัน.jpg',
      'nutrition': {
        'calories': '400',
        'carbohydrates': '20',
        'proteins': '15',
        'fats': '30',
        'fiber': '2',
        'sugar': '3',
        'minerals': {
          'calcium': '40',
          'iron': '1.5',
          'magnesium': '25',
          'potassium': '150',
          'sodium': '800',
        },
        'vitamins': {
          'vitaminA': '30',
          'vitaminB': '0.2',
          'vitaminC': '3',
          'vitaminD': '-',
          'vitaminE': '0.3',
          'vitaminK': '2',
        },
      }
    },
    {
      'name': 'ปอเปี๊ยะทอด',
      'image': 'ปอเปี๊ยะทอด.jpg',
      'nutrition': {
        'calories': '300',
        'carbohydrates': '35',
        'proteins': '10',
        'fats': '15',
        'fiber': '2',
        'sugar': '4',
        'minerals': {
          'calcium': '20',
          'iron': '1',
          'magnesium': '15',
          'potassium': '100',
          'sodium': '650',
        },
        'vitamins': {
          'vitaminA': '20',
          'vitaminB': '0.2',
          'vitaminC': '2',
          'vitaminD': '-',
          'vitaminE': '0.2',
          'vitaminK': '1',
        },
      }
    },
    {
      'name': 'ผัดผักบุ้งไฟแดง',
      'image': 'ผัดผักบุ้งไฟแดง.jpg',
      'nutrition': {
        'calories': '150',
        'carbohydrates': '10',
        'proteins': '5',
        'fats': '8',
        'fiber': '4',
        'sugar': '2',
        'minerals': {
          'calcium': '50',
          'iron': '2',
          'magnesium': '20',
          'potassium': '250',
          'sodium': '650',
        },
        'vitamins': {
          'vitaminA': '100',
          'vitaminB': '0.3',
          'vitaminC': '15',
          'vitaminD': '-',
          'vitaminE': '0.5',
          'vitaminK': '12',
        },
      }
    },
    {
      'name': 'ผัดไทย',
      'image': 'ผัดไทย.jpg',
      'nutrition': {
        'calories': '500',
        'carbohydrates': '70',
        'proteins': '15',
        'fats': '15',
        'fiber': '4',
        'sugar': '5',
        'minerals': {
          'calcium': '60',
          'iron': '2',
          'magnesium': '30',
          'potassium': '200',
          'sodium': '900',
        },
        'vitamins': {
          'vitaminA': '60',
          'vitaminB': '0.4',
          'vitaminC': '6',
          'vitaminD': '-',
          'vitaminE': '0.4',
          'vitaminK': '5',
        },
      }
    },
    {
      'name': 'ผัดกะเพรา',
      'image': 'ผัดกะเพรา.jpg',
      'nutrition': {
        'calories': '400',
        'carbohydrates': '50',
        'proteins': '20',
        'fats': '12',
        'fiber': '4',
        'sugar': '4',
        'minerals': {
          'calcium': '40',
          'iron': '1.5',
          'magnesium': '25',
          'potassium': '180',
          'sodium': '750',
        },
        'vitamins': {
          'vitaminA': '50',
          'vitaminB': '0.3',
          'vitaminC': '3',
          'vitaminD': '-',
          'vitaminE': '0.3',
          'vitaminK': '4',
        },
      }
    },
    {
      'name': 'ผัดซีอิ๊ว',
      'image': 'ผัดซีอิ๊ว.jpg',
      'nutrition': {
        'calories': '450',
        'carbohydrates': '60',
        'proteins': '15',
        'fats': '15',
        'fiber': '3',
        'sugar': '4',
        'minerals': {
          'calcium': '30',
          'iron': '1',
          'magnesium': '20',
          'potassium': '150',
          'sodium': '850',
        },
        'vitamins': {
          'vitaminA': '30',
          'vitaminB': '0.3',
          'vitaminC': '2',
          'vitaminD': '-',
          'vitaminE': '0.2',
          'vitaminK': '3',
        },
      }
    },
    {
      'name': 'ผัดฟักทองใส่ไข่',
      'image': 'ผัดฟักทองใส่ไข่.jpg',
      'nutrition': {
        'calories': '300',
        'carbohydrates': '40',
        'proteins': '10',
        'fats': '10',
        'fiber': '5',
        'sugar': '5',
        'minerals': {
          'calcium': '40',
          'iron': '1.5',
          'magnesium': '25',
          'potassium': '200',
          'sodium': '600',
        },
        'vitamins': {
          'vitaminA': '120',
          'vitaminB': '0.4',
          'vitaminC': '8',
          'vitaminD': '-',
          'vitaminE': '0.5',
          'vitaminK': '6',
        },
      }
    },
    {
      'name': 'ผัดมะเขือยาวเต้าเจี้ยวหมูสับ',
      'image': 'ผัดมะเขือยาวเต้าเจี้ยวหมูสับ.jpg',
      'nutrition': {
        'calories': '350',
        'carbohydrates': '20',
        'proteins': '15',
        'fats': '20',
        'fiber': '5',
        'sugar': '3',
        'minerals': {
          'calcium': '40',
          'iron': '1.5',
          'magnesium': '25',
          'potassium': '200',
          'sodium': '800',
        },
        'vitamins': {
          'vitaminA': '60',
          'vitaminB': '0.3',
          'vitaminC': '4',
          'vitaminD': '-',
          'vitaminE': '0.3',
          'vitaminK': '4',
        },
      }
    },
    {
      'name': 'ผัดหอยลาย',
      'image': 'ผัดหอยลาย.jpg',
      'nutrition': {
        'calories': '300',
        'carbohydrates': '15',
        'proteins': '25',
        'fats': '10',
        'fiber': '2',
        'sugar': '2',
        'minerals': {
          'calcium': '100',
          'iron': '3',
          'magnesium': '40',
          'potassium': '250',
          'sodium': '800',
        },
        'vitamins': {
          'vitaminA': '60',
          'vitaminB': '0.5',
          'vitaminC': '4',
          'vitaminD': '-',
          'vitaminE': '0.4',
          'vitaminK': '5',
        },
      }
    },
    {
      'name': 'ฝอยทอง',
      'image': 'ฝอยทอง.jpg',
      'nutrition': {
        'calories': '300',
        'carbohydrates': '50',
        'proteins': '5',
        'fats': '8',
        'fiber': '0',
        'sugar': '30',
        'minerals': {
          'calcium': '10',
          'iron': '0.5',
          'magnesium': '5',
          'potassium': '50',
          'sodium': '20',
        },
        'vitamins': {
          'vitaminA': '20',
          'vitaminB': '0.1',
          'vitaminC': '0',
          'vitaminD': '-',
          'vitaminE': '0.2',
          'vitaminK': '1',
        },
      }
    },
    {
      'name': 'พะแนงไก่',
      'image': 'พะแนงไก่.jpg',
      'nutrition': {
        'calories': '450',
        'carbohydrates': '20',
        'proteins': '25',
        'fats': '30',
        'fiber': '3',
        'sugar': '5',
        'minerals': {
          'calcium': '60',
          'iron': '2',
          'magnesium': '30',
          'potassium': '200',
          'sodium': '850',
        },
        'vitamins': {
          'vitaminA': '60',
          'vitaminB': '0.4',
          'vitaminC': '4',
          'vitaminD': '-',
          'vitaminE': '0.4',
          'vitaminK': '6',
        },
      }
    },
    {
      'name': 'ยำถั่วพู',
      'image': 'ยำถั่วพู.jpg',
      'nutrition': {
        'calories': '300',
        'carbohydrates': '15',
        'proteins': '10',
        'fats': '20',
        'fiber': '5',
        'sugar': '3',
        'minerals': {
          'calcium': '40',
          'iron': '1.5',
          'magnesium': '30',
          'potassium': '200',
          'sodium': '650',
        },
        'vitamins': {
          'vitaminA': '50',
          'vitaminB': '0.3',
          'vitaminC': '5',
          'vitaminD': '-',
          'vitaminE': '0.4',
          'vitaminK': '5',
        },
      }
    },
    {
      'name': 'ยำวุ้นเส้น',
      'image': 'ยำวุ้นเส้น.jpg',
      'nutrition': {
        'calories': '250',
        'carbohydrates': '30',
        'proteins': '10',
        'fats': '8',
        'fiber': '3',
        'sugar': '4',
        'minerals': {
          'calcium': '30',
          'iron': '1',
          'magnesium': '20',
          'potassium': '150',
          'sodium': '600',
        },
        'vitamins': {
          'vitaminA': '30',
          'vitaminB': '0.3',
          'vitaminC': '4',
          'vitaminD': '-',
          'vitaminE': '0.3',
          'vitaminK': '3',
        },
      }
    },
    {
      'name': 'ลาบหมู',
      'image': 'ลาบหมู.jpg',
      'nutrition': {
        'calories': '350',
        'carbohydrates': '5',
        'proteins': '25',
        'fats': '25',
        'fiber': '2',
        'sugar': '2',
        'minerals': {
          'calcium': '40',
          'iron': '1.5',
          'magnesium': '25',
          'potassium': '150',
          'sodium': '750',
        },
        'vitamins': {
          'vitaminA': '30',
          'vitaminB': '0.4',
          'vitaminC': '4',
          'vitaminD': '-',
          'vitaminE': '0.3',
          'vitaminK': '3',
        },
      }
    },
    {
      'name': 'สังขยาฟักทอง',
      'image': 'สังขยาฟักทอง.jpg',
      'nutrition': {
        'calories': '200',
        'carbohydrates': '40',
        'proteins': '6',
        'fats': '2',
        'fiber': '4',
        'sugar': '30',
        'minerals': {
          'calcium': '20',
          'iron': '0.5',
          'magnesium': '15',
          'potassium': '100',
          'sodium': '100',
        },
        'vitamins': {
          'vitaminA': '80',
          'vitaminB': '0.2',
          'vitaminC': '10',
          'vitaminD': '-',
          'vitaminE': '0.2',
          'vitaminK': '3',
        },
      }
    },
    {
      'name': 'สาคู',
      'image': 'สาคู.jpg',
      'nutrition': {
        'calories': '180',
        'carbohydrates': '40',
        'proteins': '3',
        'fats': '2',
        'fiber': '1',
        'sugar': '20',
        'minerals': {
          'calcium': '10',
          'iron': '0.5',
          'magnesium': '5',
          'potassium': '50',
          'sodium': '30',
        },
        'vitamins': {
          'vitaminA': '10',
          'vitaminB': '0.1',
          'vitaminC': '0',
          'vitaminD': '-',
          'vitaminE': '0.1',
          'vitaminK': '1',
        },
      }
    },
    {
      'name': 'ส้มตำ',
      'image': 'ส้มตำ.jpg',
      'nutrition': {
        'calories': '120',
        'carbohydrates': '15',
        'proteins': '4',
        'fats': '5',
        'fiber': '3',
        'sugar': '3',
        'minerals': {
          'calcium': '20',
          'iron': '0.5',
          'magnesium': '10',
          'potassium': '150',
          'sodium': '500',
        },
        'vitamins': {
          'vitaminA': '60',
          'vitaminB': '0.2',
          'vitaminC': '30',
          'vitaminD': '-',
          'vitaminE': '0.3',
          'vitaminK': '6',
        },
      }
    },
    {
      'name': 'หมูปิ้ง',
      'image': 'หมูปิ้ง.jpg',
      'nutrition': {
        'calories': '250',
        'carbohydrates': '2',
        'proteins': '15',
        'fats': '20',
        'fiber': '0',
        'sugar': '3',
        'minerals': {
          'calcium': '20',
          'iron': '1',
          'magnesium': '15',
          'potassium': '150',
          'sodium': '600',
        },
        'vitamins': {
          'vitaminA': '30',
          'vitaminB': '0.3',
          'vitaminC': '1',
          'vitaminD': '-',
          'vitaminE': '0.3',
          'vitaminK': '3',
        },
      }
    },
    {
      'name': 'หมูสะเต๊ะ',
      'image': 'หมูสะเต๊ะ.jpg',
      'nutrition': {
        'calories': '280',
        'carbohydrates': '10',
        'proteins': '18',
        'fats': '20',
        'fiber': '1',
        'sugar': '4',
        'minerals': {
          'calcium': '25',
          'iron': '1.5',
          'magnesium': '20',
          'potassium': '150',
          'sodium': '650',
        },
        'vitamins': {
          'vitaminA': '40',
          'vitaminB': '0.3',
          'vitaminC': '2',
          'vitaminD': '-',
          'vitaminE': '0.4',
          'vitaminK': '4',
        },
      }
    },
    {
      'name': 'ห่อหมก',
      'image': 'ห่อหมก.jpg',
      'nutrition': {
        'calories': '350',
        'carbohydrates': '15',
        'proteins': '25',
        'fats': '20',
        'fiber': '3',
        'sugar': '2',
        'minerals': {
          'calcium': '60',
          'iron': '2',
          'magnesium': '30',
          'potassium': '250',
          'sodium': '750',
        },
        'vitamins': {
          'vitaminA': '60',
          'vitaminB': '0.4',
          'vitaminC': '5',
          'vitaminD': '-',
          'vitaminE': '0.4',
          'vitaminK': '6',
        },
      }
    },
  ];

  void _addAllFood() {
    for (var food in foodList) {
      FirebaseFirestore.instance.collection('food').add(food).then((value) {
        print('${food['name']} ถูกเพิ่มเรียบร้อย');
      }).catchError((error) {
        print('เกิดข้อผิดพลาดในการเพิ่ม ${food['name']}: $error');
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ข้อมูลอาหารทั้งหมดถูกเพิ่มเรียบร้อย')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เพิ่มข้อมูลอาหารทั้งหมด'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _addAllFood,
          child: Text('เพิ่มข้อมูลอาหาร'),
        ),
      ),
    );
  }
}
