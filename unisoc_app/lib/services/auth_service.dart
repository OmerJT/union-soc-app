import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service class for managing user authentication and API communication.
/// Handles login, registration, token management, and user profile operations.
/// Uses JWT tokens for API authentication and SharedPreferences for local storage.
class AuthService extends ChangeNotifier {
  String? _token;
  String? _role;
  String? _username;

  bool get isLoggedIn => _token != null;
  bool get isAdmin => _role == 'admin';
  String? get token => _token;
  String? get role => _role;
  String? get username => _username;

  /// Base URL for the Django REST API backend
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  /// Headers for authenticated API requests
  Map<String, String> get authHeaders => {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      };

  /// Load authentication token from local storage on app startup
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _role = prefs.getString('role');
    _username = prefs.getString('username');
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveSession(data['access'], data['role'], data['username']);
      return true;
    }
    return false;
  }

  Future<bool> register(
    String username,
    String email,
    String password,
    String firstName,
    String lastName,
    String upNumber, {
    String role = 'user',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'up_number': role == 'admin' ? '' : upNumber,
        'role': role,
      }),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await _saveSession(data['access'], data['role'] ?? role, data['username'] ?? username);
      return true;
    }
    return false;
  }

  Future<void> _saveSession(String token, String role, String username) async {
    _token = token;
    _role = role;
    _username = username;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
    await prefs.setString('role', _role!);
    await prefs.setString('username', _username!);
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final response = await http.get(Uri.parse('$baseUrl/auth/me/'), headers: authHeaders);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }

  Future<bool> updateProfile(Map<String, dynamic> payload) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/auth/me/'),
      headers: authHeaders,
      body: jsonEncode(payload),
    );
    return response.statusCode == 200;
  }

  Future<String?> requestPasswordReset(String usernameOrEmail) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username_or_email': usernameOrEmail}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['reset_token']?.toString() ?? data['message']?.toString();
    }
    return null;
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'new_password': newPassword}),
    );
    return response.statusCode == 200;
  }

  Future<void> logout() async {
    _token = null;
    _role = null;
    _username = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
