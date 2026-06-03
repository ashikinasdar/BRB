import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('🔥 Starting HIMSAK Firebase Migration...');

  // ADMIN USER
  await FirebaseFirestore.instance.collection('users').doc('admin123').set({
    'fullName': 'HIMSAK Admin',
    'email': 'admin@himsak.com',
    'status': 'Approved',
    'role': 'admin',
    'icImage': '',
    'createdAt': FieldValue.serverTimestamp(),
  });
  print('✅ Admin created (UID: admin123)');

  // TEST STUDENTS
  final testUsers = [
    {
      'uid': 'student001',
      'fullName': 'Ahmad Bin Abdullah',
      'email': 'student@graduate.utm.my',
      'status': 'Approved',
      'role': 'user',
      'icImage': 'https://via.placeholder.com/300x200/8B2247/FFFFFF?text=IC+Image'
    },
    {
      'uid': 'student002',
      'fullName': 'Siti Binti Osman',
      'email': 'siti@himsak.com',
      'status': 'Pending Verification',
      'role': 'user',
      'icImage': 'https://via.placeholder.com/300x200/8B2247/FFFFFF?text=IC+Siti'
    }
  ];

  for (var user in testUsers) {
    await FirebaseFirestore.instance.collection('users').doc(user['uid']).set(user);
    print('✅ ${user['fullName']} (${user['status']})');
  }

  print('\n🎉 MIGRATION COMPLETE!');
  print('📱 Test Logins:');
  print('   Admin: admin@himsak.com');
  print('   Student: student@graduate.utm.my');
  print('\n🔥 Check Firebase Console → Firestore → users');
}