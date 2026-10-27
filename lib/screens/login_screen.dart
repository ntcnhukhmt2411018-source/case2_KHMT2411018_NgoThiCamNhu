import 'package:flutter/material.dart';
import '../services/auth_services.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;

  void thongBao(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> dangNhap() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      thongBao('Vui lòng nhập email và mật khẩu');
      return;
    }

    setState(() => loading = true);

    try {
      await AuthService.login(email, password);

      if (!mounted) return;

      thongBao('Đăng nhập thành công');

      // Sau này chuyển đến home_screen.dart tại đây.

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

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

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

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : dangNhap,
                child: Text(
                  loading ? 'Đang đăng nhập...' : 'ĐĂNG NHẬP',
                ),
              ),
            ),

            const SizedBox(height: 15),

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