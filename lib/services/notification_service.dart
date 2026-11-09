
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  static const String baseUrl =
      'http://10.0.2.2:3000/api/notifications';

  static Future<Map<String, dynamic>> getNotifications(
      String token,
      ) async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Không thể tải thông báo');
  }

  static Future<int> getUnreadCount(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/unread-count'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['unreadCount'] as num).toInt();
    }

    throw Exception('Không thể đếm thông báo');
  }

  static Future<void> markAsRead(
      String token,
      String notificationId,
      ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$notificationId/read'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Không thể đánh dấu đã đọc');
    }
  }

  static Future<void> markAllAsRead(String token) async {
    final response = await http.put(
      Uri.parse('$baseUrl/read-all'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Không thể đánh dấu tất cả đã đọc');
    }
  }
}
