
import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/auth_services.dart';
import 'register_screen.dart';
import '../home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. MÀU CHỦ ĐẠO
  static const Color mauTim = Color(0xFF6554C0);

  // 2. CONTROLLER ĐĂNG NHẬP
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // 3. QUẢN LÝ VỊ TRÍ NHẬP LIỆU
  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();

  bool loading = false;
  bool hienMatKhau = false;

  // 4. HIỂN THỊ THÔNG BÁO
  void thongBao(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // 5. XỬ LÝ ĐĂNG NHẬP
  Future<void> dangNhap() async {
    // Kiểm tra xem nút có nhận thao tác nhấn không
    debugPrint('DA NHAN NUT DANG NHAP');

    final email = emailController.text.trim();
    final password = passwordController.text;

    // Kiểm tra dữ liệu nhập
    if (email.isEmpty || password.isEmpty) {
      thongBao('Vui lòng nhập email và mật khẩu');
      return;
    }

    // Tránh gửi nhiều yêu cầu đăng nhập cùng lúc
    if (loading) return;

    // Ẩn bàn phím khi nhấn đăng nhập
    FocusScope.of(context).unfocus();

    setState(() {
      loading = true;
    });

    try {
      debugPrint('DANG GOI API DANG NHAP');

      // Gọi API Node.js, tối đa 10 giây
      final data = await AuthService.login(
        email,
        password,
      ).timeout(const Duration(seconds: 10));

      debugPrint('API DANG NHAP DA PHAN HOI');

      if (!mounted) return;

      // Lấy token từ backend
      final token = data['token'];

      if (token == null || token.toString().isEmpty) {
        thongBao('Không nhận được token từ server');
        return;
      }

      debugPrint('DANG NHAP THANH CONG');

      // 6. CHUYỂN SANG MÀN HÌNH HOME
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            token: token.toString(),
            email: email,
          ),
        ),
      );
    } on TimeoutException {
      // Xử lý khi API không phản hồi trong 10 giây
      debugPrint('LOI: KET NOI QUA THOI GIAN');

      thongBao(
        'Kết nối quá thời gian. Hãy kiểm tra Node.js và MongoDB.',
      );
    } catch (e) {
      // Hiển thị lỗi thực tế từ API
      debugPrint('LOI DANG NHAP: $e');

      if (!mounted) return;

      thongBao(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      // Bật lại nút đăng nhập sau khi xử lý
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // 7. GIẢI PHÓNG CONTROLLER VÀ FOCUSNODE
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    emailFocus.dispose();
    passwordFocus.dispose();

    super.dispose();
  }

  // 8. GIAO DIỆN ĐĂNG NHẬP
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),

      // THANH TIÊU ĐỀ
      appBar: AppBar(
        title: const Text(
          'TaskManager',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: mauTim,
        foregroundColor: Colors.white,
      ),

      // NỘI DUNG ĐĂNG NHẬP
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 9. BIỂU TƯỢNG ỨNG DỤNG
              const Icon(
                Icons.task_alt,
                size: 95,
                color: mauTim,
              ),

              const SizedBox(height: 20),

              // TIÊU ĐỀ ĐĂNG NHẬP
              const Text(
                'ĐĂNG NHẬP',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Chào mừng bạn đến với TaskManager',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 35),

              // 10. Ô NHẬP EMAIL
              TextField(
                controller: emailController,
                focusNode: emailFocus,
                enabled: true,
                readOnly: false,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,

                // Kiểm tra Flutter có nhận ký tự hay không
                onChanged: (value) {
                  debugPrint('Email dang nhap: $value');
                },

                // Nhấn Next chuyển sang mật khẩu
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(
                    passwordFocus,
                  );
                },

                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Nhập email của bạn',
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: mauTim,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 11. Ô NHẬP MẬT KHẨU
              TextField(
                controller: passwordController,
                focusNode: passwordFocus,
                enabled: true,
                readOnly: false,
                obscureText: !hienMatKhau,
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.done,
                enableSuggestions: false,
                autocorrect: false,

                // Nhấn Done để đăng nhập
                onSubmitted: (_) {
                  if (!loading) {
                    dangNhap();
                  }
                },

                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  hintText: 'Nhập mật khẩu',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: mauTim,
                      width: 2,
                    ),
                  ),

                  // Hiện / ẩn mật khẩu
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        hienMatKhau = !hienMatKhau;
                      });
                    },
                    icon: Icon(
                      hienMatKhau
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // 12. NÚT ĐĂNG NHẬP
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: loading ? null : dangNhap,

                  icon: loading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.login),

                  label: Text(
                    loading
                        ? 'Đang đăng nhập...'
                        : 'ĐĂNG NHẬP',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: mauTim,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 13. CHUYỂN SANG TRANG ĐĂNG KÝ
              TextButton(
                onPressed: () async {
                  final registered =
                  await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                      const RegisterScreen(),
                    ),
                  );

                  if (!mounted) return;

                  if (registered == true) {
                    thongBao(
                      'Đăng ký thành công! Hãy đăng nhập.',
                    );
                  }
                },

                child: const Text(
                  'Chưa có tài khoản? Đăng ký',
                  style: TextStyle(
                    color: mauTim,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
