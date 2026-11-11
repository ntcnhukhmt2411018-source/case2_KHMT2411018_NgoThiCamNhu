
import 'package:flutter/material.dart';
import '../../services/task_service.dart';

// MÀN HÌNH CHỈNH SỬA CÔNG VIỆC
class TaskEditScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> task;

  const TaskEditScreen({
    super.key,
    required this.token,
    required this.task,
  });

  @override
  State<TaskEditScreen> createState() =>
      _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  static const Color mauTim = Color(0xFF6554C0);

  late TextEditingController tenController;
  late TextEditingController moTaController;

  String mucUuTien = 'Trung bình';
  String trangThai = 'Chưa thực hiện';

  DateTime? ngayBatDau;
  DateTime? hanHoanThanh;

  bool dangLuu = false;

  // 1. LẤY THÔNG TIN CÔNG VIỆC HIỆN TẠI
  @override
  void initState() {
    super.initState();

    tenController = TextEditingController(
      text: widget.task['title']?.toString() ?? '',
    );

    moTaController = TextEditingController(
      text: widget.task['description']?.toString() ?? '',
    );

    final uuTien = widget.task['priority']?.toString();
    if (['Thấp', 'Trung bình', 'Cao'].contains(uuTien)) {
      mucUuTien = uuTien!;
    }

    final status = widget.task['status']?.toString();
    if ([
      'Chưa thực hiện',
      'Đang thực hiện',
      'Đã hoàn thành',
    ].contains(status)) {
      trangThai = status!;
    }

    ngayBatDau = DateTime.tryParse(
      widget.task['startDate']?.toString() ?? '',
    )?.toLocal();

    hanHoanThanh = DateTime.tryParse(
      widget.task['dueDate']?.toString() ?? '',
    )?.toLocal();
  }

  @override
  void dispose() {
    tenController.dispose();
    moTaController.dispose();
    super.dispose();
  }

  // 2. HIỂN THỊ THÔNG BÁO
  void thongBao(String noiDung) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(noiDung)),
    );
  }

  // 3. ĐỊNH DẠNG NGÀY
  String hienThiNgay(DateTime? ngay) {
    if (ngay == null) return 'Chọn ngày';

    return '${ngay.day.toString().padLeft(2, '0')}/'
        '${ngay.month.toString().padLeft(2, '0')}/'
        '${ngay.year}';
  }

  // 4. CHỌN NGÀY
  Future<void> chonNgay(bool laNgayBatDau) async {
    final ngayHienTai =
    laNgayBatDau ? ngayBatDau : hanHoanThanh;

    final ngay = await showDatePicker(
      context: context,
      initialDate: ngayHienTai ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (!mounted || ngay == null) return;

    setState(() {
      if (laNgayBatDau) {
        ngayBatDau = ngay;
      } else {
        hanHoanThanh = ngay;
      }
    });
  }

  // 5. LƯU CÔNG VIỆC VÀO MONGODB
  Future<void> luuThayDoi() async {
    final ten = tenController.text.trim();

    if (ten.isEmpty) {
      thongBao('Vui lòng nhập tên công việc');
      return;
    }

    if (ngayBatDau == null || hanHoanThanh == null) {
      thongBao('Vui lòng chọn đầy đủ ngày');
      return;
    }

    if (hanHoanThanh!.isBefore(ngayBatDau!)) {
      thongBao(
        'Hạn hoàn thành không được trước ngày bắt đầu',
      );
      return;
    }

    final taskId = widget.task['_id']?.toString() ?? '';

    if (taskId.isEmpty) {
      thongBao('Không tìm thấy mã công việc');
      return;
    }

    if (dangLuu) return;

    setState(() {
      dangLuu = true;
    });

    try {
      // GỌI API PUT /api/tasks/:id
      final ketQua = await TaskService.updateTask(
        token: widget.token,
        taskId: taskId,
        title: ten,
        description: moTaController.text.trim(),
        priority: mucUuTien,
        status: trangThai,
        startDate: ngayBatDau!,
        dueDate: hanHoanThanh!,
      );

      if (!mounted) return;

      // Trả công việc đã cập nhật về màn hình Chi tiết
      Navigator.pop(
        context,
        Map<String, dynamic>.from(ketQua['task']),
      );
    } catch (e) {
      if (!mounted) return;

      thongBao(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          dangLuu = false;
        });
      }
    }
  }

  // 6. GIAO DIỆN CHỈNH SỬA
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),

      appBar: AppBar(
        title: const Text('Chỉnh sửa công việc'),
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
            const Text(
              'Tên công việc *',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: tenController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // MÔ TẢ
            const Text(
              'Mô tả',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: moTaController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // MỨC ĐỘ ƯU TIÊN
            const Text(
              'Mức độ ưu tiên',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: mucUuTien,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: ['Thấp', 'Trung bình', 'Cao']
                  .map(
                    (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ),
              )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    mucUuTien = value;
                  });
                }
              },
            ),

            const SizedBox(height: 20),

            // TRẠNG THÁI
            const Text(
              'Trạng thái công việc',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: trangThai,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: [
                'Chưa thực hiện',
                'Đang thực hiện',
                'Đã hoàn thành',
              ]
                  .map(
                    (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ),
              )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    trangThai = value;
                  });
                }
              },
            ),

            const SizedBox(height: 20),

            // NGÀY BẮT ĐẦU
            const Text(
              'Ngày bắt đầu',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ListTile(
              tileColor: Colors.white,
              leading: const Icon(Icons.calendar_today),
              title: Text(hienThiNgay(ngayBatDau)),
              onTap: () => chonNgay(true),
            ),

            const SizedBox(height: 20),

            // HẠN HOÀN THÀNH
            const Text(
              'Hạn hoàn thành',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ListTile(
              tileColor: Colors.white,
              leading: const Icon(Icons.event),
              title: Text(hienThiNgay(hanHoanThanh)),
              onTap: () => chonNgay(false),
            ),

            const SizedBox(height: 30),

            // NÚT LƯU THAY ĐỔI
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: dangLuu ? null : luuThayDoi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: mauTim,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(15),
                ),
                child: dangLuu
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text('Lưu thay đổi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
