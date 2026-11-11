
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

  @override
  void initState() {
    super.initState();
    taiThongKe();
  }

  // ==========================================
  // LẤY ID NGƯỜI ĐĂNG NHẬP TỪ TOKEN
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

      final id = data['id'] ?? data['userId'];

      return id?.toString();
    } catch (e) {
      debugPrint('Lỗi đọc ID từ token: $e');
      return null;
    }
  }

  // LẤY ID TỪ CHUỖI HOẶC OBJECT MONGODB
  String layId(dynamic giaTri) {
    if (giaTri == null) return '';

    if (giaTri is Map) {
      return (giaTri['_id'] ?? giaTri['id'] ?? '')
          .toString();
    }

    return giaTri.toString();
  }

  // KIỂM TRA NGƯỜI DÙNG TRONG DANH SÁCH
  bool coTrongDanhSach(dynamic danhSach, String id) {
    if (danhSach is! List) return false;

    return danhSach.any(
          (nguoi) => layId(nguoi) == id,
    );
  }

  // ==========================================
  // LẤY DỮ LIỆU TỪ MONGODB
  // ==========================================

  Future<void> taiThongKe() async {
    if (!mounted) return;

    setState(() {
      dangTai = true;
      thongBaoLoi = null;
    });

    try {
      // Lấy danh sách công việc
      final ketQua =
      await TaskService.getTasks(widget.token);

      // Lấy ID tài khoản đăng nhập
      String? id = layUserIdTuToken(widget.token);

      // Nếu token không có ID thì lấy từ profile
      if (id == null || id.isEmpty) {
        try {
          final profile =
          await UserService.getProfile(widget.token);

          final user = profile['user'] ?? profile;

          id = layId(user);
        } catch (e) {
          debugPrint('Không lấy được ID từ profile: $e');
        }
      }

      if (!mounted) return;

      setState(() {
        danhSachCongViec = ketQua;
        userId = id;
        dangTai = false;
      });
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
  // THEO DÕI TIẾN ĐỘ CÔNG VIỆC
  // ==========================================

  // MỘT Ô THỐNG KÊ NHỎ
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

  // GIAO DIỆN THEO DÕI TIẾN ĐỘ
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

          // 4 Ô THỐNG KÊ CÙNG MỘT HÀNG
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

          // TỶ LỆ HOÀN THÀNH
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
  // THỐNG KÊ CÔNG VIỆC CỦA TÔI
  // ==========================================

  // KIỂM TRA CÔNG VIỆC DO TÔI GIAO CHO NGƯỜI KHÁC
  bool laCongViecDaGiao(dynamic congViec) {
    final id = userId;

    if (id == null || id.isEmpty) return false;

    final nguoiTao = layId(congViec['createdBy']);

    // Chỉ tính công việc do tôi tạo
    if (nguoiTao != id) return false;

    // Giao cho một người khác
    final nguoiPhuTrach =
    layId(congViec['assignedTo']);

    if (nguoiPhuTrach.isNotEmpty &&
        nguoiPhuTrach != id) {
      return true;
    }

    // Giao cho nhiều người
    final danhSachNguoiDuocGiao =
    congViec['assignedUsers'];

    if (danhSachNguoiDuocGiao is List) {
      return danhSachNguoiDuocGiao.any((nguoi) {
        final nguoiId = layId(nguoi);

        return nguoiId.isNotEmpty && nguoiId != id;
      });
    }

    return false;
  }

  // KIỂM TRA CÔNG VIỆC TÔI ĐANG PHỤ TRÁCH
  bool laCongViecDangPhuTrach(dynamic congViec) {
    final id = userId;

    if (id == null || id.isEmpty) return false;

    // Tôi là người phụ trách chính
    if (layId(congViec['assignedTo']) == id) {
      return true;
    }

    // Tôi nằm trong danh sách được giao
    return coTrongDanhSach(
      congViec['assignedUsers'],
      id,
    );
  }

  // MỘT Ô THỐNG KÊ CÔNG VIỆC
  Widget oThongKeCongViec({
    required String tieuDe,
    required int soLuong,
    required String moTa,
    required IconData icon,
    required Color mauNenO,
  }) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 130,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: mauNenO,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: mauTim,
              size: 22,
            ),

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

  // GIAO DIỆN THỐNG KÊ CÔNG VIỆC CỦA TÔI
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                oThongKeCongViec(
                  tieuDe: 'Đã giao',
                  soLuong: daGiao,
                  moTa: 'Công việc giao cho người khác',
                  icon: Icons.send_outlined,
                  mauNenO: const Color(0xFFF2ECFF),
                ),

                const SizedBox(width: 10),

                oThongKeCongViec(
                  tieuDe: 'Đang phụ trách',
                  soLuong: dangPhuTrach,
                  moTa: 'Công việc được giao cho tôi',
                  icon: Icons.assignment_turned_in_outlined,
                  mauNenO: const Color(0xFFEFEDFF),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ==========================================
  // GIAO DIỆN TRANG THỐNG KÊ & TIỆN ÍCH
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
            // THEO DÕI TIẾN ĐỘ
            thongKeTienDo(),

            const SizedBox(height: 12),

            // THỐNG KÊ CÔNG VIỆC CỦA TÔI
            thongKeCongViecCuaToi(),
          ],
        ),
      ),
    );
  }
}
