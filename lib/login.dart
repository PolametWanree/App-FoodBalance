import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodbalance4/register.dart';
import 'package:foodbalance4/mainscreen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });

      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password provided.';
      } else {
        errorMessage = 'An error occurred. Please try again.';
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Failed'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          Navigator.pushReplacementNamed(context, '/height_weight');
        } else {
          Navigator.pushReplacementNamed(context, '/main');
        }
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        // แบ็คกราวด์เป็นรูปภาพ
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/BG.png'), // ใส่เส้นทางไปยังภาพแบ็คกราวด์ของคุณ
              fit: BoxFit.cover,
              alignment: Alignment(0.0, -2), // ขยับตำแหน่งแบ็คกราวด์
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0), // ปรับ Padding ข้างๆ
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch, // ทำให้ element เต็มความกว้าง
            children: <Widget>[
              const SizedBox(height: 100), // เพิ่มช่องว่างด้านบนเพื่อเลื่อนส่วนนี้ลงมา
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0), // เพิ่ม Padding ด้านล่าง
                child: TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Color.fromARGB(255, 0, 0, 0)), // เพิ่มสีให้กับ label
                    filled: true,
                    fillColor: Color.fromARGB(255, 255, 255, 255), // เพิ่มสีพื้นหลังให้กับช่องกรอก
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20), // ปรับขนาดของ Padding ภายในช่องกรอก
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 5), // เพิ่ม Padding ด้านล่าง
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    filled: true,
                    labelStyle: TextStyle(color: Color.fromARGB(255, 0, 0, 0)), // เพิ่มสีให้กับ label
                    fillColor: Color.fromARGB(255, 255, 255, 255), // เพิ่มสีพื้นหลังให้กับช่องกรอก
                    border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20), // ปรับขนาดของ Padding ภายในช่องกรอก
                  ),
                ),
              ),
              const SizedBox(height: 16), // เพิ่มระยะห่างระหว่างปุ่มและช่องกรอก
              _isLoading
                  ? const Center(child: CircularProgressIndicator()) // ให้หมุนอยู่ตรงกลาง
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12), // เพิ่มขนาดปุ่ม
                      ),
                      child: const Text('Login',
                        style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)), // สีตัวอักษรของปุ่ม
                      ),
                    ),
              const SizedBox(height: 16), // เพิ่มระยะห่างระหว่างปุ่ม
              ElevatedButton(
                      onPressed: _loginWithGoogle,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12), // ปรับขนาดปุ่ม
                        shape: const CircleBorder(), // ทำให้ปุ่มเป็นวงกลม
                        backgroundColor: Colors.white, // พื้นหลังของปุ่มเป็นสีขาว (หรือเปลี่ยนเป็นสีอื่นที่คุณต้องการ)
                      ),
                      child: Image.asset(
                        'assets/images/GG.png', // ใช้ไอคอน Google จากไฟล์ที่คุณมี (ปรับเส้นทางให้ถูกต้อง)
                        height: 24, // ขนาดของไอคอน
                        width: 24,
                      ),
                    ),
                    Padding(
  padding: const EdgeInsets.only(top: 16.0), // เพิ่ม Padding ด้านบน
  child: Row(
    children: <Widget>[
      const Expanded(
        child: Divider(
          color: Color.fromARGB(255, 255, 255, 255), // สีของเส้น
          thickness: 2, // ความหนาของเส้น
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0), // เพิ่ม Padding ระหว่างเส้นกับข้อความ
        child: const Text(
          "OR", // ข้อความที่ต้องการเพิ่ม
          style: TextStyle(
            color: Colors.white, // สีของข้อความ
            fontSize: 16, // ขนาดตัวอักษร
          ),
        ),
      ),
      const Expanded(
        child: Divider(
          color: Color.fromARGB(255, 255, 255, 255), // สีของเส้น
          thickness: 2, // ความหนาของเส้น
        ),
      ),
    ],
  ),
),

              const SizedBox(height: 16), // เพิ่มระยะห่างระหว่างปุ่ม
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterPage()),
                  );
                },
                child: const Text(
                  'Don\'t have an account? Register here.',
                  style: TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255), // สีตัวอักษรของปุ่ม
                  fontSize: 12, // ปรับขนาดตัวอักษร
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12), // ปรับขนาดปุ่ม
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}


}
