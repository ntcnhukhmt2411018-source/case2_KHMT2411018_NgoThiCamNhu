
const express = require('express');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');

const Task = require('../models/Task');

const router = express.Router();

// 1. KIỂM TRA NGƯỜI DÙNG ĐÃ ĐĂNG NHẬP
function xacThuc(req, res, next) {
  const authHeader = req.headers.authorization || '';

  if (!authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      message: 'Vui lòng đăng nhập',
    });
  }

  const token = authHeader.substring(7);

  try {
    const decoded = jwt.verify(
      token,
      process.env.JWT_SECRET
    );

    // Lấy ID người dùng từ token
    const userId = decoded.id || decoded.userId;

    if (!mongoose.isValidObjectId(userId)) {
      return res.status(401).json({
        message: 'Token không có ID người dùng hợp lệ',
      });
    }

    req.userId = userId;
    next();
  } catch (error) {
    return res.status(401).json({
      message: 'Token không hợp lệ hoặc đã hết hạn',
    });
  }
}

// 2. API TẠO CÔNG VIỆC
router.post('/', xacThuc, async (req, res) => {
  try {
    const {
      title,
      description,
      priority,
      startDate,
      dueDate,
    } = req.body;

    // Kiểm tra tên công việc
    if (typeof title !== 'string' || !title.trim()) {
      return res.status(400).json({
        message: 'Vui lòng nhập tên công việc',
      });
    }

    // Kiểm tra ngày
    if (!startDate || !dueDate) {
      return res.status(400).json({
        message: 'Vui lòng chọn đầy đủ ngày',
      });
    }

    const start = new Date(startDate);
    const due = new Date(dueDate);

    if (
      Number.isNaN(start.getTime()) ||
      Number.isNaN(due.getTime())
    ) {
      return res.status(400).json({
        message: 'Ngày không hợp lệ',
      });
    }

    if (due < start) {
      return res.status(400).json({
        message: 'Hạn hoàn thành phải sau ngày bắt đầu',
      });
    }

    // Lưu công việc vào MongoDB
    const task = await Task.create({
      title: title.trim(),
      description: description || '',
      priority: priority || 'Trung bình',
      startDate: start,
      dueDate: due,

      // Người tạo cũng là người phụ trách
      createdBy: req.userId,
      assignedTo: req.userId,
    });

    return res.status(201).json({
      message: 'Tạo công việc thành công',
      task: task,
    });
  } catch (error) {
    console.error('Lỗi tạo công việc:', error.message);

    return res.status(500).json({
      message: 'Không thể tạo công việc',
    });
  }
});

// 3. API LẤY DANH SÁCH CÔNG VIỆC
router.get('/', xacThuc, async (req, res) => {
  try {
    // Lấy công việc người dùng có quyền xem
    const tasks = await Task.find({
      $or: [
        { createdBy: req.userId },
        { assignedTo: req.userId },
        { sharedWith: req.userId },
      ],
    }).sort({ createdAt: -1 });

    return res.status(200).json({
      tasks: tasks,
    });
  } catch (error) {
    console.error('Lỗi lấy công việc:', error.message);

    return res.status(500).json({
      message: 'Không thể lấy danh sách công việc',
    });
  }
});

// 4. API CHỈNH SỬA CÔNG VIỆC
router.put('/:id', xacThuc, async (req, res) => {
  try {
    // Kiểm tra ID công việc
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({
        message: 'ID công việc không hợp lệ',
      });
    }

    // Tìm công việc thuộc người tạo
    const task = await Task.findOne({
      _id: req.params.id,
      createdBy: req.userId,
    });

    if (!task) {
      return res.status(404).json({
        message: 'Không tìm thấy công việc hoặc không có quyền sửa',
      });
    }

    const {
      title,
      description,
      priority,
      status,
      startDate,
      dueDate,
    } = req.body;

    // Kiểm tra tên công việc
    if (typeof title !== 'string' || !title.trim()) {
      return res.status(400).json({
        message: 'Vui lòng nhập tên công việc',
      });
    }

    // Kiểm tra mức ưu tiên
    if (!['Thấp', 'Trung bình', 'Cao'].includes(priority)) {
      return res.status(400).json({
        message: 'Mức ưu tiên không hợp lệ',
      });
    }

    // Kiểm tra trạng thái
    const trangThaiHopLe = [
      'Chưa thực hiện',
      'Đang thực hiện',
      'Đã hoàn thành',
    ];

    if (!trangThaiHopLe.includes(status)) {
      return res.status(400).json({
        message: 'Trạng thái không hợp lệ',
      });
    }

    // Kiểm tra ngày
    if (!startDate || !dueDate) {
      return res.status(400).json({
        message: 'Vui lòng chọn đầy đủ ngày',
      });
    }

    const start = new Date(startDate);
    const due = new Date(dueDate);

    if (
      Number.isNaN(start.getTime()) ||
      Number.isNaN(due.getTime())
    ) {
      return res.status(400).json({
        message: 'Ngày không hợp lệ',
      });
    }

    if (due < start) {
      return res.status(400).json({
        message: 'Hạn hoàn thành phải sau ngày bắt đầu',
      });
    }

    // Cập nhật thông tin công việc
    task.title = title.trim();
    task.description = description || '';
    task.priority = priority;
    task.status = status;
    task.startDate = start;
    task.dueDate = due;

    // Lưu thay đổi vào MongoDB
    await task.save();

    return res.status(200).json({
      message: 'Cập nhật công việc thành công',
      task: task,
    });
  } catch (error) {
    console.error('Lỗi cập nhật công việc:', error.message);

    return res.status(500).json({
      message: 'Không thể cập nhật công việc',
    });
  }
});

module.exports = router;
