import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: user == null
          ? Center(child: const Text('No user logged in.'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('No data found.'));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final name = data['name']?.toString() ?? 'N/A';
                final height = data['height']?.toString() ?? 'N/A';
                final weight = data['weight']?.toString() ?? 'N/A';
                final birthdateTimestamp = data['birthdate'] as Timestamp?;
                final birthdate = birthdateTimestamp?.toDate();
                final age = data['age']?.toString() ?? 'N/A';
                final gender = data['gender']?.toString() ?? 'N/A'; // เพิ่มการดึงข้อมูลเพศ

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Center(
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.teal,
                              child: Text(
                                name.substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal[800],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Divider(color: Colors.teal),
                          const SizedBox(height: 8),
                          _buildProfileItem('Gender', gender), // เพิ่มการแสดงข้อมูลเพศ
                          _buildProfileItem('Height', '$height cm'),
                          _buildProfileItem('Weight', '$weight kg'),
                          _buildProfileItem(
                            'Birthdate',
                            birthdate != null
                                ? DateFormat.yMMMd().format(birthdate)
                                : 'N/A',
                          ),
                          _buildProfileItem('Age', '$age years'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.teal[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
