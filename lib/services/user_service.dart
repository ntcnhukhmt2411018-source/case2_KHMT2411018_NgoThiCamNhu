
import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // Xem thông tin cá nhân
  static Future<Map<String, dynamic>> getProfile(
      String token,
      ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Lấy thông tin thất bại');
    }

    return Map<String, dynamic>.from(data);
  }

  // Cập nhật thông tin cá nhân
  static Future<Map<String, dynamic>> updateProfile(
      String token,
      String fullName,
      ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'fullName': fullName,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Cập nhật thất bại');
    }

    return Map<String, dynamic>.from(data);
  }
}
