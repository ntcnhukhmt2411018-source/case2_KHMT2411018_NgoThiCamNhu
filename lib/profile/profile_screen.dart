
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import '../services/user_service.dart';

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

  // Xử lý thông báo lỗi
  String xuLyLoi(Object error) {
    if (error is SocketException ||
        error is TimeoutException ||
        error is HttpException) {
      return 'Không thể kết nối đến máy chủ. Vui lòng thử lại.';
    }

    final noiDung = error.toString();

    if (noiDung.contains('ClientException') ||
        noiDung.contains('Connection refused') ||
        noiDung.contains('SocketException') ||
        noiDung.contains('TimeoutException')) {
      return 'Không thể kết nối đến máy chủ. Vui lòng thử lại.';
    }

    return noiDung.replaceFirst('Exception: ', '');
  }

  // Xem thông tin cá nhân
  Future<void> layThongTin() async {
    if (mounted) {
      setState(() => dangTai = true);
    }

    try {
      final data = await UserService.getProfile(
        widget.token,
      ).timeout(const Duration(seconds: 10));

      final user = data['user'] ?? data;

      if (!mounted) return;

      setState(() {
        hoTenController.text = (user['fullName'] ?? '').toString();
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

  // Cập nhật thông tin cá nhân
  Future<void> capNhat() async {
    final hoTen = hoTenController.text.trim();

    // Trường hợp 3: Không cho lưu họ tên trống
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

      // Trường hợp 4: Thông báo lỗi kết nối
      thongBao(xuLyLoi(e));
    } finally {
      if (mounted) {
        setState(() => dangLuu = false);
      }
    }
  }

  // Hiển thị thông báo
  void thongBao(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    hoTenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            const Icon(
              Icons.account_circle,
              size: 90,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              'THÔNG TIN CÁ NHÂN',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: hoTenController,
              decoration: const InputDecoration(
                labelText: 'Họ và tên',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
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
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: dangLuu ? null : capNhat,
                icon: const Icon(Icons.save),
                label: Text(
                  dangLuu
                      ? 'Đang lưu...'
                      : 'Lưu thay đổi',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
