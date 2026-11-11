
import 'package:flutter/material.dart';
import '../services/task_service.dart';

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
  bool dangTai = true;
  String? thongBaoLoi;

  @override
  void initState() {
    super.initState();
    taiThongKe();
  }

  // LẤY DỮ LIỆU CÔNG VIỆC TỪ MONGODB
  Future<void> taiThongKe() async {
    setState(() {
      dangTai = true;
      thongBaoLoi = null;
    });

    try {
      final ketQua =
      await TaskService.getTasks(widget.token);

      if (!mounted) return;

      setState(() {
        danhSachCongViec = ketQua;
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

  // THEO DÕI TIẾN ĐỘ CÔNG VIỆC
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
          // TIÊU ĐỀ
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

  // GIAO DIỆN TRANG THỐNG KÊ & TIỆN ÍCH
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
            // THỐNG KÊ TIẾN ĐỘ
            thongKeTienDo(),

            // Các thống kê khác sẽ
            // được bổ sung bên dưới.
          ],
        ),
      ),
    );
  }
}
