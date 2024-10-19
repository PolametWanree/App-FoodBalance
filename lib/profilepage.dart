import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:foodbalance4/AdminScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ProfilePage(),
    );
  }
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? currentUser;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  // ดึงข้อมูลผู้ใช้ที่ล็อกอินอยู่จาก Firebase Auth และดึงข้อมูลจาก Firestore
  Future<void> _getCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUser = user;
      });

      // ดึงข้อมูลจาก Firestore โดยใช้ user.uid
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        userData = userDoc.data() as Map<String, dynamic>?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Page'),
        actions: [
          IconButton(
            icon: Icon(Icons.admin_panel_settings), // ไอคอน admin
            onPressed: () {
              // นำทางไปยังหน้า AdminScreen เมื่อกดปุ่ม
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminScreen()),
              );
            },
          ),
        ],
      ),
      body: userData != null
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage('assets/images/GG.png'),
                    ),
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: Text(
                      userData!['name'] ?? 'No name',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: Text(
                      currentUser!.email ?? 'No email',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'About Me',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Age: ${userData!['age'] ?? 'N/A'}',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Gender: ${userData!['gender'] ?? 'N/A'}',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Height: ${userData!['height'] ?? 'N/A'} cm',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Weight: ${userData!['weight'] ?? 'N/A'} kg',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Activity Level: ${userData!['activity_level'] ?? 'N/A'}',
                    style: TextStyle(fontSize: 16),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          _logout(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 50),
                        ),
                        child: Text('Log Out'),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Center(child: CircularProgressIndicator()), // แสดง progress bar ขณะโหลดข้อมูล
    );
  }

  void _logout(BuildContext context) async {
    // แสดง dialog ยืนยันการ log out
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Log Out'),
          content: Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ปิด Dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // ทำการ sign out จาก Firebase
                await FirebaseAuth.instance.signOut();

                // ลบสถานะการล็อกอินจาก SharedPreferences
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false);

                // ปิด Dialog และนำผู้ใช้ไปยังหน้า LoginPage
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text('Log Out'),
            ),
          ],
        );
      },
    );
  }
}
