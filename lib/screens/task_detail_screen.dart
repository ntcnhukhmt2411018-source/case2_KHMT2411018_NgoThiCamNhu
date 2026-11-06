
import 'dart:convert';
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

  // 1. LẤY ID NGƯỜI DÙNG
  String layId(dynamic giaTri) {
    if (giaTri is Map) {
      return (giaTri['_id'] ?? giaTri['id'] ?? '').toString();
    }
    return giaTri?.toString() ?? '';
  }

  // 2. LẤY ID NGƯỜI ĐĂNG NHẬP
  String get userIdHienTai {
    try {
      final parts = widget.token.split('.');
      if (parts.length != 3) return '';

      final payload = jsonDecode(
        utf8.decode(
          base64Url.decode(
            base64Url.normalize(parts[1]),
          ),
        ),
      );

      return (payload['id'] ?? payload['userId'] ?? '')
          .toString();
    } catch (_) {
      return '';
    }
  }

  // 3. KIỂM TRA NGƯỜI TẠO
  bool get laNguoiTao {
    return userIdHienTai.isNotEmpty &&
        userIdHienTai == layId(congViec['createdBy']);
  }

  // 4. LẤY TÊN NGƯỜI PHỤ TRÁCH
  void capNhatTenNguoiPhuTrach() {
    final nguoiNhan = congViec['assignedTo'];

    if (nguoiNhan is Map) {
      final ten = nguoiNhan['fullName'] ??
          nguoiNhan['name'] ??
          nguoiNhan['email'];

      tenNguoiDuocGiao = ten?.toString();
    } else {
      tenNguoiDuocGiao = null;
    }
  }

  // 5. ĐỊNH DẠNG NGÀY
  String hienThiNgay(dynamic ngay) {
    if (ngay == null) return 'Chưa có';

    final date = DateTime.tryParse(ngay.toString());
    if (date == null) return 'Không hợp lệ';

    final localDate = date.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }

  // 6. HIỂN THỊ THÔNG TIN
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

  // 7. THÔNG BÁO
  void thongBao(
      String noiDung, {
        bool laLoi = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(noiDung),
        backgroundColor: laLoi ? Colors.red : mauTim,
      ),
    );
  }

  // 8. CHỈNH SỬA CÔNG VIỆC
  Future<void> moChinhSuaCongViec() async {
    if (dangXoa || dangGiao || !laNguoiTao) return;

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

  // 9. XÓA CÔNG VIỆC
  Future<void> xoaCongViec() async {
    if (dangXoa || dangGiao || !laNguoiTao) return;

    final xacNhan = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa công việc '
              '"${congViec['title']}" không?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text(
              'Xóa',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (xacNhan != true || !mounted) return;

    setState(() => dangXoa = true);

    try {
      final taskId = layId(congViec['_id']);

      await TaskService.deleteTask(
        token: widget.token,
        taskId: taskId,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      thongBao(
        error.toString().replaceFirst('Exception: ', ''),
        laLoi: true,
      );
    } finally {
      if (mounted) {
        setState(() => dangXoa = false);
      }
    }
  }

  // 10. GIAO CÔNG VIỆC CHO NHIỀU NGƯỜI (C.1)
  Future<void> moGiaoCongViec() async {
    if (dangXoa || dangGiao || !laNguoiTao) return;

    final taskId = layId(congViec['_id']);

    if (taskId.isEmpty) {
      thongBao('Không tìm thấy ID công việc', laLoi: true);
      return;
    }

    final ketQua =
    await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GiaoNhieuNguoiDialog(
        token: widget.token,
        taskId: taskId,
        tenCongViec: congViec['title']?.toString() ?? '',
        assignedUsers: congViec['assignedUsers'],
        primaryUserId: layId(congViec['assignedTo']),
        currentUserId: userIdHienTai,
      ),
    );

    if (!mounted || ketQua == null) return;

    setState(() {
      if (ketQua['task'] is Map) {
        congViec = Map<String, dynamic>.from(
          ketQua['task'],
        );
      }

      capNhatTenNguoiPhuTrach();

      final danhSach = ketQua['assignedUsers'];

      if (danhSach is List) {
        final primaryId = layId(congViec['assignedTo']);

        for (final user in danhSach) {
          if (user is Map &&
              layId(user) == primaryId) {
            tenNguoiDuocGiao =
                (user['fullName'] ??
                    user['name'] ??
                    user['email'])
                    ?.toString();
            break;
          }
        }
      }
    });

    thongBao('Giao công việc thành công!');
  }

  // 11. CHIA SẺ CÔNG VIỆC (C.3)
  Future<void> moChiaSeCongViec() async {
    if (dangXoa || dangGiao || !laNguoiTao) return;

    final taskId = layId(congViec['_id']);

    if (taskId.isEmpty) {
      thongBao('Không tìm thấy ID công việc', laLoi: true);
      return;
    }

    final ketQua =
    await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GiaoCongViecDialog(
        token: widget.token,
        taskId: taskId,
        tenCongViec: congViec['title']?.toString() ?? '',
        chiaSe: true,
      ),
    );

    if (!mounted || ketQua == null) return;

    if (ketQua['task'] is Map) {
      setState(() {
        congViec = Map<String, dynamic>.from(
          ketQua['task'],
        );
      });
    }

    thongBao('Chia sẻ công việc thành công!');
  }

  // 12. GIAO DIỆN CHI TIẾT
  @override
  Widget build(BuildContext context) {
    final ten = congViec['title']?.toString() ?? '';
    final moTa = congViec['description']?.toString() ?? '';
    final uuTien =
        congViec['priority']?.toString() ?? 'Trung bình';
    final trangThai =
        congViec['status']?.toString() ??
            'Chưa thực hiện';

    final assignedUsers = congViec['assignedUsers'];
    final soNguoiDuocGiao = assignedUsers is List
        ? assignedUsers.length
        : 0;

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
            Text(
              ten,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

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
                      'Người phụ trách chính',
                      tenNguoiDuocGiao ??
                          'Chưa có thông tin tên người phụ trách',
                    ),
                    const Divider(),
                    dongThongTin(
                      Icons.people,
                      'Số người được giao',
                      soNguoiDuocGiao > 0
                          ? '$soNguoiDuocGiao người'
                          : 'Chưa có danh sách',
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
                      hienThiNgay(congViec['startDate']),
                    ),
                    const Divider(),
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

            if (laNguoiTao) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: dangXoa || dangGiao
                      ? null
                      : moGiaoCongViec,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mauTim,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.group_add),
                  label: const Text(
                    'Giao công việc cho nhiều người',
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: dangXoa || dangGiao
                      ? null
                      : moChiaSeCongViec,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mauTim,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.share),
                  label: const Text('Chia sẻ công việc'),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: dangXoa || dangGiao
                          ? null
                          : moChinhSuaCongViec,
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
                      onPressed: dangXoa || dangGiao
                          ? null
                          : xoaCongViec,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(
                          color: Colors.red,
                        ),
                      ),
                      icon: const Icon(Icons.delete),
                      label: const Text('Xóa'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// HỘP THOẠI GIAO CÔNG VIỆC CHO NHIỀU NGƯỜI
class GiaoNhieuNguoiDialog extends StatefulWidget {
  final String token;
  final String taskId;
  final String tenCongViec;
  final dynamic assignedUsers;
  final String primaryUserId;
  final String currentUserId;

  const GiaoNhieuNguoiDialog({
    super.key,
    required this.token,
    required this.taskId,
    required this.tenCongViec,
    required this.assignedUsers,
    required this.primaryUserId,
    required this.currentUserId,
  });

  @override
  State<GiaoNhieuNguoiDialog> createState() =>
      _GiaoNhieuNguoiDialogState();
}

class _GiaoNhieuNguoiDialogState
    extends State<GiaoNhieuNguoiDialog> {
  static const Color mauTim = Color(0xFF6554C0);

  final TextEditingController emailController =
  TextEditingController();

  final List<Map<String, dynamic>> danhSachNguoi = [];

  Map<String, dynamic>? nguoiTimThay;

  String? nguoiPhuTrachChinh;
  String? loi;

  bool dangTim = false;
  bool dangLuu = false;

  @override
  void initState() {
    super.initState();

    nguoiPhuTrachChinh =
    widget.primaryUserId.isNotEmpty
        ? widget.primaryUserId
        : null;

    // Nạp những người đã được giao trước đó
    if (widget.assignedUsers is List) {
      for (final item in widget.assignedUsers) {
        if (item is Map) {
          final user = Map<String, dynamic>.from(item);
          final id = user['_id']?.toString() ?? '';

          if (id.isNotEmpty &&
              !danhSachNguoi.any(
                    (u) => u['_id'].toString() == id,
              )) {
            danhSachNguoi.add(user);
          }
        }
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  // 1. TÌM NGƯỜI DÙNG THEO EMAIL
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
      nguoiTimThay = null;
    });

    try {
      final user = await TaskService.findUserByEmail(
        token: widget.token,
        email: email,
      );

      if (!mounted) return;

      final userId = user['_id']?.toString() ?? '';

      if (userId.isEmpty) {
        throw Exception('Không tìm thấy ID tài khoản');
      }

      if (danhSachNguoi.any(
            (u) => u['_id'].toString() == userId,
      )) {
        setState(() {
          loi = 'Người này đã có trong danh sách';
        });
        return;
      }

      setState(() {
        nguoiTimThay = user;
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
        setState(() => dangTim = false);
      }
    }
  }

  // 2. THÊM NGƯỜI VÀO DANH SÁCH
  void themNguoi() {
    if (nguoiTimThay == null) return;

    final userId =
        nguoiTimThay!['_id']?.toString() ?? '';

    if (userId.isEmpty) return;

    if (danhSachNguoi.any(
          (u) => u['_id'].toString() == userId,
    )) {
      setState(() {
        loi = 'Người này đã có trong danh sách';
      });
      return;
    }

    setState(() {
      danhSachNguoi.add(nguoiTimThay!);

      // Mặc định người đầu tiên là phụ trách chính
      nguoiPhuTrachChinh ??= userId;

      nguoiTimThay = null;
      emailController.clear();
      loi = null;
    });
  }

  // 3. XÓA NGƯỜI KHỎI DANH SÁCH ĐANG CHỌN
  void xoaNguoi(String userId) {
    setState(() {
      danhSachNguoi.removeWhere(
            (user) => user['_id'].toString() == userId,
      );

      if (nguoiPhuTrachChinh == userId) {
        nguoiPhuTrachChinh = danhSachNguoi.isNotEmpty
            ? danhSachNguoi.first['_id'].toString()
            : null;
      }
    });
  }

  // 4. XÁC NHẬN GIAO CÔNG VIỆC
  Future<void> xacNhanGiao() async {
    if (dangTim || dangLuu) return;

    if (danhSachNguoi.isEmpty) {
      setState(() {
        loi = 'Vui lòng thêm ít nhất một người';
      });
      return;
    }

    final userIds = danhSachNguoi
        .map((user) => user['_id'].toString())
        .toList();

    if (nguoiPhuTrachChinh == null ||
        !userIds.contains(nguoiPhuTrachChinh)) {
      setState(() {
        loi = 'Vui lòng chọn người phụ trách chính';
      });
      return;
    }

    setState(() {
      dangLuu = true;
      loi = null;
    });

    try {
      final ketQua = await TaskService.assignManyTasks(
        token: widget.token,
        taskId: widget.taskId,
        userIds: userIds,
        primaryUserId: nguoiPhuTrachChinh,
      );

      if (!mounted) return;

      Navigator.pop(context, ketQua);
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

  // 5. GIAO DIỆN
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Giao công việc cho nhiều người'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email người nhận',
                  hintText: 'Nhập email tài khoản',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) {
                  setState(() {
                    nguoiTimThay = null;
                    loi = null;
                  });
                },
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: dangTim || dangLuu
                      ? null
                      : timNguoiDung,
                  icon: dangTim
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.search),
                  label: Text(
                    dangTim
                        ? 'Đang tìm...'
                        : 'Tìm tài khoản',
                  ),
                ),
              ),

              // TÀI KHOẢN VỪA TÌM THẤY
              if (nguoiTimThay != null) ...[
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0ECFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đã tìm thấy tài khoản',
                        style: TextStyle(
                          color: mauTim,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        (nguoiTimThay!['fullName'] ??
                            nguoiTimThay!['name'] ??
                            'Người dùng')
                            .toString(),
                      ),
                      Text(
                        (nguoiTimThay!['email'] ?? '')
                            .toString(),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: themNguoi,
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm người'),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              Text(
                'Danh sách người được chọn '
                    '(${danhSachNguoi.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              if (danhSachNguoi.isEmpty)
                const Text(
                  'Chưa có người nào được chọn',
                  style: TextStyle(color: Colors.grey),
                ),

              // DANH SÁCH NGƯỜI ĐƯỢC GIAO
              ...danhSachNguoi.map((user) {
                final userId =
                    user['_id']?.toString() ?? '';

                final ten = (user['fullName'] ??
                    user['name'] ??
                    'Người dùng')
                    .toString();

                final email =
                (user['email'] ?? '').toString();

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding:
                        const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(
                          ten,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          email,
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        trailing: IconButton(
                          tooltip: 'Bỏ khỏi danh sách chọn',
                          onPressed: dangLuu
                              ? null
                              : () => xoaNguoi(userId),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.red,
                          ),
                        ),
                      ),


                      ListTile(
                        title: const Text(
                          'Người phụ trách chính',
                          style: TextStyle(fontSize: 13),
                        ),
                        leading: Icon(
                          nguoiPhuTrachChinh == userId
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: mauTim,
                        ),
                        onTap: dangLuu
                            ? null
                            : () {
                          setState(() {
                            nguoiPhuTrachChinh = userId;
                          });
                        },
                      ),

                    ],
                  ),
                );
              }),

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
      ),
      actions: [
        TextButton(
          onPressed: dangTim || dangLuu
              ? null
              : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: mauTim,
            foregroundColor: Colors.white,
          ),
          onPressed: danhSachNguoi.isEmpty ||
              dangTim ||
              dangLuu
              ? null
              : xacNhanGiao,
          child: Text(
            dangLuu
                ? 'Đang giao...'
                : 'Giao công việc',
          ),
        ),
      ],
    );
  }
}

// HỘP THOẠI CHIA SẺ CÔNG VIỆC (GIỮ NGUYÊN C.3)
class GiaoCongViecDialog extends StatefulWidget {
  final String token;
  final String taskId;
  final String tenCongViec;
  final bool chiaSe;

  const GiaoCongViecDialog({
    super.key,
    required this.token,
    required this.taskId,
    required this.tenCongViec,
    this.chiaSe = false,
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
    emailController.dispose();
    super.dispose();
  }

  // TÌM TÀI KHOẢN
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
      final user = await TaskService.findUserByEmail(
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
        setState(() => dangTim = false);
      }
    }
  }

  // XÁC NHẬN CHIA SẺ
  Future<void> xacNhan() async {
    if (nguoiDuocChon == null ||
        dangTim ||
        dangLuu) {
      return;
    }

    final userId =
        nguoiDuocChon!['_id']?.toString() ?? '';

    if (userId.isEmpty) {
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
      final ketQua = widget.chiaSe
          ? await TaskService.shareTask(
        token: widget.token,
        taskId: widget.taskId,
        userId: userId,
      )
          : await TaskService.assignTask(
        token: widget.token,
        taskId: widget.taskId,
        userId: userId,
      );

      if (!mounted) return;

      Navigator.pop(context, ketQua);
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.chiaSe
            ? 'Chia sẻ công việc'
            : 'Giao công việc',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email người nhận',
                hintText: 'Nhập email tài khoản',
                prefixIcon: Icon(Icons.email),
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
                onPressed: dangTim || dangLuu
                    ? null
                    : timNguoiDung,
                icon: dangTim
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.search),
                label: Text(
                  dangTim
                      ? 'Đang tìm...'
                      : 'Tìm tài khoản',
                ),
              ),
            ),

            if (nguoiDuocChon != null) ...[
              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0ECFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đã tìm thấy tài khoản',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
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
                      (nguoiDuocChon!['email'] ?? '')
                          .toString(),
                    ),
                  ],
                ),
              ),
            ],

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
          onPressed: dangTim || dangLuu
              ? null
              : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: mauTim,
            foregroundColor: Colors.white,
          ),
          onPressed: nguoiDuocChon == null ||
              dangTim ||
              dangLuu
              ? null
              : xacNhan,
          child: Text(
            dangLuu
                ? 'Đang xử lý...'
                : widget.chiaSe
                ? 'Xác nhận chia sẻ'
                : 'Xác nhận giao',
          ),
        ),
      ],
    );
  }
}
