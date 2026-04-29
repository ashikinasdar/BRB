import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  
  // Change to 'http://10.0.2.2/himsak_api' if using Android Emulator
  // For Chrome/Web or Windows Desktop, localhost works.
  final String _baseUrl = 'http://localhost/himsak_api'; 

  UserModel? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _currentUser = UserModel(
            id: data['user']['id'].toString(),
            fullName: data['user']['fullName'],
            email: data['user']['email'],
            status: data['user']['status'] ?? 'Approved',
            role: data['user']['role'] ?? 'user',
          );
          notifyListeners();
          return null; // Success
        } else {
          print('Login failed: ${data['message']}');
          return data['message'];
        }
      }
    } catch (e) {
      print('Error during login: $e');
      return 'An error occurred during login.';
    }
    return 'Failed to connect to server.';
  }

  Future<String?> register(String fullName, String email, String password, String icImageBase64) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'full_name': fullName,
          'email': email,
          'password': password,
          'ic_image': icImageBase64,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _currentUser = UserModel(
            id: data['user']['id'].toString(),
            fullName: data['user']['fullName'],
            email: data['user']['email'],
            status: data['user']['status'] ?? 'Pending Verification',
            role: data['user']['role'] ?? 'user',
          );
          notifyListeners();
          return null; // Success
        } else {
           print('Register failed: ${data['message']}');
           return data['message'];
        }
      }
    } catch (e) {
      print('Error during registration: $e');
      return 'An error occurred during registration.';
    }
    return 'Failed to connect to server.';
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
