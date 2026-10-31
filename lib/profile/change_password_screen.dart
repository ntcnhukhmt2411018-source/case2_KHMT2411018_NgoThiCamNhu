
import 'package:flutter/material.dart';
import '../services/user_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String token;

  const ChangePasswordScreen({
    super.key,
    required this.token,
  });

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {

  // 1. CONTROLLER MẬT KHẨU
  final matKhauCuController = TextEditingController();
  final matKhauMoiController = TextEditingController();
  final xacNhanController = TextEditingController();

  bool dangDoi = false;
  bool hienMatKhau = false;

  // 2. HIỂN THỊ THÔNG BÁO
  void thongBao(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // 3. XỬ LÝ ĐỔI MẬT KHẨU
  Future<void> doiMatKhau() async {
    final cu = matKhauCuController.text;
    final moi = matKhauMoiController.text;
    final xacNhan = xacNhanController.text;

    if (cu.isEmpty || moi.isEmpty || xacNhan.isEmpty) {
      thongBao('Vui lòng nhập đầy đủ thông tin');
      return;
    }

    if (moi.length < 8) {
      thongBao('Mật khẩu mới phải có ít nhất 8 ký tự');
      return;
    }

    if (cu == moi) {
      thongBao('Mật khẩu mới phải khác mật khẩu cũ');
      return;
    }

    if (moi != xacNhan) {
      thongBao('Xác nhận mật khẩu không khớp');
      return;
    }

    setState(() => dangDoi = true);

    try {
      await UserService.changePassword(
        widget.token,
        cu,
        moi,
      );

      if (!mounted) return;

      // Chuyển đến màn hình thông báo thành công
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ChangePasswordSuccessScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      thongBao(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => dangDoi = false);
      }
    }
  }

  // 4. TẠO Ô NHẬP MẬT KHẨU
  Widget oMatKhau(
      String nhan,
      TextEditingController controller,
      ) {
    return TextField(
      controller: controller,
      obscureText: !hienMatKhau,
      enableSuggestions: false,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: nhan,
        prefixIcon: const Icon(Icons.lock_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() => hienMatKhau = !hienMatKhau);
          },
          icon: Icon(
            hienMatKhau
                ? Icons.visibility_off
                : Icons.visibility,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    matKhauCuController.dispose();
    matKhauMoiController.dispose();
    xacNhanController.dispose();
    super.dispose();
  }

  // 5. GIAO DIỆN ĐỔI MẬT KHẨU
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        title: const Text('Đổi mật khẩu'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            const CircleAvatar(
              radius: 45,
              backgroundColor: Color(0xFFE8E2FA),
              child: Icon(
                Icons.lock,
                size: 48,
                color: Color(0xFF6247B5),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Đổi mật khẩu',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Nhập mật khẩu hiện tại và mật khẩu mới '
                  'để bảo vệ tài khoản của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 30),

            // Mật khẩu cũ
            oMatKhau(
              'Mật khẩu hiện tại',
              matKhauCuController,
            ),

            const SizedBox(height: 18),

            // Mật khẩu mới
            oMatKhau(
              'Mật khẩu mới',
              matKhauMoiController,
            ),

            const SizedBox(height: 18),

            // Xác nhận mật khẩu
            oMatKhau(
              'Xác nhận mật khẩu mới',
              xacNhanController,
            ),

            const SizedBox(height: 25),

            // Gợi ý mật khẩu
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFE9EDFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Lưu ý:\n'
                    '• Mật khẩu mới phải có ít nhất 8 ký tự.\n'
                    '• Nên sử dụng chữ hoa, chữ thường, số '
                    'và ký tự đặc biệt.\n'
                    '• Không sử dụng lại mật khẩu cũ.',
                style: TextStyle(height: 1.6),
              ),
            ),

            const SizedBox(height: 25),

            // Nút đổi mật khẩu
            ElevatedButton.icon(
              onPressed: dangDoi ? null : doiMatKhau,
              icon: const Icon(Icons.lock_reset),
              label: Text(
                dangDoi
                    ? 'Đang đổi mật khẩu...'
                    : 'Đổi mật khẩu',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF72549A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 6. MÀN HÌNH ĐỔI MẬT KHẨU THÀNH CÔNG
class ChangePasswordSuccessScreen extends StatelessWidget {
  const ChangePasswordSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        title: const Text('Đổi mật khẩu'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                size: 110,
                color: Colors.green,
              ),
              const SizedBox(height: 25),
              const Text(
                'Đổi mật khẩu thành công!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Mật khẩu của bạn đã được thay đổi.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 35),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF72549A),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Quay về thông tin cá nhân',
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
