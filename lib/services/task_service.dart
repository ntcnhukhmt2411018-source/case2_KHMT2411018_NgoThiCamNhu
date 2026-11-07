
import 'dart:convert';
import 'package:http/http.dart' as http;

// Service kết nối Flutter với API quản lý công việc
class TaskService {
  // Địa chỉ backend trên Android Emulator
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
      data['message'] ??
          'Không thể lấy danh sách công việc',
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

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data['message'] ??
          'Không thể cập nhật công việc',
    );
  }

  // 4. XÓA CÔNG VIỆC
  static Future<void> deleteTask({
    required String token,
    required String taskId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$taskId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return;
    }

    String thongBao = 'Không thể xóa công việc';

    try {
      final data = jsonDecode(response.body);
      thongBao = data['message'] ?? thongBao;
    } catch (_) {
      // Giữ thông báo mặc định
    }

    throw Exception(thongBao);
  }

  // 5. TÌM NGƯỜI DÙNG THEO EMAIL
  static Future<Map<String, dynamic>> findUserByEmail({
    required String token,
    required String email,
  }) async {
    final uri = Uri.parse('$baseUrl/users').replace(
      queryParameters: {
        'email': email.trim().toLowerCase(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data['user']);
    }

    throw Exception(
      data['message'] ?? 'Không tìm thấy tài khoản',
    );
  }

  // 6. GIAO CÔNG VIỆC CHO MỘT NGƯỜI
  static Future<Map<String, dynamic>> assignTask({
    required String token,
    required String taskId,
    required String userId,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$taskId/assign'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'assignedTo': userId,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data['message'] ?? 'Không thể giao công việc',
    );
  }


// 7. CHIA SẺ CÔNG VIỆC VÀ PHÂN QUYỀN
  static Future<Map<String, dynamic>> shareTask({
    required String token,
    required String taskId,
    required String userId,
    String role = 'viewer',
  }) async {
    // Kiểm tra quyền chia sẻ
    if (role != 'viewer' && role != 'editor') {
      throw Exception('Quyền chia sẻ không hợp lệ');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/$taskId/share'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'userId': userId,
        'role': role,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data['message'] ?? 'Không thể chia sẻ công việc',
    );
  }

// 8. C.6 - THAY ĐỔI QUYỀN VIEWER / EDITOR
  static Future<Map<String, dynamic>> updateSharePermission({
    required String token,
    required String taskId,
    required String userId,
    required String role,
  }) async {
    if (role != 'viewer' && role != 'editor') {
      throw Exception('Quyền chia sẻ không hợp lệ');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/$taskId/share/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'role': role,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data['message'] ?? 'Không thể thay đổi quyền chia sẻ',
    );
  }

// 9. C.6 - THU HỒI QUYỀN CHIA SẺ
  static Future<Map<String, dynamic>> revokeSharePermission({
    required String token,
    required String taskId,
    required String userId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$taskId/share/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data['message'] ?? 'Không thể thu hồi quyền chia sẻ',
    );
  }


  // 8. GIAO CÔNG VIỆC CHO NHIỀU NGƯỜI (C.1)
  static Future<Map<String, dynamic>> assignManyTasks({
    required String token,
    required String taskId,
    required List<String> userIds,
    String? primaryUserId,
  }) async {
    if (userIds.isEmpty) {
      throw Exception(
        'Vui lòng chọn ít nhất một người nhận',
      );
    }

    // Gọi API giao công việc cho nhiều người
    final response = await http.put(
      Uri.parse('$baseUrl/$taskId/assign-many'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        // Danh sách ID người được giao
        'userIds': userIds,

        // Chỉ gửi primaryUserId nếu có giá trị
        if (primaryUserId != null)
          'primaryUserId': primaryUserId,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data['message'] ??
          'Không thể giao công việc cho nhiều người',
    );
  }
}
