
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const router = express.Router();


// ========================================
// 1. KIỂM TRA API
// ========================================

router.get('/test', (req, res) => {
  res.json({
    message: 'Auth routes hoat dong'
  });
});


// ========================================
// 2. ĐĂNG KÝ TÀI KHOẢN
// ========================================

router.post('/register', async (req, res) => {
  try {
    const { fullName, email, password } = req.body;

    // Kiểm tra thông tin nhập vào
    if (!fullName || !email || !password) {
      return res.status(400).json({
        message: 'Vui long nhap day du thong tin'
      });
    }

    // Chuẩn hóa email
    const emailChuan = email.trim().toLowerCase();

    // Kiểm tra email đã tồn tại chưa
    const userCu = await User.findOne({
      email: emailChuan
    });

    if (userCu) {
      return res.status(400).json({
        message: 'Email da ton tai'
      });
    }

    // Mã hóa mật khẩu
    const matKhauMaHoa = await bcrypt.hash(password, 10);

    // Tạo tài khoản mới
    const user = new User({
      fullName: fullName.trim(),
      email: emailChuan,
      password: matKhauMaHoa
    });

    // Lưu tài khoản vào MongoDB
    await user.save();

    res.status(201).json({
      message: 'Dang ky thanh cong'
    });

  } catch (error) {
    res.status(500).json({
      message: 'Loi server'
    });
  }
});


// ========================================
// 3. ĐĂNG NHẬP TÀI KHOẢN
// ========================================

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Kiểm tra dữ liệu
    if (!email || !password) {
      return res.status(400).json({
        message: 'Vui long nhap email va mat khau'
      });
    }

    // Tìm tài khoản theo email
    const user = await User.findOne({
      email: email.trim().toLowerCase()
    });

    if (!user) {
      return res.status(401).json({
        message: 'Email hoac mat khau khong dung'
      });
    }

    // Kiểm tra mật khẩu
    const dungMatKhau = await bcrypt.compare(
      password,
      user.password
    );

    if (!dungMatKhau) {
      return res.status(401).json({
        message: 'Email hoac mat khau khong dung'
      });
    }

    // Tạo token đăng nhập
    const token = jwt.sign(
      { userId: user._id.toString() },
      process.env.JWT_SECRET,
      { expiresIn: '1d' }
    );

    // Trả về token và thông tin người dùng
    res.status(200).json({
      message: 'Dang nhap thanh cong',
      token: token,
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email
      }
    });

  } catch (error) {
    res.status(500).json({
      message: 'Loi server'
    });
  }
});


// ========================================
// 4. XÁC THỰC TOKEN ĐĂNG NHẬP
// ========================================

const xacThuc = (req, res, next) => {
  try {
    // Lấy token từ Header
    const authorization = req.headers.authorization;

    if (
      !authorization ||
      !authorization.startsWith('Bearer ')
    ) {
      return res.status(401).json({
        message: 'Vui long dang nhap'
      });
    }

    // Tách token
    const token = authorization.split(' ')[1];

    // Kiểm tra token hợp lệ
    const decoded = jwt.verify(
      token,
      process.env.JWT_SECRET
    );

    // Lưu ID người dùng
    req.userId = decoded.userId;

    next();

  } catch (error) {
    return res.status(401).json({
      message: 'Token khong hop le hoac da het han'
    });
  }
};


// ========================================
// 5. XEM THÔNG TIN CÁ NHÂN
// ========================================

router.get('/me', xacThuc, async (req, res) => {
  try {
    // Lấy thông tin người dùng từ MongoDB
    const user = await User.findById(req.userId)
      .select('-password');

    if (!user) {
      return res.status(404).json({
        message: 'Khong tim thay nguoi dung'
      });
    }

    // Trả về thông tin cá nhân
    res.status(200).json({
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email
      }
    });

  } catch (error) {
    res.status(500).json({
      message: 'Loi khi lay thong tin ca nhan'
    });
  }
});


// ========================================
// 6. CẬP NHẬT THÔNG TIN CÁ NHÂN
// ========================================

router.put('/me', xacThuc, async (req, res) => {
  try {
    const { fullName } = req.body;

    // Không cho phép họ tên trống
    if (
      typeof fullName !== 'string' ||
      !fullName.trim()
    ) {
      return res.status(400).json({
        message: 'Vui long nhap ho ten'
      });
    }

    // Cập nhật họ tên trong MongoDB
    const user = await User.findByIdAndUpdate(
      req.userId,
      { fullName: fullName.trim() },
      { new: true, runValidators: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({
        message: 'Khong tim thay nguoi dung'
      });
    }

    // Trả về thông tin sau cập nhật
    res.status(200).json({
      message: 'Cap nhat thanh cong',
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email
      }
    });

  } catch (error) {
    res.status(500).json({
      message: 'Loi khi cap nhat thong tin'
    });
  }
});


// ========================================
// 7. ĐỔI MẬT KHẨU
// ========================================

router.post('/change-password', xacThuc, async (req, res) => {
  try {
    const { oldPassword, newPassword } = req.body;

    // Kiểm tra đã nhập đầy đủ mật khẩu chưa
    if (
      typeof oldPassword !== 'string' ||
      typeof newPassword !== 'string' ||
      !oldPassword ||
      !newPassword
    ) {
      return res.status(400).json({
        message: 'Vui long nhap day du mat khau'
      });
    }

    // Mật khẩu mới phải có ít nhất 8 ký tự
    if (newPassword.length < 8) {
      return res.status(400).json({
        message: 'Mat khau moi phai co it nhat 8 ky tu'
      });
    }

    // Tìm tài khoản đang đăng nhập
    const user = await User.findById(req.userId);

    if (!user) {
      return res.status(404).json({
        message: 'Khong tim thay tai khoan'
      });
    }

    // Kiểm tra mật khẩu cũ có đúng không
    const dungMatKhauCu = await bcrypt.compare(
      oldPassword,
      user.password
    );

    if (!dungMatKhauCu) {
      return res.status(400).json({
        message: 'Mat khau cu khong dung'
      });
    }

    // Không cho dùng lại mật khẩu cũ
    if (oldPassword === newPassword) {
      return res.status(400).json({
        message: 'Mat khau moi phai khac mat khau cu'
      });
    }

    // Mã hóa mật khẩu mới
    const matKhauMoiMaHoa = await bcrypt.hash(
      newPassword,
      10
    );

    // Lưu mật khẩu mới vào MongoDB
    user.password = matKhauMoiMaHoa;
    await user.save();

    // Thông báo đổi mật khẩu thành công
    return res.status(200).json({
      message: 'Doi mat khau thanh cong'
    });

  } catch (error) {
    return res.status(500).json({
      message: 'Loi server khi doi mat khau'
    });
  }
});


// ========================================
// 8. XUẤT ROUTER
// ========================================

module.exports = router;
