
import 'package:flutter/material.dart';

import 'task_edit_screen.dart';
import '../services/task_service.dart';

// MÀN HÌNH CHI TIẾT CÔNG VIỆC
class TaskDetailScreen extends StatefulWidget {
  final Map<String, dynamic> task;
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

  late Map<String, dynamic> congViec;

  bool dangXoa = false;
  bool dangGiao = false;

  String? tenNguoiDuocGiao;

  @override
  void initState() {
    super.initState();

    congViec = Map<String, dynamic>.from(widget.task);
    capNhatTenNguoiPhuTrach();
  }

  // 1. LẤY THÔNG TIN NGƯỜI PHỤ TRÁCH
  void capNhatTenNguoiPhuTrach() {
    final nguoiNhan = congViec['assignedTo'];

    if (nguoiNhan is Map) {
      final ten = nguoiNhan['fullName'] ??
          nguoiNhan['name'] ??
          nguoiNhan['email'];

      tenNguoiDuocGiao = ten?.toString();
    } else {
      // API hiện tại có thể chỉ trả về ID
      tenNguoiDuocGiao = null;
    }
  }

  // 2. ĐỊNH DẠNG NGÀY
  String hienThiNgay(dynamic ngay) {
    if (ngay == null) return 'Chưa có';

    final date = DateTime.tryParse(ngay.toString());

    if (date == null) return 'Không hợp lệ';

    final localDate = date.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }

  // 3. HIỂN THỊ DÒNG THÔNG TIN
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
          Icon(
            icon,
            color: mauTim,
            size: 23,
          ),
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

  // 4. HIỂN THỊ THÔNG BÁO
  void thongBao(
      String noiDung, {
        bool laLoi = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(noiDung),
        backgroundColor:
        laLoi ? Colors.red : mauTim,
      ),
    );
  }

  // 5. CHỈNH SỬA CÔNG VIỆC
  Future<void> moChinhSuaCongViec() async {
    if (dangXoa || dangGiao) return;

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

    if (ketQua != null) {
      setState(() {
        congViec = Map<String, dynamic>.from(ketQua);
        capNhatTenNguoiPhuTrach();
      });

      thongBao('Cập nhật công việc thành công!');
    }
  }

  // 6. XÓA CÔNG VIỆC
  Future<void> xoaCongViec() async {
    if (dangXoa || dangGiao) return;

    final xacNhan = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text(
            'Bạn có chắc chắn muốn xóa công việc '
                '"${congViec['title']}" không?\n\n'
                'Công việc đã xóa sẽ không thể khôi phục.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Xóa',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (xacNhan != true || !mounted) return;

    setState(() {
      dangXoa = true;
    });

    try {
      final taskId = congViec['_id']?.toString();

      if (taskId == null || taskId.isEmpty) {
        throw Exception('Không tìm thấy ID công việc');
      }

      await TaskService.deleteTask(
        token: widget.token,
        taskId: taskId,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      thongBao(
        error.toString().replaceFirst(
          'Exception: ',
          '',
        ),
        laLoi: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          dangXoa = false;
        });
      }
    }
  }

  // 7. MỞ HỘP THOẠI GIAO CÔNG VIỆC
  Future<void> moGiaoCongViec() async {
    if (dangXoa || dangGiao) return;

    final taskId = congViec['_id']?.toString();

    if (taskId == null || taskId.isEmpty) {
      thongBao(
        'Không tìm thấy ID công việc',
        laLoi: true,
      );
      return;
    }

    // Hộp thoại trả về dữ liệu sau khi giao thành công
    final ketQua =
    await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return GiaoCongViecDialog(
          token: widget.token,
          taskId: taskId,
          tenCongViec:
          congViec['title']?.toString() ?? '',
        );
      },
    );

    // Không cập nhật State khi màn hình đã đóng
    if (!mounted || ketQua == null) return;

    final task = ketQua['task'];
    final assignee = ketQua['assignee'];

    setState(() {
      if (task is Map) {
        congViec = Map<String, dynamic>.from(task);
      }

      if (assignee is Map) {
        final ten = assignee['fullName'] ??
            assignee['name'];

        final email = assignee['email'];

        if (ten != null &&
            ten.toString().trim().isNotEmpty) {
          tenNguoiDuocGiao = ten.toString();
        } else {
          tenNguoiDuocGiao = email?.toString();
        }
      }
    });

    thongBao('Giao công việc thành công!');
  }

  // 8. GIAO DIỆN CHI TIẾT
  @override
  Widget build(BuildContext context) {
    final ten = congViec['title']?.toString() ?? '';

    final moTa =
        congViec['description']?.toString() ?? '';

    final uuTien =
        congViec['priority']?.toString() ??
            'Trung bình';

    final trangThai =
        congViec['status']?.toString() ??
            'Chưa thực hiện';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),

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
                    dongThongTin(
                      Icons.description,
                      'Mô tả',
                      moTa.isEmpty
                          ? 'Không có mô tả'
                          : moTa,
                    ),

                    const Divider(),

                    dongThongTin(
                      Icons.person,
                      'Người phụ trách',
                      tenNguoiDuocGiao ??
                          'Chưa có thông tin tên người phụ trách',
                    ),

                    const Divider(),

                    dongThongTin(
                      Icons.flag,
                      'Mức độ ưu tiên',
                      uuTien,
                    ),

                    const Divider(),

                    dongThongTin(
                      Icons.pending_actions,
                      'Trạng thái',
                      trangThai,
                    ),

                    const Divider(),

                    dongThongTin(
                      Icons.calendar_today,
                      'Ngày bắt đầu',
                      hienThiNgay(
                        congViec['startDate'],
                      ),
                    ),

                    const Divider(),

                    dongThongTin(
                      Icons.event,
                      'Hạn hoàn thành',
                      hienThiNgay(
                        congViec['dueDate'],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // NÚT GIAO CÔNG VIỆC
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                dangXoa || dangGiao
                    ? null
                    : moGiaoCongViec,
                style: ElevatedButton.styleFrom(
                  backgroundColor: mauTim,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
                icon: const Icon(
                  Icons.person_add,
                ),
                label: const Text(
                  'Giao công việc',
                ),
              ),
            ),

            const SizedBox(height: 12),

            // NÚT CHỈNH SỬA VÀ XÓA
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                    dangXoa || dangGiao
                        ? null
                        : moChinhSuaCongViec,
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor: mauTim,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(
                      Icons.edit,
                    ),
                    label: const Text(
                      'Chỉnh sửa',
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                    dangXoa || dangGiao
                        ? null
                        : xoaCongViec,
                    style:
                    OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(
                        color: Colors.red,
                      ),
                    ),
                    icon: dangXoa
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(
                      Icons.delete,
                    ),
                    label: Text(
                      dangXoa
                          ? 'Đang xóa...'
                          : 'Xóa',
                    ),
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

// HỘP THOẠI GIAO CÔNG VIỆC RIÊNG
// Giúp quản lý State và Controller an toàn hơn
class GiaoCongViecDialog extends StatefulWidget {
  final String token;
  final String taskId;
  final String tenCongViec;

  const GiaoCongViecDialog({
    super.key,
    required this.token,
    required this.taskId,
    required this.tenCongViec,
  });

  @override
  State<GiaoCongViecDialog> createState() =>
      _GiaoCongViecDialogState();
}

class _GiaoCongViecDialogState
    extends State<GiaoCongViecDialog> {
  static const Color mauTim = Color(0xFF6554C0);

  final TextEditingController emailController =
  TextEditingController();

  Map<String, dynamic>? nguoiDuocChon;

  bool dangTim = false;
  bool dangLuu = false;

  String? loi;

  @override
  void dispose() {
    // Chỉ giải phóng Controller khi Widget bị hủy
    emailController.dispose();
    super.dispose();
  }

  // 1. TÌM TÀI KHOẢN THEO EMAIL
  Future<void> timNguoiDung() async {
    final email =
    emailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      setState(() {
        loi = 'Vui lòng nhập email người nhận';
      });
      return;
    }

    setState(() {
      dangTim = true;
      loi = null;
      nguoiDuocChon = null;
    });

    try {
      final user =
      await TaskService.findUserByEmail(
        token: widget.token,
        email: email,
      );

      if (!mounted) return;

      setState(() {
        nguoiDuocChon = user;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loi = error
            .toString()
            .replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          dangTim = false;
        });
      }
    }
  }

  // 2. XÁC NHẬN GIAO CÔNG VIỆC
  Future<void> xacNhanGiaoViec() async {
    if (nguoiDuocChon == null ||
        dangTim ||
        dangLuu) {
      return;
    }

    final userId =
    nguoiDuocChon!['_id']?.toString();

    if (userId == null || userId.isEmpty) {
      setState(() {
        loi = 'Không tìm thấy ID người nhận';
      });
      return;
    }

    setState(() {
      dangLuu = true;
      loi = null;
    });

    try {
      final ketQua =
      await TaskService.assignTask(
        token: widget.token,
        taskId: widget.taskId,
        userId: userId,
      );

      if (!mounted) return;

      // Đóng hộp thoại và trả kết quả về màn hình cha
      // Không gọi setState sau khi Navigator.pop
      Navigator.pop(context, ketQua);
      return;
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loi = error
            .toString()
            .replaceFirst('Exception: ', '');
        dangLuu = false;
      });
    }
  }

  // 3. GIAO DIỆN HỘP THOẠI
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Giao công việc',
      ),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              'Công việc: ${widget.tenCongViec}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: emailController,
              enabled: !dangTim && !dangLuu,
              keyboardType:
              TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email người nhận',
                hintText:
                'Nhập email tài khoản',
                prefixIcon: Icon(
                  Icons.email,
                ),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                setState(() {
                  nguoiDuocChon = null;
                  loi = null;
                });
              },
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                dangTim || dangLuu
                    ? null
                    : timNguoiDung,
                icon: dangTim
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(
                  Icons.search,
                ),
                label: Text(
                  dangTim
                      ? 'Đang tìm...'
                      : 'Tìm tài khoản',
                ),
              ),
            ),

            // HIỂN THỊ TÀI KHOẢN TÌM ĐƯỢC
            if (nguoiDuocChon != null) ...[
              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0ECFF),
                  borderRadius:
                  BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đã tìm thấy tài khoản',
                      style: TextStyle(
                        fontWeight:
                        FontWeight.bold,
                        color: mauTim,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      (nguoiDuocChon!['fullName'] ??
                          nguoiDuocChon!['name'] ??
                          'Người dùng')
                          .toString(),
                    ),

                    Text(
                      (nguoiDuocChon!['email'] ??
                          '')
                          .toString(),
                    ),
                  ],
                ),
              ),
            ],

            // HIỂN THỊ LỖI
            if (loi != null) ...[
              const SizedBox(height: 12),

              Text(
                loi!,
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed:
          dangTim || dangLuu
              ? null
              : () {
            Navigator.pop(context);
          },
          child: const Text(
            'Hủy',
          ),
        ),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: mauTim,
            foregroundColor: Colors.white,
          ),
          onPressed:
          nguoiDuocChon == null ||
              dangTim ||
              dangLuu
              ? null
              : xacNhanGiaoViec,
          child: Text(
            dangLuu
                ? 'Đang giao...'
                : 'Xác nhận giao',
          ),
        ),
      ],
    );
  }
}
