
const express = require('express');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');

const Notification = require('../models/Notification');

const router = express.Router();

function xacThuc(req, res, next) {
  try {
    const header = req.headers.authorization || '';

    if (!header.startsWith('Bearer ')) {
      return res.status(401).json({
        message: 'Vui lòng đăng nhập',
      });
    }

    const token = header.substring(7);

    const decoded = jwt.verify(
      token,
      process.env.JWT_SECRET
    );

    const userId = decoded.id || decoded.userId;

    if (!mongoose.isValidObjectId(userId)) {
      return res.status(401).json({
        message: 'Token không hợp lệ',
      });
    }

    req.userId = userId;
    next();
  } catch (error) {
    return res.status(401).json({
      message: 'Phiên đăng nhập không hợp lệ',
    });
  }
}

// Lấy thông báo của tài khoản đang đăng nhập
router.get('/', xacThuc, async (req, res) => {
  try {
    const notifications = await Notification.find({
      recipient: req.userId,
    })
      .sort({ createdAt: -1 })
      .limit(100)
      .lean();

    const unreadCount =
      await Notification.countDocuments({
        recipient: req.userId,
        isRead: false,
      });

    return res.json({
      notifications,
      unreadCount,
    });
  } catch (error) {
    return res.status(500).json({
      message: 'Không thể lấy thông báo',
    });
  }
});

// Đếm thông báo chưa đọc
router.get('/unread-count', xacThuc, async (req, res) => {
  try {
    const count = await Notification.countDocuments({
      recipient: req.userId,
      isRead: false,
    });

    return res.json({
      unreadCount: count,
    });
  } catch (error) {
    return res.status(500).json({
      message: 'Không thể đếm thông báo',
    });
  }
});

// Đánh dấu tất cả đã đọc
router.put('/read-all', xacThuc, async (req, res) => {
  try {
    await Notification.updateMany(
      {
        recipient: req.userId,
        isRead: false,
      },
      {
        $set: { isRead: true },
      }
    );

    return res.json({
      message: 'Đã đọc tất cả thông báo',
      unreadCount: 0,
    });
  } catch (error) {
    return res.status(500).json({
      message: 'Không thể cập nhật thông báo',
    });
  }
});

// Đánh dấu một thông báo đã đọc
router.put('/:id/read', xacThuc, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({
        message: 'ID thông báo không hợp lệ',
      });
    }

    const notification =
      await Notification.findOneAndUpdate(
        {
          _id: req.params.id,
          recipient: req.userId,
        },
        {
          $set: { isRead: true },
        },
        {
          new: true,
        }
      );

    if (!notification) {
      return res.status(404).json({
        message: 'Không tìm thấy thông báo',
      });
    }

    return res.json({
      message: 'Đã đánh dấu đã đọc',
      notification,
    });
  } catch (error) {
    return res.status(500).json({
      message: 'Không thể cập nhật thông báo',
    });
  }
});

module.exports = router;
