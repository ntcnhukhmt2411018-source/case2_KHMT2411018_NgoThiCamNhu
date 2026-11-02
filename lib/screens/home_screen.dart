
import 'package:flutter/material.dart';

import '../profile/profile_screen.dart';
import '../services/user_service.dart';

import 'login_screen.dart';
import 'task_list_screen.dart'; // MỚI: Màn hình danh sách công việc

class HomeScreen extends StatefulWidget {
  final String token;
  final String email;

  const HomeScreen({
    super.key,
    required this.token,
    required this.email,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 1. MÀU CHỦ ĐẠO
  static const Color mauTim = Color(0xFF6554C0);

  // 2. THÔNG TIN NGƯỜI DÙNG
  String hoTen = '';
  bool dangTai = true;

  @override
  void initState() {
    super.initState();
    layHoTen();
  }

  // 3. LẤY HỌ TÊN TỪ MONGODB THÔNG QUA API
  Future<void> layHoTen() async {
    try {
      final data = await UserService.getProfile(widget.token);
      final user = data['user'] ?? data;

      if (!mounted) return;

      setState(() {
        hoTen = (user['fullName'] ?? '').toString();
        dangTai = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        dangTai = false;
      });
    }
  }

  // 4. MỞ TRANG THÔNG TIN CÁ NHÂN
  Future<void> moThongTin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          token: widget.token,
        ),
      ),
    );

    // Tải lại họ tên sau khi cập nhật thông tin
    if (mounted) {
      layHoTen();
    }
  }

  // 5. ĐĂNG XUẤT
  void dangXuat() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  // 6. MỞ DANH SÁCH CÔNG VIỆC - PHẦN B
  void moCongViec() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskListScreen(
          token: widget.token,
        ),
      ),
    );
  }

  // 7. TẠO NÚT CHỨC NĂNG
  Widget nutChucNang({
    required String ten,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          ten,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: mauTim,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    );
  }

  // 8. GIAO DIỆN HOME
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),

      // THANH TIÊU ĐỀ MÀU TÍM
      appBar: AppBar(
        title: const Text(
          'TaskManager',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: mauTim,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),

      // NỘI DUNG TRANG HOME
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 25,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // BIỂU TƯỢNG TASK MANAGER
              const Icon(
                Icons.task_alt,
                size: 100,
                color: mauTim,
              ),

              const SizedBox(height: 25),

              // LỜI CHÀO
              const Text(
                'Xin chào,',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              // HỌ TÊN NGƯỜI ĐĂNG NHẬP
              dangTai
                  ? const CircularProgressIndicator(
                color: mauTim,
              )
                  : Text(
                hoTen.isNotEmpty
                    ? '$hoTen!'
                    : widget.email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Quản lý công việc hiệu quả mỗi ngày',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 35),

              // 9. NÚT DANH SÁCH CÔNG VIỆC - PHẦN B
              nutChucNang(
                ten: 'Danh sách công việc',
                icon: Icons.list_alt,
                onPressed: moCongViec,
              ),

              const SizedBox(height: 14),

              // 10. NÚT THÔNG TIN CÁ NHÂN - PHẦN A
              nutChucNang(
                ten: 'Thông tin cá nhân',
                icon: Icons.person,
                onPressed: moThongTin,
              ),

              const SizedBox(height: 14),

              // 11. NÚT ĐĂNG XUẤT - PHẦN A
              nutChucNang(
                ten: 'Đăng xuất',
                icon: Icons.logout,
                onPressed: dangXuat,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
