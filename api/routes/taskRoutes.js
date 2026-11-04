
const express = require('express');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');

const Task = require('../models/Task');
const User = require('../models/User');

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

// 2. API TÌM NGƯỜI DÙNG THEO EMAIL
router.get('/users', xacThuc, async (req, res) => {
  try {
    const email = String(req.query.email || '')
      .trim()
      .toLowerCase();

    if (!email) {
      return res.status(400).json({
        message: 'Vui lòng nhập email người nhận',
      });
    }

    const user = await User.findOne({
      email: email,
    }).select('_id fullName name email');

    if (!user) {
      return res.status(404).json({
        message: 'Không tìm thấy tài khoản',
      });
    }

    return res.status(200).json({
      user: user,
    });
  } catch (error) {
    console.error('Lỗi tìm người dùng:', error.message);

    return res.status(500).json({
      message: 'Không thể tìm người dùng',
    });
  }
});

// 3. API TẠO CÔNG VIỆC
router.post('/', xacThuc, async (req, res) => {
  try {
    const {
      title,
      description,
      priority,
      startDate,
      dueDate,
    } = req.body;

    if (typeof title !== 'string' || !title.trim()) {
      return res.status(400).json({
        message: 'Vui lòng nhập tên công việc',
      });
    }

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

    const task = await Task.create({
      title: title.trim(),
      description: description || '',
      priority: priority || 'Trung bình',
      startDate: start,
      dueDate: due,
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

// 4. API LẤY DANH SÁCH CÔNG VIỆC
router.get('/', xacThuc, async (req, res) => {
  try {
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

// 5. API GIAO CÔNG VIỆC CHO NGƯỜI KHÁC
router.put('/:id/assign', xacThuc, async (req, res) => {
  try {
    const taskId = req.params.id;
    const { assignedTo } = req.body;

    if (!mongoose.isValidObjectId(taskId)) {
      return res.status(400).json({
        message: 'ID công việc không hợp lệ',
      });
    }

    if (!mongoose.isValidObjectId(assignedTo)) {
      return res.status(400).json({
        message: 'ID người nhận không hợp lệ',
      });
    }

    const task = await Task.findOne({
      _id: taskId,
      createdBy: req.userId,
    });

    if (!task) {
      return res.status(404).json({
        message:
          'Không tìm thấy công việc hoặc không có quyền giao',
      });
    }

    const user = await User.findById(assignedTo);

    if (!user) {
      return res.status(404).json({
        message: 'Tài khoản người nhận không tồn tại',
      });
    }

    task.assignedTo = user._id;
    await task.save();

    return res.status(200).json({
      message: 'Giao công việc thành công',
      task: task,
      assignee: {
        _id: user._id,
        fullName: user.fullName || user.name || '',
        email: user.email,
      },
    });
  } catch (error) {
    console.error('Lỗi giao công việc:', error.message);

    return res.status(500).json({
      message: 'Không thể giao công việc',
    });
  }
});

// 6. API CHIA SẺ CÔNG VIỆC (MỚI)
router.post('/:id/share', xacThuc, async (req, res) => {
  try {
    const taskId = req.params.id;
    const { userId } = req.body;

    // Kiểm tra ID công việc
    if (!mongoose.isValidObjectId(taskId)) {
      return res.status(400).json({
        message: 'ID công việc không hợp lệ',
      });
    }

    // Kiểm tra ID người nhận
    if (!mongoose.isValidObjectId(userId)) {
      return res.status(400).json({
        message: 'ID người nhận không hợp lệ',
      });
    }

    // Chỉ người tạo mới được chia sẻ
    const task = await Task.findOne({
      _id: taskId,
      createdBy: req.userId,
    });

    if (!task) {
      return res.status(404).json({
        message:
          'Không tìm thấy công việc hoặc không có quyền chia sẻ',
      });
    }

    // Không chia sẻ cho chính mình
    if (String(userId) === String(req.userId)) {
      return res.status(400).json({
        message: 'Không thể chia sẻ cho chính mình',
      });
    }

    // Kiểm tra người nhận tồn tại
    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({
        message: 'Không tìm thấy tài khoản người nhận',
      });
    }

    // Kiểm tra đã chia sẻ chưa
    const daChiaSe = (task.sharedWith || []).some(
      (id) => String(id) === String(userId)
    );

    if (daChiaSe) {
      return res.status(400).json({
        message: 'Công việc đã được chia sẻ cho người này',
      });
    }

    // Thêm người nhận vào danh sách chia sẻ
    task.sharedWith.push(user._id);

    await task.save();

    return res.status(200).json({
      message: 'Chia sẻ công việc thành công',
      task: task,
      sharedUser: {
        _id: user._id,
        fullName: user.fullName || user.name || '',
        email: user.email,
      },
    });
  } catch (error) {
    console.error('Lỗi chia sẻ công việc:', error.message);

    return res.status(500).json({
      message: 'Không thể chia sẻ công việc',
    });
  }
});

// 7. API CHỈNH SỬA CÔNG VIỆC
router.put('/:id', xacThuc, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({
        message: 'ID công việc không hợp lệ',
      });
    }

    const task = await Task.findOne({
      _id: req.params.id,
      createdBy: req.userId,
    });

    if (!task) {
      return res.status(404).json({
        message:
          'Không tìm thấy công việc hoặc không có quyền sửa',
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

    if (typeof title !== 'string' || !title.trim()) {
      return res.status(400).json({
        message: 'Vui lòng nhập tên công việc',
      });
    }

    if (!['Thấp', 'Trung bình', 'Cao'].includes(priority)) {
      return res.status(400).json({
        message: 'Mức ưu tiên không hợp lệ',
      });
    }

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

    task.title = title.trim();
    task.description = description || '';
    task.priority = priority;
    task.status = status;
    task.startDate = start;
    task.dueDate = due;

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

// 8. API XÓA CÔNG VIỆC
router.delete('/:id', xacThuc, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({
        message: 'ID công việc không hợp lệ',
      });
    }

    const task = await Task.findOneAndDelete({
      _id: req.params.id,
      createdBy: req.userId,
    });

    if (!task) {
      return res.status(404).json({
        message:
          'Không tìm thấy công việc hoặc không có quyền xóa',
      });
    }

    return res.status(200).json({
      message: 'Xóa công việc thành công',
    });
  } catch (error) {
    console.error('Lỗi xóa công việc:', error.message);

    return res.status(500).json({
      message: 'Không thể xóa công việc',
    });
  }
});

module.exports = router;
