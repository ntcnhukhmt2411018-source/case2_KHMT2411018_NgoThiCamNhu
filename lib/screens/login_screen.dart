
import 'package:flutter/material.dart';
import '../services/auth_services.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. CONTROLLER ĐĂNG NHẬP
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;

  // 2. HIỂN THỊ THÔNG BÁO
  void thongBao(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // 3. ĐĂNG NHẬP TÀI KHOẢN
  Future<void> dangNhap() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    // Kiểm tra thông tin nhập vào
    if (email.isEmpty || password.isEmpty) {
      thongBao('Vui lòng nhập email và mật khẩu');
      return;
    }

    setState(() => loading = true);

    try {
      // Gọi API đăng nhập Node.js
      final data = await AuthService.login(email, password);

      if (!mounted) return;

      // Lấy token sau khi đăng nhập
      final token = data['token'];

      if (token == null || token.toString().isEmpty) {
        thongBao('Đăng nhập thành công nhưng chưa nhận được token');
        return;
      }

      // 4. CHUYỂN ĐẾN MÀN HÌNH CHÍNH
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            token: token.toString(),
            email: email,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      thongBao(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  // 5. GIẢI PHÓNG CONTROLLER
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // 6. GIAO DIỆN ĐĂNG NHẬP
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Biểu tượng ứng dụng
            const Icon(
              Icons.task_alt,
              size: 80,
              color: Colors.blue,
            ),

            const SizedBox(height: 20),

            const Text(
              'ĐĂNG NHẬP',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            // Ô nhập email
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // Ô nhập mật khẩu
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            // Nút đăng nhập
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : dangNhap,
                child: Text(
                  loading
                      ? 'Đang đăng nhập...'
                      : 'ĐĂNG NHẬP',
                ),
              ),
            ),

            const SizedBox(height: 15),

            // 7. CHUYỂN SANG ĐĂNG KÝ
            TextButton(
              onPressed: () async {
                final registered = await Navigator.push<bool>(
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
