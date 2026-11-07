
const express = require('express');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');

const Task = require('../models/Task');
const User = require('../models/User');

const router = express.Router();

// 1. XÁC THỰC NGƯỜI DÙNG
function xacThuc(req, res, next) {
  const authHeader = req.headers.authorization || '';

  if (!authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      message: 'Vui lòng đăng nhập',
    });
  }

  try {
    const token = authHeader.substring(7);
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

// 2. TÌM NGƯỜI DÙNG THEO EMAIL
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

// 3. TẠO CÔNG VIỆC
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
      assignedUsers: [req.userId],
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

// 4. LẤY DANH SÁCH CÔNG VIỆC
router.get('/', xacThuc, async (req, res) => {
  try {
    const tasks = await Task.find({
      $or: [
        { createdBy: req.userId },
        { assignedTo: req.userId },
        { assignedUsers: req.userId },
        { sharedWith: req.userId },
      ],
    })
      .populate('createdBy', 'fullName name email')
      .populate('assignedTo', 'fullName name email')
      .populate('assignedUsers', 'fullName name email')
      .populate('sharedWith', 'fullName name email')
      .sort({ createdAt: -1 });

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

// 5. GIAO CÔNG VIỆC CHO MỘT NGƯỜI
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

    // Cập nhật người phụ trách chính
    task.assignedTo = user._id;

    // Đồng bộ danh sách người được giao
    const danhSach = (task.assignedUsers || []).map(
      (id) => String(id)
    );

    if (!danhSach.includes(String(user._id))) {
      task.assignedUsers.push(user._id);
    }

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

// 6. GIAO CÔNG VIỆC CHO NHIỀU NGƯỜI (C.1)
router.put(
  '/:id/assign-many',
  xacThuc,
  async (req, res) => {
    try {
      const taskId = req.params.id;
      const { userIds, primaryUserId } = req.body;

      if (!mongoose.isValidObjectId(taskId)) {
        return res.status(400).json({
          message: 'ID công việc không hợp lệ',
        });
      }

      if (
        !Array.isArray(userIds) ||
        userIds.length === 0
      ) {
        return res.status(400).json({
          message: 'Vui lòng chọn ít nhất một người',
        });
      }

      if (
        !userIds.every((id) =>
          mongoose.isValidObjectId(id)
        )
      ) {
        return res.status(400).json({
          message: 'Danh sách người nhận không hợp lệ',
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

      // Loại bỏ ID trùng lặp
      const uniqueIds = [
        ...new Set(userIds.map((id) => String(id))),
      ];

      // Kiểm tra tài khoản có tồn tại
      const users = await User.find({
        _id: { $in: uniqueIds },
      }).select('_id fullName name email');

      if (users.length !== uniqueIds.length) {
        return res.status(404).json({
          message: 'Có tài khoản người nhận không tồn tại',
        });
      }

      // Giữ danh sách người được giao trước đó
      const oldIds = (task.assignedUsers || []).map(
        (id) => String(id)
      );

      // Đảm bảo người phụ trách hiện tại cũng có trong danh sách
      if (task.assignedTo) {
        oldIds.push(String(task.assignedTo));
      }

      // Gộp danh sách cũ và mới
      const allIds = [
        ...new Set([...oldIds, ...uniqueIds]),
      ];

      task.assignedUsers = allIds;

      // Có thể chỉ định người phụ trách chính
      if (primaryUserId !== undefined) {
        if (
          !mongoose.isValidObjectId(primaryUserId)
        ) {
          return res.status(400).json({
            message: 'ID người phụ trách chính không hợp lệ',
          });
        }

        if (!allIds.includes(String(primaryUserId))) {
          return res.status(400).json({
            message:
              'Người phụ trách chính phải thuộc danh sách được giao',
          });
        }

        const primaryUser = await User.findById(
          primaryUserId
        );

        if (!primaryUser) {
          return res.status(404).json({
            message: 'Người phụ trách chính không tồn tại',
          });
        }

        task.assignedTo = primaryUser._id;
      }

     await task.save();

     await task.populate([
       { path: 'assignedTo', select: 'fullName name email' },
       { path: 'assignedUsers', select: 'fullName name email' },
       { path: 'sharedWith', select: 'fullName name email' },
     ]);

     return res.status(200).json({
       message: 'Giao công việc cho nhiều người thành công',
       task: task,
       assignedUsers: task.assignedUsers,
     });
    } catch (error) {
      console.error(
        'Lỗi giao nhiều người:',
        error.message
      );

      return res.status(500).json({
        message: 'Không thể giao công việc cho nhiều người',
      });
    }
  }
);


 // 7. CHIA SẺ CÔNG VIỆC
router.post('/:id/share', xacThuc, async (req, res) => {
  try {
    const taskId = req.params.id;
    const { userId, role = 'viewer' } = req.body;

    if (!mongoose.isValidObjectId(taskId)) {
      return res.status(400).json({
        message: 'ID công việc không hợp lệ',
      });
    }

    if (!mongoose.isValidObjectId(userId)) {
      return res.status(400).json({
        message: 'ID người nhận không hợp lệ',
      });
    }

    // Kiểm tra quyền Viewer / Editor
    if (!['viewer', 'editor'].includes(role)) {
      return res.status(400).json({
        message: 'Quyền chia sẻ không hợp lệ',
      });
    }

    // Chỉ người tạo được chia sẻ
    const task = await Task.findOne({
      _id: taskId,
      createdBy: req.userId,
    });

    if (!task) {
      return res.status(404).json({
        message: 'Không tìm thấy công việc hoặc không có quyền chia sẻ',
      });
    }

    if (String(userId) === String(req.userId)) {
      return res.status(400).json({
        message: 'Không thể chia sẻ cho chính mình',
      });
    }

    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({
        message: 'Không tìm thấy tài khoản người nhận',
      });
    }

    // Kiểm tra người dùng đã được chia sẻ chưa
    const daChiaSe = (task.sharedWith || []).some(
      (id) => String(id) === String(userId)
    );

    if (daChiaSe) {
      return res.status(400).json({
        message: 'Công việc đã được chia sẻ cho người này',
      });
    }

    // Lưu người được chia sẻ
    task.sharedWith.push(user._id);

    // Lưu quyền chia sẻ
    task.sharePermissions.push({
      user: user._id,
      role: role,
    });

    await task.save();

    return res.status(200).json({
      message: 'Chia sẻ công việc thành công',
      task: task,
      sharedUser: {
        _id: user._id,
        fullName: user.fullName || user.name || '',
        email: user.email,
        role: role,
      },
    });
  } catch (error) {
    console.error('Lỗi chia sẻ công việc:', error.message);

    return res.status(500).json({
      message: 'Không thể chia sẻ công việc',
    });
  }
});



 // 8. CHỈNH SỬA CÔNG VIỆC
router.put('/:id', xacThuc, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({
        message: 'ID công việc không hợp lệ',
      });
    }

    // Tìm công việc
    const task = await Task.findById(req.params.id);

    if (!task) {
      return res.status(404).json({
        message: 'Không tìm thấy công việc',
      });
    }

    // Kiểm tra người tạo công việc
    const laNguoiTao =
      String(task.createdBy) === String(req.userId);

    // Kiểm tra quyền Editor
    const quyenChiaSe = (task.sharePermissions || []).find(
      (item) => String(item.user) === String(req.userId)
    );

    const laEditor =
      quyenChiaSe?.role === 'editor' &&
      (task.sharedWith || []).some(
        (id) => String(id) === String(req.userId)
      );

    // Chỉ Owner và Editor được chỉnh sửa
    if (!laNguoiTao && !laEditor) {
      return res.status(403).json({
        message: 'Bạn không có quyền chỉnh sửa công việc này',
      });
    }

    // Lấy dữ liệu chỉnh sửa
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

    // Kiểm tra mức độ ưu tiên
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

    // Cập nhật công việc
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


// 9. XÓA CÔNG VIỆC
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
