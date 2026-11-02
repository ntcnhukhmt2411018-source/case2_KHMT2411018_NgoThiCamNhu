
import 'package:flutter/material.dart';

// Kết nối với API quản lý công việc
import '../services/task_service.dart';

class TaskCreateScreen extends StatefulWidget {
  final String token;

  const TaskCreateScreen({
    super.key,
    required this.token,
  });

  @override
  State<TaskCreateScreen> createState() =>
      _TaskCreateScreenState();
}

class _TaskCreateScreenState extends State<TaskCreateScreen> {
  static const Color mauTim = Color(0xFF6554C0);

  // Controller nhập công việc
  final tenController = TextEditingController();
  final moTaController = TextEditingController();

  // Thông tin công việc
  String mucUuTien = 'Trung bình';
  DateTime? ngayBatDau;
  DateTime? hanHoanThanh;

  // Kiểm tra trạng thái đang lưu
  bool dangLuu = false;

  @override
  void dispose() {
    tenController.dispose();
    moTaController.dispose();
    super.dispose();
  }

  // Chọn ngày
  Future<DateTime?> chonNgay(DateTime? ngayHienTai) async {
    return await showDatePicker(
      context: context,
      initialDate: ngayHienTai ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
  }

  // Hiển thị ngày
  String hienThiNgay(DateTime? ngay) {
    if (ngay == null) return 'Chọn ngày';

    return '${ngay.day.toString().padLeft(2, '0')}/'
        '${ngay.month.toString().padLeft(2, '0')}/'
        '${ngay.year}';
  }

  // TẠO CÔNG VIỆC VÀ LƯU VÀO MONGODB
  Future<void> taoCongViec() async {
    final ten = tenController.text.trim();

    // 1. Kiểm tra tên công việc
    if (ten.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên công việc'),
        ),
      );
      return;
    }

    // 2. Kiểm tra ngày
    if (ngayBatDau == null || hanHoanThanh == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn đầy đủ ngày'),
        ),
      );
      return;
    }

    // 3. Kiểm tra hạn hoàn thành
    if (hanHoanThanh!.isBefore(ngayBatDau!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hạn hoàn thành không được trước ngày bắt đầu',
          ),
        ),
      );
      return;
    }

    // 4. Tránh nhấn nút nhiều lần
    if (dangLuu) return;

    setState(() {
      dangLuu = true;
    });

    try {
      // 5. Gửi dữ liệu lên Node.js và MongoDB
      await TaskService.createTask(
        token: widget.token,
        title: ten,
        description: moTaController.text.trim(),
        priority: mucUuTien,
        startDate: ngayBatDau!,
        dueDate: hanHoanThanh!,
      );

      if (!mounted) return;

      // 6. Quay về danh sách khi lưu thành công
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      // 7. Hiển thị lỗi nếu lưu thất bại
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          dangLuu = false;
        });
      }
    }
  }

  // Giao diện chọn mức ưu tiên
  Widget nutUuTien(String ten, IconData icon, Color mau) {
    final dangChon = mucUuTien == ten;

    return Expanded(
      child: InkWell(
        onTap: dangLuu
            ? null
            : () {
          setState(() {
            mucUuTien = ten;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: dangChon
                ? mau.withValues(alpha: 0.12)
                : Colors.white,
            border: Border.all(
              color: dangChon ? mau : Colors.grey.shade300,
              width: dangChon ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, color: mau),
              const SizedBox(height: 6),
              Text(
                ten,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),

      appBar: AppBar(
        title: const Text('Tạo công việc'),
        centerTitle: true,
        backgroundColor: mauTim,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TÊN CÔNG VIỆC
            const Text(
              'Tên công việc *',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: tenController,
              enabled: !dangLuu,
              decoration: const InputDecoration(
                hintText: 'Nhập tên công việc...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // 2. MÔ TẢ
            const Text(
              'Mô tả',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: moTaController,
              enabled: !dangLuu,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Nhập mô tả công việc...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // 3. NGƯỜI PHỤ TRÁCH
            const Text(
              'Người phụ trách',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const TextField(
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'Tôi',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // 4. MỨC ĐỘ ƯU TIÊN
            const Text(
              'Mức độ ưu tiên',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                nutUuTien(
                  'Thấp',
                  Icons.circle,
                  Colors.green,
                ),
                nutUuTien(
                  'Trung bình',
                  Icons.star,
                  Colors.amber,
                ),
                nutUuTien(
                  'Cao',
                  Icons.favorite,
                  Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 5. NGÀY BẮT ĐẦU
            const Text(
              'Ngày bắt đầu',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              leading: const Icon(Icons.calendar_today),
              title: Text(hienThiNgay(ngayBatDau)),
              onTap: dangLuu
                  ? null
                  : () async {
                final ngay = await chonNgay(ngayBatDau);

                if (!mounted) return;

                if (ngay != null) {
                  setState(() {
                    ngayBatDau = ngay;
                  });
                }
              },
            ),

            const SizedBox(height: 20),

            // 6. HẠN HOÀN THÀNH
            const Text(
              'Hạn hoàn thành',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              leading: const Icon(Icons.event),
              title: Text(hienThiNgay(hanHoanThanh)),
              onTap: dangLuu
                  ? null
                  : () async {
                final ngay = await chonNgay(hanHoanThanh);

                if (!mounted) return;

                if (ngay != null) {
                  setState(() {
                    hanHoanThanh = ngay;
                  });
                }
              },
            ),

            const SizedBox(height: 30),

            // 7. NÚT HỦY VÀ TẠO CÔNG VIỆC
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: dangLuu
                        ? null
                        : () {
                      Navigator.pop(context);
                    },
                    child: const Text('Hủy'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    onPressed: dangLuu ? null : taoCongViec,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mauTim,
                      foregroundColor: Colors.white,
                    ),
                    child: dangLuu
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text('Tạo công việc'),
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
