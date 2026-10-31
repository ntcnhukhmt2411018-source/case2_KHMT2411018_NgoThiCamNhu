
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String token;

  const ProfileScreen({
    super.key,
    required this.token,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // 1. CONTROLLER THÔNG TIN CÁ NHÂN
  final hoTenController = TextEditingController();

  String email = '';
  bool dangTai = true;
  bool dangLuu = false;
  bool taiThanhCong = false;

  @override
  void initState() {
    super.initState();
    layThongTin();
  }

  // 2. XỬ LÝ LỖI
  String xuLyLoi(Object error) {
    if (error is SocketException ||
        error is TimeoutException ||
        error is HttpException ||
        error.toString().contains('ClientException')) {
      return 'Không thể kết nối đến máy chủ.';
    }

    return error.toString().replaceFirst('Exception: ', '');
  }

  // 3. HIỂN THỊ THÔNG BÁO
  void thongBao(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // 4. XEM THÔNG TIN CÁ NHÂN
  Future<void> layThongTin() async {
    setState(() => dangTai = true);

    try {
      final data = await UserService.getProfile(
        widget.token,
      ).timeout(const Duration(seconds: 10));

      final user = data['user'] ?? data;

      if (!mounted) return;

      setState(() {
        hoTenController.text =
            (user['fullName'] ?? '').toString();
        email = (user['email'] ?? '').toString();
        taiThanhCong = true;
        dangTai = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        dangTai = false;
        taiThanhCong = false;
      });

      thongBao(xuLyLoi(e));
    }
  }

  // 5. CẬP NHẬT THÔNG TIN CÁ NHÂN
  Future<void> capNhat() async {
    final hoTen = hoTenController.text.trim();

    if (hoTen.isEmpty) {
      thongBao('Vui lòng nhập họ tên');
      return;
    }

    setState(() => dangLuu = true);

    try {
      await UserService.updateProfile(
        widget.token,
        hoTen,
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      thongBao('Cập nhật thông tin thành công');
      await layThongTin();
    } catch (e) {
      if (!mounted) return;
      thongBao(xuLyLoi(e));
    } finally {
      if (mounted) {
        setState(() => dangLuu = false);
      }
    }
  }

  // 6. MỞ TRANG ĐỔI MẬT KHẨU RIÊNG
  void moDoiMatKhau() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangePasswordScreen(
          token: widget.token,
        ),
      ),
    );
  }

  @override
  void dispose() {
    hoTenController.dispose();
    super.dispose();
  }

  // 7. GIAO DIỆN THÔNG TIN CÁ NHÂN
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: dangTai
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : !taiThanhCong
          ? Center(
        child: ElevatedButton(
          onPressed: layThongTin,
          child: const Text('Thử tải lại thông tin'),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 15),

            // 8. ẢNH ĐẠI DIỆN
            const CircleAvatar(
              radius: 48,
              backgroundColor: Color(0xFFE0E9FF),
              child: Icon(
                Icons.account_circle,
                size: 85,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              hoTenController.text,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              email,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 25),

            // 9. THẺ THÔNG TIN CÁ NHÂN
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Thông tin cá nhân',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Họ tên
                  TextField(
                    controller: hoTenController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Email
                  TextFormField(
                    key: ValueKey(email),
                    initialValue: email,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Lưu thay đổi
                  ElevatedButton.icon(
                    onPressed: dangLuu ? null : capNhat,
                    icon: const Icon(Icons.save),
                    label: Text(
                      dangLuu
                          ? 'Đang lưu...'
                          : 'Lưu thay đổi',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF72549A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(14),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 10. MỤC ĐỔI MẬT KHẨU
            // Nhấn vào sẽ mở trang mới
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                onTap: moDoiMatKhau,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFE9DD),
                  child: Icon(
                    Icons.lock,
                    color: Colors.deepOrange,
                  ),
                ),
                title: const Text(
                  'Đổi mật khẩu',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Thay đổi mật khẩu để bảo vệ tài khoản',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
