import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String? profileImageBase64;
  final String? matricNo;
  final String? course;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    this.phoneNumber = '',
    this.profileImageBase64,
    this.matricNo,
    this.course,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      profileImageBase64: data['profileImageBase64'],
      matricNo: data['matricNo'],
      course: data['course'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      if (profileImageBase64 != null) 'profileImageBase64': profileImageBase64,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? phoneNumber,
    String? profileImageBase64,
    bool clearImage = false,
  }) {
    return UserProfile(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageBase64: clearImage ? null : (profileImageBase64 ?? this.profileImageBase64),
      matricNo: matricNo,
      course: course,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
