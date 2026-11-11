
import 'dart:convert';
import 'package:flutter/material.dart';

import 'task_create_screen.dart';
import 'task_detail_screen.dart';
import '../../services/task_service.dart';
import '../../services/notification_service.dart';

class TaskListScreen extends StatefulWidget {
  final String token;

  const TaskListScreen({
    super.key,
    required this.token,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  static const Color mauTim = Color(0xFF6554C0);
  static const Color nen = Color(0xFFFAF8FF);

  List<dynamic> danhSachCongViec = [];
  bool dangTai = false;
  String? loiTaiDuLieu;
  String? userId;

  final timKiemController = TextEditingController();

  int tabDangChon = 0;
  int soThongBaoChuaDoc = 0;

  final danhSachTab = [
    'Tất cả',
    'Của tôi',
    'Được giao',
    'Được chia sẻ',
  ];

  String locTrangThai = 'Tất cả';
  String locUuTien = 'Tất cả';
  String sapXep = 'Mới tạo nhất';

  final danhSachTrangThai = [
    'Tất cả',
    'Chưa thực hiện',
    'Đang thực hiện',
    'Đã hoàn thành',
  ];

  final danhSachUuTien = [
    'Tất cả',
    'Thấp',
    'Trung bình',
    'Cao',
  ];

  final danhSachSapXep = [
    'Mới tạo nhất',
    'Cũ nhất',
    'Hạn hoàn thành gần nhất',
    'Ưu tiên cao nhất',
  ];

  @override
  void initState() {
    super.initState();
    userId = layUserIdTuToken(widget.token);
    taiDanhSachCongViec();
    taiSoThongBao();
  }

  @override
  void dispose() {
    timKiemController.dispose();
    super.dispose();
  }

  // ==========================================
  // D.7 - THÔNG BÁO TRONG ỨNG DỤNG
  // ==========================================

  Future<void> taiSoThongBao() async {
    try {
      final soLuong =
      await NotificationService.getUnreadCount(widget.token);

      if (!mounted) return;

      setState(() {
        soThongBaoChuaDoc = soLuong;
      });
    } catch (e) {
      debugPrint('Lỗi tải số thông báo: $e');
    }
  }

  Widget nutChuongThongBao() {
    return IconButton(
      tooltip: 'Thông báo',
      onPressed: moThongBao,
      icon: SizedBox(
        width: 32,
        height: 32,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Center(
              child: Icon(
                Icons.notifications_none,
                color: Colors.white,
                size: 28,
              ),
            ),
            if (soThongBaoChuaDoc > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                  ),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    soThongBaoChuaDoc > 99
                        ? '99+'
                        : '$soThongBaoChuaDoc',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> moThongBao() async {
    try {
      final data =
      await NotificationService.getNotifications(widget.token);

      if (!mounted) return;

      final notifications =
      List<dynamic>.from(data['notifications'] ?? []);

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) {
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(sheetContext).size.height * 0.65,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Thông báo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: notifications.isEmpty
                        ? const Center(
                      child: Text('Chưa có thông báo'),
                    )
                        : ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final item = Map<String, dynamic>.from(
                          notifications[index],
                        );

                        final daDoc = item['isRead'] == true;

                        return ListTile(
                          leading: Icon(
                            daDoc
                                ? Icons.notifications_none
                                : Icons.notifications_active,
                            color: daDoc
                                ? Colors.grey
                                : mauTim,
                          ),
                          title: Text(
                            item['title']?.toString() ?? '',
                            style: TextStyle(
                              fontWeight: daDoc
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            item['message']?.toString() ?? '',
                          ),
                          onTap: () async {
                            if (!daDoc) {
                              try {
                                await NotificationService.markAsRead(
                                  widget.token,
                                  item['_id'].toString(),
                                );
                              } catch (e) {
                                if (mounted) {
                                  thongBao(
                                    'Lỗi đánh dấu đã đọc: $e',
                                  );
                                }
                                return;
                              }
                            }

                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                          },
                        );
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        await NotificationService.markAllAsRead(
                          widget.token,
                        );

                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      } catch (e) {
                        if (mounted) {
                          thongBao('Lỗi: $e');
                        }
                      }
                    },
                    child: const Text(
                      'Đánh dấu tất cả đã đọc',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      await taiSoThongBao();
    } catch (e) {
      if (!mounted) return;
      thongBao('Lỗi tải thông báo: $e');
    }
  }

  // ==========================================
  // LẤY ID NGƯỜI ĐĂNG NHẬP
  // ==========================================

  String? layUserIdTuToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = utf8.decode(
        base64Url.decode(
          base64Url.normalize(parts[1]),
        ),
      );

      final data = jsonDecode(payload);

      if (data is! Map) return null;

      return (data['id'] ?? data['userId'])?.toString();
    } catch (e) {
      debugPrint('Lỗi đọc token: $e');
      return null;
    }
  }

  String layId(dynamic giaTri) {
    if (giaTri == null) return '';

    if (giaTri is Map) {
      return (giaTri['_id'] ?? giaTri['id'] ?? '').toString();
    }

    return giaTri.toString();
  }

  bool coTrongDanhSach(dynamic danhSach, String id) {
    if (danhSach is! List) return false;

    return danhSach.any(
          (nguoiDung) => layId(nguoiDung) == id,
    );
  }

  // ==========================================
  // TẢI DANH SÁCH CÔNG VIỆC
  // ==========================================

  Future<void> taiDanhSachCongViec() async {
    if (!mounted) return;

    setState(() {
      dangTai = true;
      loiTaiDuLieu = null;
    });

    try {
      final ketQua =
      await TaskService.getTasks(widget.token);

      if (!mounted) return;

      setState(() {
        danhSachCongViec = ketQua;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loiTaiDuLieu = e
            .toString()
            .replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          dangTai = false;
        });
      }
    }
  }

  // ==========================================
  // TẠO VÀ XEM CHI TIẾT CÔNG VIỆC
  // ==========================================

  Future<void> moTaoCongViec() async {
    final ketQua = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TaskCreateScreen(
          token: widget.token,
        ),
      ),
    );

    if (!mounted) return;

    if (ketQua == true) {
      await taiDanhSachCongViec();

      if (!mounted) return;

      if (loiTaiDuLieu == null) {
        thongBao('Tạo công việc thành công!');
      }
    }
  }

  Future<void> moChiTietCongViec(dynamic congViec) async {
    final ketQua = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(
          token: widget.token,
          task: Map<String, dynamic>.from(congViec),
        ),
      ),
    );

    if (!mounted) return;

    await taiDanhSachCongViec();

    if (!mounted) return;

    if (ketQua == true && loiTaiDuLieu == null) {
      thongBao('Xóa công việc thành công!');
    }
  }

  void thongBao(String noiDung) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(noiDung),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ==========================================
  // XỬ LÝ NGÀY VÀ ƯU TIÊN
  // ==========================================

  DateTime? chuyenNgay(dynamic ngay) {
    if (ngay == null) return null;
    return DateTime.tryParse(ngay.toString());
  }

  String hienThiNgay(dynamic ngay) {
    final date = chuyenNgay(ngay);

    if (date == null) return 'Chưa có hạn';

    final localDate = date.toLocal();

    final ngayText =
    localDate.day.toString().padLeft(2, '0');

    final thangText =
    localDate.month.toString().padLeft(2, '0');

    return '$ngayText/$thangText/${localDate.year}';
  }

  int giaTriUuTien(String uuTien) {
    switch (uuTien) {
      case 'Cao':
        return 3;
      case 'Trung bình':
        return 2;
      case 'Thấp':
        return 1;
      default:
        return 0;
    }
  }

  Color mauUuTien(String uuTien) {
    switch (uuTien) {
      case 'Cao':
        return Colors.red;
      case 'Trung bình':
        return Colors.orange;
      case 'Thấp':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // ==========================================
  // PHÂN LOẠI CÔNG VIỆC THEO VAI TRÒ
  // ==========================================

  bool dungTab(dynamic congViec) {
    if (tabDangChon == 0) return true;

    final id = userId;

    if (id == null || id.isEmpty) {
      return false;
    }

    final nguoiTao = layId(congViec['createdBy']);
    final nguoiPhuTrach = layId(congViec['assignedTo']);

    final laNguoiPhuTrach = nguoiPhuTrach == id;

    final laNguoiDuocGiao = coTrongDanhSach(
      congViec['assignedUsers'],
      id,
    );

    final laNguoiDuocChiaSe = coTrongDanhSach(
      congViec['sharedWith'],
      id,
    );

    switch (tabDangChon) {
      case 1:
        return nguoiTao == id;

      case 2:
        return nguoiTao != id &&
            (laNguoiPhuTrach || laNguoiDuocGiao);

      case 3:
        return nguoiTao != id && laNguoiDuocChiaSe;

      default:
        return true;
    }
  }

  String vaiTroTrongCongViec(dynamic congViec) {
    final id = userId;

    if (id == null || id.isEmpty) {
      return '';
    }

    if (layId(congViec['createdBy']) == id) {
      return 'Người tạo';
    }

    if (layId(congViec['assignedTo']) == id) {
      return 'Người phụ trách chính';
    }

    if (coTrongDanhSach(
      congViec['assignedUsers'],
      id,
    )) {
      return 'Người được giao';
    }

    if (coTrongDanhSach(
      congViec['sharedWith'],
      id,
    )) {
      return 'Người được chia sẻ';
    }

    return '';
  }

  // ==========================================
  // TÌM KIẾM, LỌC VÀ SẮP XẾP
  // ==========================================

  List<dynamic> locCongViec() {
    final tuKhoa =
    timKiemController.text.trim().toLowerCase();

    final ketQua = danhSachCongViec.where((congViec) {
      final ten =
      (congViec['title'] ?? '').toString().toLowerCase();

      final trangThai =
      (congViec['status'] ?? 'Chưa thực hiện').toString();

      final uuTien =
      (congViec['priority'] ?? 'Trung bình').toString();

      return dungTab(congViec) &&
          ten.contains(tuKhoa) &&
          (locTrangThai == 'Tất cả' ||
              trangThai == locTrangThai) &&
          (locUuTien == 'Tất cả' ||
              uuTien == locUuTien);
    }).toList();

    ketQua.sort((a, b) {
      if (sapXep == 'Ưu tiên cao nhất') {
        return giaTriUuTien(
          (b['priority'] ?? '').toString(),
        ).compareTo(
          giaTriUuTien(
            (a['priority'] ?? '').toString(),
          ),
        );
      }

      if (sapXep == 'Hạn hoàn thành gần nhất') {
        final ngayA = chuyenNgay(a['dueDate']);
        final ngayB = chuyenNgay(b['dueDate']);

        if (ngayA == null && ngayB == null) return 0;
        if (ngayA == null) return 1;
        if (ngayB == null) return -1;

        return ngayA.compareTo(ngayB);
      }

      final ngayA = chuyenNgay(a['createdAt']);
      final ngayB = chuyenNgay(b['createdAt']);

      if (ngayA == null && ngayB == null) return 0;
      if (ngayA == null) return 1;
      if (ngayB == null) return -1;

      if (sapXep == 'Cũ nhất') {
        return ngayA.compareTo(ngayB);
      }

      return ngayB.compareTo(ngayA);
    });

    return ketQua;
  }

  // ==========================================
  // E.1 - THỐNG KÊ TIẾN ĐỘ CÔNG VIỆC
  // ==========================================

  Widget oTienDo(
      String nhan,
      int soLuong,
      Color mau,
      ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 4,
        ),
        decoration: BoxDecoration(
          color: mau.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$soLuong',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: mau,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              nhan,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget thongKeTienDo() {
    final danhSach = danhSachCongViec
        .where((congViec) => dungTab(congViec))
        .toList();

    final tong = danhSach.length;

    final chuaLam = danhSach.where(
          (cv) =>
      (cv['status'] ?? 'Chưa thực hiện') ==
          'Chưa thực hiện',
    ).length;

    final dangLam = danhSach.where(
          (cv) => cv['status'] == 'Đang thực hiện',
    ).length;

    final hoanThanh = danhSach.where(
          (cv) => cv['status'] == 'Đã hoàn thành',
    ).length;

    final tiLe = tong == 0 ? 0.0 : hoanThanh / tong;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Theo dõi tiến độ công việc',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              oTienDo('Tổng', tong, mauTim),
              const SizedBox(width: 7),
              oTienDo('Chưa làm', chuaLam, Colors.grey),
              const SizedBox(width: 7),
              oTienDo('Đang làm', dangLam, Colors.orange),
              const SizedBox(width: 7),
              oTienDo('Hoàn thành', hoanThanh, Colors.green),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tỷ lệ hoàn thành',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                '${(tiLe * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: mauTim,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          LinearProgressIndicator(
            value: tiLe,
            minHeight: 10,
            borderRadius: BorderRadius.circular(10),
            backgroundColor: Colors.grey.shade200,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // E.2 - THỐNG KÊ CÔNG VIỆC CỦA TÔI
  // ==========================================

  // Công việc do tôi tạo và giao cho người khác.
  bool laCongViecDaGiao(dynamic congViec) {
    final id = userId;

    if (id == null || id.isEmpty) return false;

    final nguoiTao = layId(congViec['createdBy']);

    if (nguoiTao != id) return false;

    final nguoiPhuTrach = layId(congViec['assignedTo']);

    final nguoiDuocGiao =
    congViec['assignedUsers'] is List
        ? congViec['assignedUsers'] as List
        : [];

    final giaoChoNguoiKhac =
        nguoiPhuTrach.isNotEmpty &&
            nguoiPhuTrach != id;

    final coNguoiKhacTrongDanhSach =
    nguoiDuocGiao.any((nguoi) {
      final nguoiId = layId(nguoi);

      return nguoiId.isNotEmpty && nguoiId != id;
    });

    return giaoChoNguoiKhac ||
        coNguoiKhacTrongDanhSach;
  }

  // Công việc mà tôi được phân công thực hiện.
  bool laCongViecDangPhuTrach(dynamic congViec) {
    final id = userId;

    if (id == null || id.isEmpty) return false;

    if (layId(congViec['assignedTo']) == id) {
      return true;
    }

    return coTrongDanhSach(
      congViec['assignedUsers'],
      id,
    );
  }

  Widget oThongKeE2({
    required String ten,
    required String moTa,
    required int soLuong,
    required IconData icon,
    required Color mauNen,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: mauNen,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: mauTim,
                  size: 24,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    ten,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              '$soLuong',
              style: const TextStyle(
                color: Color(0xFF4D24B0),
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              moTa,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget thongKeCongViecCuaToi() {
    final soDaGiao = danhSachCongViec
        .where(laCongViecDaGiao)
        .length;

    final soDangPhuTrach = danhSachCongViec
        .where(laCongViecDangPhuTrach)
        .length;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: mauTim,
                size: 27,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Thống kê công việc của tôi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              oThongKeE2(
                ten: 'Đã giao',
                moTa: 'Công việc giao cho người khác',
                soLuong: soDaGiao,
                icon: Icons.send_outlined,
                mauNen: const Color(0xFFF4EDFF),
              ),

              const SizedBox(width: 9),

              oThongKeE2(
                ten: 'Đang phụ trách',
                moTa: 'Công việc được giao cho tôi',
                soLuong: soDangPhuTrach,
                icon: Icons.assignment_turned_in_outlined,
                mauNen: const Color(0xFFF0EFFF),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BỘ LỌC VÀ SẮP XẾP
  // ==========================================

  void xoaBoLoc() {
    setState(() {
      locTrangThai = 'Tất cả';
      locUuTien = 'Tất cả';
      sapXep = 'Mới tạo nhất';
    });
  }

  Future<void> moBoLoc() async {
    String trangThaiTam = locTrangThai;
    String uuTienTam = locUuTien;
    String sapXepTam = sapXep;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Lọc và sắp xếp'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Trạng thái'),
                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      key: ValueKey('status-$trangThaiTam'),
                      initialValue: trangThaiTam,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: danhSachTrangThai.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            trangThaiTam = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 20),
                    const Text('Mức độ ưu tiên'),
                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      key: ValueKey('priority-$uuTienTam'),
                      initialValue: uuTienTam,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: danhSachUuTien.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            uuTienTam = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 20),
                    const Text('Sắp xếp theo'),
                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      key: ValueKey('sort-$sapXepTam'),
                      initialValue: sapXepTam,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: danhSachSapXep.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(
                            item,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            sapXepTam = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    xoaBoLoc();
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Xóa lọc'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      locTrangThai = trangThaiTam;
                      locUuTien = uuTienTam;
                      sapXep = sapXepTam;
                    });
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Áp dụng'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // HIỂN THỊ MỘT CÔNG VIỆC
  // ==========================================

  Widget hienThiCongViec(dynamic congViec) {
    final ten =
        congViec['title']?.toString() ?? '';

    final moTa =
        congViec['description']?.toString() ?? '';

    final uuTien =
        congViec['priority']?.toString() ?? 'Trung bình';

    final trangThai =
        congViec['status']?.toString() ?? 'Chưa thực hiện';

    final hanHoanThanh =
    hienThiNgay(congViec['dueDate']);

    final vaiTro =
    vaiTroTrongCongViec(congViec);

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => moChiTietCongViec(congViec),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ten,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                ],
              ),

              if (vaiTro.isNotEmpty) ...[
                const SizedBox(height: 6),
                Chip(
                  label: Text(vaiTro),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: const Color(0xFFEDE9FA),
                  labelStyle: const TextStyle(
                    color: mauTim,
                    fontSize: 12,
                  ),
                ),
              ],

              if (moTa.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  moTa,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(
                    Icons.flag,
                    color: mauUuTien(uuTien),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ưu tiên: $uuTien',
                    style: TextStyle(
                      color: mauUuTien(uuTien),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(
                    Icons.pending_actions,
                    size: 18,
                    color: mauTim,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Trạng thái: $trangThai',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Hạn hoàn thành: $hanHoanThanh',
                    ),
                  ),
                ],
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
    final danhSachHienThi = locCongViec();

    final dangLoc =
        locTrangThai != 'Tất cả' ||
            locUuTien != 'Tất cả' ||
            sapXep != 'Mới tạo nhất';

    return Scaffold(
      backgroundColor: nen,

      appBar: AppBar(
        title: const Text(
          'Danh sách công việc',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: mauTim,
        foregroundColor: Colors.white,
        actions: [
          nutChuongThongBao(),
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await taiDanhSachCongViec();
              await taiSoThongBao();
            },
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          await taiDanhSachCongViec();
          await taiSoThongBao();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 4 TAB PHÂN LOẠI
            SliverToBoxAdapter(
              child: SizedBox(
                height: 55,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: danhSachTab.length,
                  itemBuilder: (context, index) {
                    final dangChon = tabDangChon == index;

                    return Padding(
                      padding: const EdgeInsets.all(5),
                      child: ChoiceChip(
                        label: Text(danhSachTab[index]),
                        selected: dangChon,
                        selectedColor: mauTim,
                        labelStyle: TextStyle(
                          color: dangChon
                              ? Colors.white
                              : Colors.black,
                        ),
                        onSelected: (_) {
                          setState(() {
                            tabDangChon = index;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

            // E.1 + E.2
            if (!dangTai &&
                loiTaiDuLieu == null &&
                userId != null &&
                userId!.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: thongKeTienDo(),
              ),

              SliverToBoxAdapter(
                child: thongKeCongViecCuaToi(),
              ),
            ],

            // TÌM KIẾM
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: timKiemController,
                  onChanged: (_) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm công việc...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      tooltip: 'Lọc và sắp xếp',
                      icon: Icon(
                        Icons.filter_list,
                        color: dangLoc
                            ? mauTim
                            : Colors.grey,
                      ),
                      onPressed: moBoLoc,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

            // BỘ LỌC ĐANG ÁP DỤNG
            if (dangLoc)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.tune,
                        color: mauTim,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Đang áp dụng bộ lọc / sắp xếp',
                          style: TextStyle(
                            color: mauTim,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: xoaBoLoc,
                        child: const Text('Xóa lọc'),
                      ),
                    ],
                  ),
                ),
              ),

            // SỐ CÔNG VIỆC TÌM THẤY
            if (!dangTai && loiTaiDuLieu == null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Text(
                    'Tìm thấy ${danhSachHienThi.length} công việc',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

            // ĐANG TẢI
            if (dangTai)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    color: mauTim,
                  ),
                ),
              )

            // LỖI TẢI DỮ LIỆU
            else if (loiTaiDuLieu != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 45,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          loiTaiDuLieu!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: taiDanhSachCongViec,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                ),
              )

            // KHÔNG ĐỌC ĐƯỢC USER ID
            else if (userId == null && tabDangChon != 0)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Không xác định được tài khoản đăng nhập.',
                    ),
                  ),
                )

              // DANH SÁCH TRỐNG
              else if (danhSachHienThi.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        danhSachCongViec.isEmpty
                            ? 'Chưa có công việc nào.\n'
                            'Nhấn + để tạo công việc mới.'
                            : 'Không tìm thấy công việc phù hợp.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )

                // DANH SÁCH CÔNG VIỆC
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(12),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          return hienThiCongViec(
                            danhSachHienThi[index],
                          );
                        },
                        childCount: danhSachHienThi.length,
                      ),
                    ),
                  ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: mauTim,
        foregroundColor: Colors.white,
        onPressed: moTaoCongViec,
        child: const Icon(Icons.add),
      ),
    );
  }
}
