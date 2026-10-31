
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const router = express.Router();

// Kiểm tra API
router.get('/test', (req, res) => {
  res.json({ message: 'Auth routes hoat dong' });
});

// Đăng ký tài khoản
router.post('/register', async (req, res) => {
  try {
    const { fullName, email, password } = req.body;

    if (!fullName || !email || !password) {
      return res.status(400).json({
        message: 'Vui long nhap day du thong tin'
      });
    }

    const emailChuan = email.trim().toLowerCase();

    const userCu = await User.findOne({ email: emailChuan });

    if (userCu) {
      return res.status(400).json({
        message: 'Email da ton tai'
      });
    }

    const matKhauMaHoa = await bcrypt.hash(password, 10);

    const user = new User({
      fullName: fullName.trim(),
      email: emailChuan,
      password: matKhauMaHoa
    });

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

// Đăng nhập
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        message: 'Vui long nhap email va mat khau'
      });
    }

    const user = await User.findOne({
      email: email.trim().toLowerCase()
    });

    if (!user) {
      return res.status(401).json({
        message: 'Email hoac mat khau khong dung'
      });
    }

    const dungMatKhau = await bcrypt.compare(
      password,
      user.password
    );

    if (!dungMatKhau) {
      return res.status(401).json({
        message: 'Email hoac mat khau khong dung'
      });
    }

    const token = jwt.sign(
      { userId: user._id.toString() },
      process.env.JWT_SECRET,
      { expiresIn: '1d' }
    );

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

// Middleware kiểm tra token đăng nhập
const xacThuc = (req, res, next) => {
  try {
    const authorization = req.headers.authorization;

    if (!authorization || !authorization.startsWith('Bearer ')) {
      return res.status(401).json({
        message: 'Vui long dang nhap'
      });
    }

    const token = authorization.split(' ')[1];

    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    req.userId = decoded.userId;
    next();

  } catch (error) {
    return res.status(401).json({
      message: 'Token khong hop le hoac da het han'
    });
  }
};

// 1. XEM THONG TIN CA NHAN
router.get('/me', xacThuc, async (req, res) => {
  try {
    const user = await User.findById(req.userId)
      .select('-password');

    if (!user) {
      return res.status(404).json({
        message: 'Khong tim thay nguoi dung'
      });
    }

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

// 2. CAP NHAT THONG TIN CA NHAN
router.put('/me', xacThuc, async (req, res) => {
  try {
    const { fullName } = req.body;

    if (typeof fullName !== 'string' || !fullName.trim()) {
      return res.status(400).json({
        message: 'Vui long nhap ho ten'
      });
    }

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

module.exports = router;
