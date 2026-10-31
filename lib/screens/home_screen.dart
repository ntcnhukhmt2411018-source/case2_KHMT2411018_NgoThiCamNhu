
import 'package:flutter/material.dart';
import '../profile/profile_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  final String token;
  final String email;

  const HomeScreen({
    super.key,
    required this.token,
    required this.email,
  });

  // 1. MỞ THÔNG TIN CÁ NHÂN
  void moThongTin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(token: token),
      ),
    );
  }

  // 2. ĐĂNG XUẤT
  void dangXuat(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  // 3. DANH SÁCH CÔNG VIỆC (SẼ LÀM SAU)
  void moCongViec(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng danh sách công việc sẽ được bổ sung sau'),
      ),
    );
  }

  // 4. TẠO NÚT CHỨC NĂNG
  Widget nutChucNang({
    required String ten,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(ten),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF72549A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FF),
      appBar: AppBar(
        title: const Text('TaskManager'),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFF9FF),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => dangXuat(context),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.task_alt,
                size: 80,
                color: Color(0xFF72549A),
              ),
              const SizedBox(height: 20),

              const Text(
                'Đăng nhập thành công!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Tài khoản: $email',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
              ),

              const SizedBox(height: 30),

              // Nút danh sách công việc
              nutChucNang(
                ten: 'Danh sách công việc',
                icon: Icons.list_alt,
                onPressed: () => moCongViec(context),
              ),

              const SizedBox(height: 12),

              // Nút thông tin cá nhân
              nutChucNang(
                ten: 'Thông tin cá nhân',
                icon: Icons.person,
                onPressed: () => moThongTin(context),
              ),

              const SizedBox(height: 12),

              // Nút đăng xuất
              nutChucNang(
                ten: 'Đăng xuất',
                icon: Icons.logout,
                onPressed: () => dangXuat(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
