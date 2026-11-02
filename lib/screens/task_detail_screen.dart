
import 'package:flutter/material.dart';

// Import màn hình chỉnh sửa công việc
import 'task_edit_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  // Thông tin công việc từ danh sách
  final Map<String, dynamic> task;

  // Token đăng nhập để gọi API
  final String token;

  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.token,
  });

  @override
  State<TaskDetailScreen> createState() =>
      _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  static const Color mauTim = Color(0xFF6554C0);

  // Dữ liệu công việc hiện tại
  late Map<String, dynamic> congViec;

  @override
  void initState() {
    super.initState();

    congViec = Map<String, dynamic>.from(widget.task);
  }

  // 1. ĐỊNH DẠNG NGÀY THÁNG
  String hienThiNgay(dynamic ngay) {
    if (ngay == null) return 'Chưa có';

    final date = DateTime.tryParse(ngay.toString());

    if (date == null) return 'Không hợp lệ';

    final localDate = date.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }

  // 2. HIỂN THỊ MỘT DÒNG THÔNG TIN
  Widget dongThongTin(
      IconData icon,
      String tieuDe,
      String noiDung,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: mauTim, size: 23),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tieuDe,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  noiDung,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. MỞ MÀN HÌNH CHỈNH SỬA CÔNG VIỆC
  Future<void> moChinhSuaCongViec() async {
    // Chuyển sang màn hình chỉnh sửa
    final ketQua =
    await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => TaskEditScreen(
          token: widget.token,
          task: congViec,
        ),
      ),
    );

    if (!mounted) return;

    // Cập nhật dữ liệu khi chỉnh sửa thành công
    if (ketQua != null) {
      setState(() {
        congViec = Map<String, dynamic>.from(ketQua);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật công việc thành công!'),
        ),
      );
    }
  }

  // 4. GIAO DIỆN CHI TIẾT CÔNG VIỆC
  @override
  Widget build(BuildContext context) {
    final ten = congViec['title']?.toString() ?? '';

    final moTa =
        congViec['description']?.toString() ?? '';

    final uuTien =
        congViec['priority']?.toString() ?? 'Trung bình';

    final trangThai =
        congViec['status']?.toString() ?? 'Chưa thực hiện';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),

      // THANH TIÊU ĐỀ
      appBar: AppBar(
        title: const Text('Chi tiết công việc'),
        centerTitle: true,
        backgroundColor: mauTim,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TÊN CÔNG VIỆC
            Text(
              ten,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // THÔNG TIN CÔNG VIỆC
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Mô tả
                    dongThongTin(
                      Icons.description,
                      'Mô tả',
                      moTa.isEmpty
                          ? 'Không có mô tả'
                          : moTa,
                    ),

                    const Divider(),

                    // Người phụ trách
                    dongThongTin(
                      Icons.person,
                      'Người phụ trách',
                      'Tôi',
                    ),

                    const Divider(),

                    // Mức độ ưu tiên
                    dongThongTin(
                      Icons.flag,
                      'Mức độ ưu tiên',
                      uuTien,
                    ),

                    const Divider(),

                    // Trạng thái
                    dongThongTin(
                      Icons.pending_actions,
                      'Trạng thái',
                      trangThai,
                    ),

                    const Divider(),

                    // Ngày bắt đầu
                    dongThongTin(
                      Icons.calendar_today,
                      'Ngày bắt đầu',
                      hienThiNgay(congViec['startDate']),
                    ),

                    const Divider(),

                    // Hạn hoàn thành
                    dongThongTin(
                      Icons.event,
                      'Hạn hoàn thành',
                      hienThiNgay(congViec['dueDate']),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // NÚT CHỈNH SỬA VÀ XÓA
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    // Mở màn hình chỉnh sửa
                    onPressed: moChinhSuaCongViec,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mauTim,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text('Chỉnh sửa'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: OutlinedButton.icon(
                    // Chức năng xóa làm ở bước sau
                    onPressed: null,
                    icon: const Icon(Icons.delete),
                    label: const Text('Xóa'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
