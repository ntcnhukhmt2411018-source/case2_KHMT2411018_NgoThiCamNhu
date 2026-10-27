import 'package:flutter/material.dart';
import '../services/auth_services.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool loading = false;

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirm = confirmController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      showMessage('Vui lòng nhập đầy đủ thông tin');
      return;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      showMessage('Email không hợp lệ');
      return;
    }

    if (password.length < 6) {
      showMessage('Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }

    if (password != confirm) {
      showMessage('Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() => loading = true);

    try {
      await AuthService.register(name, email, password);

      if (!mounted) return;

      // Quay về màn hình đăng nhập
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký tài khoản'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Icon(
              Icons.person_add_alt_1,
              size: 75,
              color: Colors.blue,
            ),

            const SizedBox(height: 15),

            const Text(
              'ĐĂNG KÝ TÀI KHOẢN',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Họ và tên',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

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

            const SizedBox(height: 15),

            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Xác nhận mật khẩu',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : register,
                child: Text(
                  loading ? 'Đang đăng ký...' : 'ĐĂNG KÝ',
                ),
              ),
            ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đã có tài khoản? Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}