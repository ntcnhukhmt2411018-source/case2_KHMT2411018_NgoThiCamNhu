
import 'dart:convert';
import 'package:http/http.dart' as http;

// Service kết nối Flutter với API quản lý công việc
class TaskService {
  // Địa chỉ backend Node.js trên Android Emulator
  static const String baseUrl =
      'http://10.0.2.2:3000/api/tasks';

  // 1. TẠO CÔNG VIỆC MỚI
  static Future<Map<String, dynamic>> createTask({
    required String token,
    required String title,
    required String description,
    required String priority,
    required DateTime startDate,
    required DateTime dueDate,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'priority': priority,
        'startDate': startDate.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data['message'] ?? 'Tạo công việc thất bại',
    );
  }

  // 2. LẤY DANH SÁCH CÔNG VIỆC
  static Future<List<dynamic>> getTasks(
      String token,
      ) async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['tasks'] as List<dynamic>;
    }

    throw Exception(
      data['message'] ?? 'Không thể lấy danh sách công việc',
    );
  }

  // 3. CHỈNH SỬA CÔNG VIỆC
  static Future<Map<String, dynamic>> updateTask({
    required String token,
    required String taskId,
    required String title,
    required String description,
    required String priority,
    required String status,
    required DateTime startDate,
    required DateTime dueDate,
  }) async {
    // Gửi yêu cầu PUT đến Node.js
    final response = await http.put(
      Uri.parse('$baseUrl/$taskId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'priority': priority,
        'status': status,
        'startDate': startDate.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
      }),
    );

    // Chuyển kết quả JSON thành dữ liệu Dart
    final data = jsonDecode(response.body);

    // Cập nhật thành công
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data['message'] ?? 'Không thể cập nhật công việc',
    );
  }

  // 4. XÓA CÔNG VIỆC
  static Future<void> deleteTask({
    required String token,
    required String taskId,
  }) async {
    // Gửi yêu cầu DELETE đến Node.js
    final response = await http.delete(
      Uri.parse('$baseUrl/$taskId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    // Xóa thành công
    if (response.statusCode == 200) {
      return;
    }

    // Đọc thông báo lỗi từ backend
    String thongBao = 'Không thể xóa công việc';

    try {
      final data = jsonDecode(response.body);
      thongBao = data['message'] ?? thongBao;
    } catch (_) {
      // Giữ thông báo mặc định nếu server không trả JSON
    }

    throw Exception(thongBao);
  }
}
