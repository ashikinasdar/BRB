import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

/// Handles all Firebase interactions for profile management.
class ProfileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  // ── Fetch ──────────────────────────────────────────────────────────────────

  /// Returns a live stream of the authenticated user's profile document.
  Stream<UserProfile?> profileStream() {
    final uid = currentUid;
    if (uid == null) return const Stream.empty();

    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserProfile.fromFirestore(uid, snap.data()!);
    });
  }

  /// Fetches the profile once. Creates a minimal document if absent.
  Future<UserProfile> fetchOrCreateProfile() async {
    final uid = currentUid!;
    final ref = _db.collection('users').doc(uid);
    final snap = await ref.get();

    if (!snap.exists) {
      final email = _auth.currentUser?.email ?? '';
      await ref.set({
        'fullName': '',
        'email': email,
        'phoneNumber': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final newSnap = await ref.get();
      return UserProfile.fromFirestore(uid, newSnap.data()!);
    }

    return UserProfile.fromFirestore(uid, snap.data()!);
  }

  // ── Update ─────────────────────────────────────────────────────────────────

  /// Saves editable profile fields to Firestore.
  Future<void> updateProfile({
    required String fullName,
    required String phoneNumber,
    String? profileImageBase64,
  }) async {
    final uid = currentUid!;
    final payload = <String, dynamic>{
      'fullName': fullName.trim(),
      'phoneNumber': phoneNumber.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (profileImageBase64 != null) {
      payload['profileImageBase64'] = profileImageBase64;
    }
    await _db.collection('users').doc(uid).set(payload, SetOptions(merge: true));
  }

  // ── Image ──────────────────────────────────────────────────────────────────

  /// Stores the profile image as a base64 string directly in Firestore.
  /// Matches the existing pattern used by the codebase (no Firebase Storage).
  Future<void> uploadProfileImage(List<int> imageBytes) async {
    if (imageBytes.length > 800 * 1024) {
      throw Exception('Image is too large. Maximum size is 800 KB.');
    }
    final base64Image = base64Encode(imageBytes);
    await _db.collection('users').doc(currentUid!).set(
      {'profileImageBase64': base64Image, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }
}
