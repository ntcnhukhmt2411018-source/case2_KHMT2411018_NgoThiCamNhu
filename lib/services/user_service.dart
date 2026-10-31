
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class UserService {
  // =========================================
  // 1. ĐỊA CHỈ KẾT NỐI API NODE.JS
  // =========================================
  // 10.0.2.2 là địa chỉ localhost của máy tính
  // khi chạy Flutter trên Android Emulator.
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // =========================================
  // 2. XEM THÔNG TIN CÁ NHÂN
  // =========================================
  static Future<Map<String, dynamic>> getProfile(
      String token,
      ) async {
    try {
      // Gửi yêu cầu lấy thông tin người dùng
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      // Đọc dữ liệu JSON trả về
      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(
          data['message'] ?? 'Lấy thông tin thất bại',
        );
      }

      return Map<String, dynamic>.from(data);
    } on TimeoutException {
      throw Exception('Kết nối quá thời gian. Hãy kiểm tra Node.js.');
    } on http.ClientException {
      throw Exception('Không thể kết nối đến máy chủ Node.js.');
    }
  }

  // =========================================
  // 3. CẬP NHẬT THÔNG TIN CÁ NHÂN
  // =========================================
  static Future<Map<String, dynamic>> updateProfile(
      String token,
      String fullName,
      ) async {
    try {
      // Gửi họ tên mới lên MongoDB thông qua API
      final response = await http.put(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fullName': fullName,
        }),
      ).timeout(const Duration(seconds: 10));

      // Nhận kết quả cập nhật
      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(
          data['message'] ?? 'Cập nhật thông tin thất bại',
        );
      }

      return Map<String, dynamic>.from(data);
    } on TimeoutException {
      throw Exception('Kết nối quá thời gian. Hãy thử lại.');
    } on http.ClientException {
      throw Exception('Không thể kết nối đến máy chủ Node.js.');
    }
  }

  // =========================================
  // 4. ĐỔI MẬT KHẨU
  // =========================================
  static Future<void> changePassword(
      String token,
      String oldPassword,
      String newPassword,
      ) async {
    // Kiểm tra dữ liệu trước khi gửi API
    if (oldPassword.isEmpty || newPassword.isEmpty) {
      throw Exception('Vui lòng nhập đầy đủ mật khẩu');
    }

    if (newPassword.length < 8) {
      throw Exception('Mật khẩu mới phải có ít nhất 8 ký tự');
    }

    if (oldPassword == newPassword) {
      throw Exception('Mật khẩu mới phải khác mật khẩu cũ');
    }

    try {
      // Gửi mật khẩu cũ và mới đến Node.js
      final response = await http.post(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 10));

      // Nhận phản hồi từ backend
      final data = jsonDecode(response.body);

      // Kiểm tra kết quả đổi mật khẩu
      if (response.statusCode != 200) {
        throw Exception(
          data['message'] ?? 'Đổi mật khẩu thất bại',
        );
      }

      // Thành công: không cần trả dữ liệu
    } on TimeoutException {
      throw Exception('Kết nối quá thời gian. Hãy thử lại.');
    } on http.ClientException {
      throw Exception('Không thể kết nối đến máy chủ Node.js.');
    }
  }
}
