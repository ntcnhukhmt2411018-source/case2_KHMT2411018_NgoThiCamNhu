
import 'package:flutter/material.dart';
import '../../services/task_service.dart';

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

  // Controller nhập dữ liệu
  final tenController = TextEditingController();
  final moTaController = TextEditingController();

  // Controller cho thanh cuộn bên phải
  final ScrollController scrollController = ScrollController();

  // Thông tin công việc
  String mucUuTien = 'Trung bình';
  DateTime? ngayBatDau;
  DateTime? hanHoanThanh;
  TimeOfDay? gioHoanThanh;

  bool dangLuu = false;

  @override
  void dispose() {
    tenController.dispose();
    moTaController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  // ==========================================
  // CHỌN NGÀY
  // ==========================================
  Future<DateTime?> chonNgay(DateTime? ngayHienTai) async {
    return showDatePicker(
      context: context,
      initialDate: ngayHienTai ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
  }

  // ==========================================
  // CHỌN GIỜ HOÀN THÀNH
  // ==========================================
  Future<void> chonGioHoanThanh() async {
    final gioMacDinh = gioHoanThanh ??
        TimeOfDay.fromDateTime(
          DateTime.now().add(const Duration(hours: 1)),
        );

    final gio = await showTimePicker(
      context: context,
      initialTime: gioMacDinh,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true,
          ),
          child: child!,
        );
      },
    );

    if (!mounted) return;

    if (gio != null) {
      setState(() {
        gioHoanThanh = gio;
      });
    }
  }

  // ==========================================
  // HIỂN THỊ NGÀY
  // ==========================================
  String hienThiNgay(DateTime? ngay) {
    if (ngay == null) {
      return 'Chọn ngày';
    }

    return '${ngay.day.toString().padLeft(2, '0')}/'
        '${ngay.month.toString().padLeft(2, '0')}/'
        '${ngay.year}';
  }

  // ==========================================
  // HIỂN THỊ GIỜ
  // ==========================================
  String hienThiGio(TimeOfDay? gio) {
    if (gio == null) {
      return 'Chọn giờ hoàn thành';
    }

    final hour = gio.hour.toString().padLeft(2, '0');
    final minute = gio.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  // ==========================================
  // HIỂN THỊ THÔNG BÁO
  // ==========================================
  void hienThiThongBao(String noiDung) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(noiDung),
      ),
    );
  }

  // ==========================================
  // TẠO CÔNG VIỆC VÀ LƯU VÀO MONGODB
  // ==========================================
  Future<void> taoCongViec() async {
    final ten = tenController.text.trim();

    // Kiểm tra tên công việc
    if (ten.isEmpty) {
      hienThiThongBao('Vui lòng nhập tên công việc');
      return;
    }

    // Kiểm tra ngày
    if (ngayBatDau == null || hanHoanThanh == null) {
      hienThiThongBao('Vui lòng chọn đầy đủ ngày');
      return;
    }

    // Kiểm tra giờ
    if (gioHoanThanh == null) {
      hienThiThongBao('Vui lòng chọn giờ hoàn thành');
      return;
    }

    // Kết hợp ngày và giờ thành DateTime
    final hanHoanThanhDayDu = DateTime(
      hanHoanThanh!.year,
      hanHoanThanh!.month,
      hanHoanThanh!.day,
      gioHoanThanh!.hour,
      gioHoanThanh!.minute,
    );

    // Kiểm tra ngày bắt đầu
    if (hanHoanThanhDayDu.isBefore(ngayBatDau!)) {
      hienThiThongBao(
        'Hạn hoàn thành không được trước ngày bắt đầu',
      );
      return;
    }

    // Hạn hoàn thành phải sau hiện tại
    if (!hanHoanThanhDayDu.isAfter(DateTime.now())) {
      hienThiThongBao(
        'Hạn hoàn thành phải sau thời điểm hiện tại',
      );
      return;
    }

    // Tránh tạo trùng
    if (dangLuu) return;

    setState(() {
      dangLuu = true;
    });

    try {
      await TaskService.createTask(
        token: widget.token,
        title: ten,
        description: moTaController.text.trim(),
        priority: mucUuTien,
        startDate: ngayBatDau!,
        dueDate: hanHoanThanhDayDu,
      );

      if (!mounted) return;

      // Quay lại danh sách công việc
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      hienThiThongBao(
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

  // ==========================================
  // NÚT CHỌN MỨC ĐỘ ƯU TIÊN
  // ==========================================
  Widget nutUuTien(
      String ten,
      IconData icon,
      Color mau,
      ) {
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
        borderRadius: BorderRadius.circular(10),
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

  // ==========================================
  // GIAO DIỆN CHÍNH
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      resizeToAvoidBottomInset: true,

      appBar: AppBar(
        title: const Text('Tạo công việc'),
        centerTitle: true,
        backgroundColor: mauTim,
        foregroundColor: Colors.white,
      ),

      body: SafeArea(
        child: Scrollbar(
          // Dùng chung controller với màn hình cuộn
          controller: scrollController,

          // Thanh cuộn luôn hiển thị
          thumbVisibility: true,

          // Có thể kéo thanh cuộn bằng chuột
          interactive: true,

          // Độ dày thanh cuộn
          thickness: 8,

          // Bo tròn thanh cuộn
          radius: const Radius.circular(10),

          child: SingleChildScrollView(
            controller: scrollController,

            // Cho phép cuộn
            physics: const AlwaysScrollableScrollPhysics(),

            // Tự ẩn bàn phím khi kéo
            keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior.onDrag,

            // Chừa khoảng trống bên phải và phía dưới
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              26,
              60,
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================
                // 1. TÊN CÔNG VIỆC
                // ==================================
                const Text(
                  'Tên công việc *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
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

                // ==================================
                // 2. MÔ TẢ
                // ==================================
                const Text(
                  'Mô tả',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
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

                // ==================================
                // 3. NGƯỜI PHỤ TRÁCH
                // ==================================
                const Text(
                  'Người phụ trách',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
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

                // ==================================
                // 4. MỨC ĐỘ ƯU TIÊN
                // ==================================
                const Text(
                  'Mức độ ưu tiên',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
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

                // ==================================
                // 5. NGÀY BẮT ĐẦU
                // ==================================
                const Text(
                  'Ngày bắt đầu',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
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
                    final ngay = await chonNgay(
                      ngayBatDau,
                    );

                    if (!mounted) return;

                    if (ngay != null) {
                      setState(() {
                        ngayBatDau = ngay;
                      });
                    }
                  },
                ),

                const SizedBox(height: 20),

                // ==================================
                // 6. HẠN HOÀN THÀNH
                // ==================================
                const Text(
                  'Hạn hoàn thành',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
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
                    final ngay = await chonNgay(
                      hanHoanThanh,
                    );

                    if (!mounted) return;

                    if (ngay != null) {
                      setState(() {
                        hanHoanThanh = ngay;
                      });
                    }
                  },
                ),

                const SizedBox(height: 20),

                // ==================================
                // 7. GIỜ HOÀN THÀNH
                // ==================================
                const Text(
                  'Giờ hoàn thành',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
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
                  leading: const Icon(Icons.access_time),
                  title: Text(hienThiGio(gioHoanThanh)),
                  trailing: const Icon(
                    Icons.arrow_drop_down,
                  ),
                  onTap: dangLuu
                      ? null
                      : chonGioHoanThanh,
                ),

                const SizedBox(height: 30),

                // ==================================
                // 8. NÚT HỦY VÀ TẠO CÔNG VIỆC
                // ==================================
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
                        onPressed: dangLuu
                            ? null
                            : taoCongViec,
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
        ),
      ),
    );
  }
}
