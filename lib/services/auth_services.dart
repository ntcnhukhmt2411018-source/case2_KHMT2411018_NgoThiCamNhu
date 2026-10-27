import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // Đăng ký tài khoản
  static Future<Map<String, dynamic>> register(
      String fullName,
      String email,
      String password,
      ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Đăng ký thất bại');
    }

    return Map<String, dynamic>.from(data);
  }

  // Đăng nhập tài khoản
  static Future<Map<String, dynamic>> login(
      String email,
      String password,
      ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Đăng nhập thất bại');
    }

    return Map<String, dynamic>.from(data);
  }
}