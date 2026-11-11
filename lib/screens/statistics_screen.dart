
import 'dart:convert';
import 'package:flutter/material.dart';

import '../services/task_service.dart';
import '../services/user_service.dart';

class StatisticsScreen extends StatefulWidget {
  final String token;

  const StatisticsScreen({
    super.key,
    required this.token,
  });

  @override
  State<StatisticsScreen> createState() =>
      _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  static const Color mauTim = Color(0xFF6554C0);
  static const Color mauNen = Color(0xFFFAF8FF);

  List<dynamic> danhSachCongViec = [];
  String? userId;
  bool dangTai = true;
  String? thongBaoLoi;

  // E.4 - Lịch sử hoạt động
  String? congViecDuocChon;
  List<dynamic> danhSachLichSu = [];
  bool dangTaiLichSu = false;
  String? loiLichSu;

  @override
  void initState() {
    super.initState();
    taiThongKe();
  }

  // ==========================================
  // CÁC HÀM DÙNG CHUNG
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
      return (giaTri['_id'] ?? giaTri['id'] ?? '')
          .toString();
    }

    return giaTri.toString();
  }

  bool coTrongDanhSach(dynamic danhSach, String id) {
    if (danhSach is! List) return false;

    return danhSach.any(
          (nguoi) => layId(nguoi) == id,
    );
  }

  Future<void> taiThongKe() async {
    if (!mounted) return;

    setState(() {
      dangTai = true;
      thongBaoLoi = null;
    });

    try {
      final ketQua =
      await TaskService.getTasks(widget.token);

      String? id = layUserIdTuToken(widget.token);

      if (id == null || id.isEmpty) {
        try {
          final profile =
          await UserService.getProfile(widget.token);

          final user = profile['user'] ?? profile;
          id = layId(user);
        } catch (e) {
          debugPrint('Không lấy được ID: $e');
        }
      }

      if (!mounted) return;

      final ids = ketQua
          .map((cv) => layId(cv['_id']))
          .toSet();

      final idDaChon =
      ids.contains(congViecDuocChon)
          ? congViecDuocChon
          : null;

      setState(() {
        danhSachCongViec = ketQua;
        userId = id;
        dangTai = false;
        congViecDuocChon = idDaChon;

        if (idDaChon == null) {
          danhSachLichSu = [];
          loiLichSu = null;
          dangTaiLichSu = false;
        }
      });

      if (idDaChon != null) {
        await taiLichSu(idDaChon);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        thongBaoLoi = e
            .toString()
            .replaceFirst('Exception: ', '');
        dangTai = false;
      });
    }
  }

  // ==========================================
  // E.1 - THEO DÕI TIẾN ĐỘ CÔNG VIỆC
  // ==========================================

  Widget oThongKe({
    required String tieuDe,
    required int soLuong,
    required Color mauChu,
    required Color mauNenO,
  }) {
    return Expanded(
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(
          horizontal: 2,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: mauNenO,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$soLuong',
              style: TextStyle(
                color: mauChu,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                tieuDe,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget thongKeTienDo() {
    final tong = danhSachCongViec.length;

    final chuaLam = danhSachCongViec.where((cv) {
      return (cv['status'] ?? 'Chưa thực hiện') ==
          'Chưa thực hiện';
    }).length;

    final dangLam = danhSachCongViec.where((cv) {
      return cv['status'] == 'Đang thực hiện';
    }).length;

    final hoanThanh = danhSachCongViec.where((cv) {
      return cv['status'] == 'Đã hoàn thành';
    }).length;

    final double tiLe =
    tong == 0 ? 0.0 : hoanThanh / tong;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
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
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              oThongKe(
                tieuDe: 'Tổng',
                soLuong: tong,
                mauChu: const Color(0xFF5142D3),
                mauNenO: const Color(0xFFF0EDFF),
              ),
              const SizedBox(width: 5),
              oThongKe(
                tieuDe: 'Chưa làm',
                soLuong: chuaLam,
                mauChu: Colors.grey,
                mauNenO: const Color(0xFFF5F5F5),
              ),
              const SizedBox(width: 5),
              oThongKe(
                tieuDe: 'Đang làm',
                soLuong: dangLam,
                mauChu: Colors.orange,
                mauNenO: const Color(0xFFFFF4E6),
              ),
              const SizedBox(width: 5),
              oThongKe(
                tieuDe: 'Hoàn thành',
                soLuong: hoanThanh,
                mauChu: Colors.green,
                mauNenO: const Color(0xFFEDF8F0),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tỷ lệ hoàn thành',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(tiLe * 100).round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: mauTim,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: tiLe,
              minHeight: 7,
              backgroundColor:
              const Color(0xFFE5E7EB),
              valueColor:
              const AlwaysStoppedAnimation<Color>(
                Color(0xFF4CAF50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // E.2 - THỐNG KÊ CÔNG VIỆC CỦA TÔI
  // ==========================================

  bool laCongViecDaGiao(dynamic congViec) {
    final id = userId;

    if (id == null || id.isEmpty) return false;

    final nguoiTao = layId(congViec['createdBy']);

    if (nguoiTao != id) return false;

    final nguoiPhuTrach =
    layId(congViec['assignedTo']);

    if (nguoiPhuTrach.isNotEmpty &&
        nguoiPhuTrach != id) {
      return true;
    }

    final danhSach = congViec['assignedUsers'];

    if (danhSach is List) {
      return danhSach.any((nguoi) {
        final nguoiId = layId(nguoi);
        return nguoiId.isNotEmpty && nguoiId != id;
      });
    }

    return false;
  }

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

  Widget oThongKeCongViec({
    required String tieuDe,
    required int soLuong,
    required String moTa,
    required IconData icon,
    required Color mauNenO,
  }) {
    return Expanded(
      child: Container(
        constraints:
        const BoxConstraints(minHeight: 130),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: mauNenO,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: mauTim, size: 22),
            const SizedBox(height: 9),
            Text(
              tieuDe,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$soLuong',
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: mauTim,
              ),
            ),
            const SizedBox(height: 6),
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
    final daGiao = danhSachCongViec
        .where(laCongViecDaGiao)
        .length;

    final dangPhuTrach = danhSachCongViec
        .where(laCongViecDangPhuTrach)
        .length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thống kê công việc của tôi',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (userId == null || userId!.isEmpty)
            const Text(
              'Không xác định được tài khoản '
                  'để thống kê công việc.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            )
          else
            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                oThongKeCongViec(
                  tieuDe: 'Đã giao',
                  soLuong: daGiao,
                  moTa:
                  'Công việc giao cho người khác',
                  icon: Icons.send_outlined,
                  mauNenO:
                  const Color(0xFFF2ECFF),
                ),
                const SizedBox(width: 10),
                oThongKeCongViec(
                  tieuDe: 'Đang phụ trách',
                  soLuong: dangPhuTrach,
                  moTa:
                  'Công việc được giao cho tôi',
                  icon: Icons
                      .assignment_turned_in_outlined,
                  mauNenO:
                  const Color(0xFFEFEDFF),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ==========================================
  // E.3 - SẮP ĐẾN HẠN VÀ QUÁ HẠN
  // ==========================================

  DateTime? layHanCongViec(dynamic congViec) {
    if (congViec is! Map) return null;

    final giaTri =
        congViec['dueDate'] ?? congViec['deadline'];

    if (giaTri == null) return null;

    if (giaTri is DateTime) {
      return giaTri.toLocal();
    }

    return DateTime.tryParse(
      giaTri.toString(),
    )?.toLocal();
  }

  DateTime chiLayNgay(DateTime ngay) {
    return DateTime(
      ngay.year,
      ngay.month,
      ngay.day,
    );
  }

  bool daHoanThanh(dynamic congViec) {
    return congViec is Map &&
        congViec['status'] == 'Đã hoàn thành';
  }

  bool sapDenHan(dynamic congViec) {
    if (daHoanThanh(congViec)) return false;

    final han = layHanCongViec(congViec);

    if (han == null) return false;

    final homNay = chiLayNgay(DateTime.now());
    final ngayHan = chiLayNgay(han);

    final soNgay =
        ngayHan.difference(homNay).inDays;

    return soNgay >= 0 && soNgay <= 3;
  }

  bool quaHan(dynamic congViec) {
    if (daHoanThanh(congViec)) return false;

    final han = layHanCongViec(congViec);

    if (han == null) return false;

    return chiLayNgay(han).isBefore(
      chiLayNgay(DateTime.now()),
    );
  }

  String dinhDangNgay(DateTime ngay) {
    final ngayChuoi =
    ngay.day.toString().padLeft(2, '0');

    final thangChuoi =
    ngay.month.toString().padLeft(2, '0');

    return '$ngayChuoi/$thangChuoi/${ngay.year}';
  }

  Widget oThongKeHan({
    required String tieuDe,
    required int soLuong,
    required String moTa,
    required IconData icon,
    required Color mauNenO,
    required Color mauChu,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: mauNenO,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: mauChu,
              size: 22,
            ),
            const SizedBox(height: 8),
            Text(
              tieuDe,
              style: TextStyle(
                color: mauChu,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$soLuong',
              style: TextStyle(
                color: mauChu,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              moTa,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget danhSachTheoHan({
    required String tieuDe,
    required List<dynamic> danhSach,
    required Color mauChu,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                tieuDe,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${danhSach.length} công việc',
              style: TextStyle(
                fontSize: 12,
                color: mauChu,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (danhSach.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(
              vertical: 10,
            ),
            child: Text(
              'Không có công việc nào.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          )
        else
          ...danhSach.map((congViec) {
            final han =
            layHanCongViec(congViec);

            final ten = (
                congViec['title'] ??
                    congViec['name'] ??
                    'Công việc chưa có tên'
            ).toString();

            return Container(
              margin: const EdgeInsets.only(
                bottom: 8,
              ),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius:
                BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFEEEEEE),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: mauChu,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          ten,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          han == null
                              ? 'Chưa có hạn'
                              : 'Hạn: ${dinhDangNgay(han)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget thongKeHanCongViec() {
    final sapDen = danhSachCongViec
        .where(sapDenHan)
        .toList();

    final qua = danhSachCongViec
        .where(quaHan)
        .toList();

    sapDen.sort((a, b) {
      return layHanCongViec(a)!.compareTo(
        layHanCongViec(b)!,
      );
    });

    qua.sort((a, b) {
      return layHanCongViec(a)!.compareTo(
        layHanCongViec(b)!,
      );
    });

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.05,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Công việc sắp đến hạn & quá hạn',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              oThongKeHan(
                tieuDe: 'Sắp đến hạn',
                soLuong: sapDen.length,
                moTa: 'Trong 3 ngày tới',
                icon: Icons.access_time,
                mauNenO:
                const Color(0xFFFFF4E6),
                mauChu:
                const Color(0xFFD97706),
              ),
              const SizedBox(width: 10),
              oThongKeHan(
                tieuDe: 'Quá hạn',
                soLuong: qua.length,
                moTa: 'Chưa hoàn thành',
                icon:
                Icons.warning_amber_rounded,
                mauNenO:
                const Color(0xFFFEECEC),
                mauChu:
                const Color(0xFFDC2626),
              ),
            ],
          ),
          const SizedBox(height: 16),
          danhSachTheoHan(
            tieuDe: 'Sắp đến hạn',
            danhSach: sapDen,
            mauChu: const Color(0xFFD97706),
            icon: Icons.schedule,
          ),
          const Divider(height: 24),
          danhSachTheoHan(
            tieuDe: 'Quá hạn',
            danhSach: qua,
            mauChu: const Color(0xFFDC2626),
            icon: Icons.error_outline,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // E.4 - LỊCH SỬ HOẠT ĐỘNG CÔNG VIỆC
  // ==========================================

  Future<void> taiLichSu(String taskId) async {
    if (!mounted) return;

    setState(() {
      congViecDuocChon = taskId;
      dangTaiLichSu = true;
      danhSachLichSu = [];
      loiLichSu = null;
    });

    try {
      final ketQua =
      await TaskService.getTaskActivities(
        widget.token,
        taskId,
      );

      if (!mounted ||
          congViecDuocChon != taskId) {
        return;
      }

      setState(() {
        danhSachLichSu = ketQua;
        dangTaiLichSu = false;
      });
    } catch (e) {
      if (!mounted ||
          congViecDuocChon != taskId) {
        return;
      }

      setState(() {
        loiLichSu = e
            .toString()
            .replaceFirst('Exception: ', '');
        dangTaiLichSu = false;
      });
    }
  }

  String dinhDangThoiGian(dynamic giaTri) {
    final ngay = DateTime.tryParse(
      giaTri?.toString() ?? '',
    )?.toLocal();

    if (ngay == null) {
      return 'Không rõ thời gian';
    }

    final gio =
    ngay.hour.toString().padLeft(2, '0');
    final phut =
    ngay.minute.toString().padLeft(2, '0');

    return '${dinhDangNgay(ngay)} $gio:$phut';
  }

  String layTenNguoi(dynamic user) {
    if (user is Map) {
      return (
          user['fullName'] ??
              user['name'] ??
              user['email'] ??
              'Người dùng'
      ).toString();
    }

    return 'Người dùng';
  }

  String tenHanhDong(String action) {
    switch (action) {
      case 'created':
        return 'Tạo công việc';
      case 'updated':
        return 'Chỉnh sửa công việc';
      case 'status_changed':
        return 'Thay đổi trạng thái';
      case 'assigned':
        return 'Giao công việc';
      case 'shared':
        return 'Chia sẻ công việc';
      case 'permission_changed':
        return 'Thay đổi quyền';
      case 'share_revoked':
        return 'Thu hồi quyền chia sẻ';
      default:
        return 'Hoạt động công việc';
    }
  }

  IconData iconHanhDong(String action) {
    switch (action) {
      case 'created':
        return Icons.add_circle_outline;
      case 'updated':
        return Icons.edit_outlined;
      case 'status_changed':
        return Icons.sync_alt;
      case 'assigned':
        return Icons.person_add_alt_1_outlined;
      case 'shared':
        return Icons.share_outlined;
      case 'permission_changed':
        return Icons.admin_panel_settings_outlined;
      case 'share_revoked':
        return Icons.person_remove_outlined;
      default:
        return Icons.history;
    }
  }

  Widget oLichSu(dynamic activity) {
    final action =
    (activity['action'] ?? '').toString();

    final moTa =
    (activity['description'] ?? '').toString();

    final tenNguoi =
    layTenNguoi(activity['user']);

    final thoiGian =
    dinhDangThoiGian(activity['createdAt']);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEAE6F7),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor:
            const Color(0xFFECE7FF),
            child: Icon(
              iconHanhDong(action),
              size: 19,
              color: mauTim,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  tenHanhDong(action),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  moTa,
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        tenNguoi,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      thoiGian,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget lichSuHoatDongCongViec() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.05,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Lịch sử hoạt động công việc',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Chọn công việc để xem lịch sử hoạt động.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),

          if (danhSachCongViec.isEmpty)
            const Text(
              'Chưa có công việc nào.',
              style: TextStyle(
                color: Colors.grey,
              ),
            )
          else
            DropdownButtonFormField<String>(
              value: congViecDuocChon,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Chọn công việc',
                prefixIcon: const Icon(
                  Icons.assignment_outlined,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                ),
              ),
              items: danhSachCongViec.map((cv) {
                final id = layId(cv['_id']);
                final ten = (
                    cv['title'] ??
                        'Công việc chưa có tên'
                ).toString();

                return DropdownMenuItem<String>(
                  value: id,
                  child: Text(
                    ten,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (id) {
                if (id != null) {
                  taiLichSu(id);
                }
              },
            ),

          const SizedBox(height: 14),

          if (congViecDuocChon == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Vui lòng chọn một công việc.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else if (dangTaiLichSu)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  color: mauTim,
                ),
              ),
            )
          else if (loiLichSu != null)
              Column(
                children: [
                  Text(
                    'Không tải được lịch sử:\n'
                        '$loiLichSu',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      taiLichSu(congViecDuocChon!);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              )
            else if (danhSachLichSu.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Chưa có lịch sử hoạt động.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
              else ...[
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${danhSachLichSu.length} hoạt động',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: mauTim,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Làm mới lịch sử',
                        onPressed: () {
                          taiLichSu(congViecDuocChon!);
                        },
                        icon: const Icon(
                          Icons.refresh,
                          color: mauTim,
                        ),
                      ),
                    ],
                  ),
                  ...danhSachLichSu.map(oLichSu),
                ],
        ],
      ),
    );
  }

  // ==========================================
  // GIAO DIỆN THỐNG KÊ & TIỆN ÍCH
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mauNen,
      appBar: AppBar(
        title: const Text(
          'Thống kê & Tiện ích',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: mauTim,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: taiThongKe,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: dangTai
          ? const Center(
        child: CircularProgressIndicator(
          color: mauTim,
        ),
      )
          : thongBaoLoi != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Không tải được thống kê:\n'
                    '$thongBaoLoi',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: taiThongKe,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: taiThongKe,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // E.1
            thongKeTienDo(),

            const SizedBox(height: 12),

            // E.2
            thongKeCongViecCuaToi(),

            const SizedBox(height: 12),

            // E.3
            thongKeHanCongViec(),

            const SizedBox(height: 12),

            // E.4
            lichSuHoatDongCongViec(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
