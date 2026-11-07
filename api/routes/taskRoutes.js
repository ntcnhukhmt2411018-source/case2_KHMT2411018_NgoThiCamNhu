
const express = require('express');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');

const Task = require('../models/Task');
const User = require('../models/User');

// D.1 - Dịch vụ gửi email
const { guiEmail } = require('../services/emailService');

const router = express.Router();

// =====================================================
// 1. XÁC THỰC NGƯỜI DÙNG
// =====================================================
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

// =====================================================
// D.1 - HÀM GỬI EMAIL KHI GIAO CÔNG VIỆC
// =====================================================
async function guiEmailGiaoViec(task, user, nguoiGiao) {
  try {
    if (!user || !user.email) {
      console.log('Người nhận không có email');
      return false;
    }

    const tenNguoiNhan =
      user.fullName || user.name || user.email;

    const tenNguoiGiao =
      nguoiGiao?.fullName ||
      nguoiGiao?.name ||
      nguoiGiao?.email ||
      'Người quản lý';

    const ngayHetHan = task.dueDate
      ? new Date(task.dueDate).toLocaleDateString('vi-VN', {
          timeZone: 'Asia/Ho_Chi_Minh',
        })
      : 'Chưa xác định';

    const tieuDe =
      `Task Manager - Bạn được giao công việc: ${task.title}`;

    const noiDung = `
Xin chào ${tenNguoiNhan}!

Bạn vừa được giao một công việc mới trong Task Manager.

THÔNG TIN CÔNG VIỆC

Tên công việc: ${task.title}

Mô tả: ${task.description || 'Không có mô tả'}

Người giao: ${tenNguoiGiao}

Mức độ ưu tiên: ${task.priority || 'Trung bình'}

Hạn hoàn thành: ${ngayHetHan}

Vui lòng đăng nhập ứng dụng Task Manager để
xem chi tiết và thực hiện công việc.

Trân trọng,
Task Manager
`;

    const ketQua = await guiEmail(
      user.email,
      tieuDe,
      noiDung
    );

    if (ketQua) {
      console.log(
        'Đã gửi email giao việc đến:',
        user.email
      );
      return true;
    }

    console.error(
      'Gửi email giao việc thất bại:',
      user.email
    );

    return false;
  } catch (error) {
    console.error(
      'Lỗi gửi email giao việc:',
      error.message
    );
    return false;
  }
}

// =====================================================
// 2. TÌM NGƯỜI DÙNG THEO EMAIL
// =====================================================
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
    console.error(
      'Lỗi tìm người dùng:',
      error.message
    );

    return res.status(500).json({
      message: 'Không thể tìm người dùng',
    });
  }
});

// =====================================================
// 3. TẠO CÔNG VIỆC
// =====================================================
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
        message:
          'Hạn hoàn thành phải sau ngày bắt đầu',
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
    console.error(
      'Lỗi tạo công việc:',
      error.message
    );

    return res.status(500).json({
      message: 'Không thể tạo công việc',
    });
  }
});

// =====================================================
// 4. LẤY DANH SÁCH CÔNG VIỆC
// =====================================================
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
      .populate(
        'sharePermissions.user',
        'fullName name email'
      )
      .sort({ createdAt: -1 });

    return res.status(200).json({
      tasks: tasks,
    });
  } catch (error) {
    console.error(
      'Lỗi lấy công việc:',
      error.message
    );

    return res.status(500).json({
      message: 'Không thể lấy danh sách công việc',
    });
  }
});

// =====================================================
// 5. GIAO CÔNG VIỆC CHO MỘT NGƯỜI
// D.1 - GỬI EMAIL KHI GIAO VIỆC
// =====================================================
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

    // Kiểm tra người này đã được giao chưa
    const danhSachCu = (task.assignedUsers || [])
      .map((id) => String(id));

    const daDuocGiao =
      danhSachCu.includes(String(user._id)) ||
      String(task.assignedTo) === String(user._id);

    // Cập nhật người phụ trách chính
    task.assignedTo = user._id;

    if (!danhSachCu.includes(String(user._id))) {
      task.assignedUsers.push(user._id);
    }

    // Lưu công việc trước khi gửi email
    await task.save();

    // D.1 - Chỉ gửi cho người mới được giao
    let daGuiEmail = false;

    if (
      !daDuocGiao &&
      String(user._id) !== String(req.userId)
    ) {
      const nguoiGiao = await User.findById(
        req.userId
      );

      daGuiEmail = await guiEmailGiaoViec(
        task,
        user,
        nguoiGiao
      );
    }

    return res.status(200).json({
      message: 'Giao công việc thành công',
      task: task,
      assignee: {
        _id: user._id,
        fullName: user.fullName || user.name || '',
        email: user.email,
      },
      emailSent: daGuiEmail,
    });
  } catch (error) {
    console.error(
      'Lỗi giao công việc:',
      error.message
    );

    return res.status(500).json({
      message: 'Không thể giao công việc',
    });
  }
});

// =====================================================
// 6. GIAO CÔNG VIỆC CHO NHIỀU NGƯỜI (C.1)
// D.1 - GỬI EMAIL CHO NHIỀU NGƯỜI
// =====================================================
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
          message:
            'Vui lòng chọn ít nhất một người',
        });
      }

      if (
        !userIds.every((id) =>
          mongoose.isValidObjectId(id)
        )
      ) {
        return res.status(400).json({
          message:
            'Danh sách người nhận không hợp lệ',
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
        ...new Set(
          userIds.map((id) => String(id))
        ),
      ];

      const users = await User.find({
        _id: { $in: uniqueIds },
      }).select('_id fullName name email');

      if (users.length !== uniqueIds.length) {
        return res.status(404).json({
          message:
            'Có tài khoản người nhận không tồn tại',
        });
      }

      // Danh sách người đã được giao trước đó
      const oldIds = (task.assignedUsers || [])
        .map((id) => String(id));

      if (task.assignedTo) {
        oldIds.push(String(task.assignedTo));
      }

      const danhSachCu = new Set(oldIds);

      // Danh sách người mới được giao
      const nguoiMoi = users.filter(
        (user) =>
          !danhSachCu.has(String(user._id)) &&
          String(user._id) !== String(req.userId)
      );

      // Gộp danh sách cũ và mới
      const allIds = [
        ...new Set([
          ...oldIds,
          ...uniqueIds,
        ]),
      ];

      task.assignedUsers = allIds;

      // Chỉ định người phụ trách chính
      if (primaryUserId !== undefined) {
        if (
          !mongoose.isValidObjectId(primaryUserId)
        ) {
          return res.status(400).json({
            message:
              'ID người phụ trách chính không hợp lệ',
          });
        }

        if (
          !allIds.includes(String(primaryUserId))
        ) {
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
            message:
              'Người phụ trách chính không tồn tại',
          });
        }

        task.assignedTo = primaryUser._id;
      }

      // Lưu MongoDB trước khi gửi email
      await task.save();

      // D.1 - Gửi email cho từng người mới
      let soEmailThanhCong = 0;
      let soEmailThatBai = 0;

      if (nguoiMoi.length > 0) {
        const nguoiGiao = await User.findById(
          req.userId
        );

        const ketQuaGui = await Promise.all(
          nguoiMoi.map((user) =>
            guiEmailGiaoViec(
              task,
              user,
              nguoiGiao
            )
          )
        );

        soEmailThanhCong = ketQuaGui.filter(
          (ketQua) => ketQua === true
        ).length;

        soEmailThatBai =
          nguoiMoi.length - soEmailThanhCong;
      }

      await task.populate([
        {
          path: 'assignedTo',
          select: 'fullName name email',
        },
        {
          path: 'assignedUsers',
          select: 'fullName name email',
        },
        {
          path: 'sharedWith',
          select: 'fullName name email',
        },
      ]);

      return res.status(200).json({
        message:
          'Giao công việc cho nhiều người thành công',
        task: task,
        assignedUsers: task.assignedUsers,
        emailSuccess: soEmailThanhCong,
        emailFailed: soEmailThatBai,
      });
    } catch (error) {
      console.error(
        'Lỗi giao nhiều người:',
        error.message
      );

      return res.status(500).json({
        message:
          'Không thể giao công việc cho nhiều người',
      });
    }
  }
);

// =====================================================
// 7. CHIA SẺ CÔNG VIỆC (C.3 - C.4)
// =====================================================
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

    if (!['viewer', 'editor'].includes(role)) {
      return res.status(400).json({
        message: 'Quyền chia sẻ không hợp lệ',
      });
    }

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

    if (String(userId) === String(req.userId)) {
      return res.status(400).json({
        message: 'Không thể chia sẻ cho chính mình',
      });
    }

    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({
        message:
          'Không tìm thấy tài khoản người nhận',
      });
    }

    const daChiaSe = (task.sharedWith || [])
      .some(
        (id) => String(id) === String(userId)
      );

    if (daChiaSe) {
      return res.status(400).json({
        message:
          'Công việc đã được chia sẻ cho người này',
      });
    }

    task.sharedWith.push(user._id);

    task.sharePermissions.push({
      user: user._id,
      role: role,
    });

    await task.save();

    await task.populate([
      {
        path: 'createdBy',
        select: 'fullName name email',
      },
      {
        path: 'assignedTo',
        select: 'fullName name email',
      },
      {
        path: 'assignedUsers',
        select: 'fullName name email',
      },
      {
        path: 'sharedWith',
        select: 'fullName name email',
      },
      {
        path: 'sharePermissions.user',
        select: 'fullName name email',
      },
    ]);

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
    console.error(
      'Lỗi chia sẻ công việc:',
      error.message
    );

    return res.status(500).json({
      message: 'Không thể chia sẻ công việc',
    });
  }
});

// =====================================================
// 8. C.6 - THAY ĐỔI QUYỀN CHIA SẺ
// =====================================================
router.put(
  '/:id/share/:userId',
  xacThuc,
  async (req, res) => {
    try {
      const { id, userId } = req.params;
      const { role } = req.body;

      if (
        !mongoose.isValidObjectId(id) ||
        !mongoose.isValidObjectId(userId)
      ) {
        return res.status(400).json({
          message: 'ID không hợp lệ',
        });
      }

      if (!['viewer', 'editor'].includes(role)) {
        return res.status(400).json({
          message: 'Quyền chia sẻ không hợp lệ',
        });
      }

      const task = await Task.findOne({
        _id: id,
        createdBy: req.userId,
      });

      if (!task) {
        return res.status(404).json({
          message:
            'Không tìm thấy công việc hoặc không có quyền thay đổi',
        });
      }

      const daChiaSe = (task.sharedWith || [])
        .some(
          (user) =>
            String(user) === String(userId)
        );

      if (!daChiaSe) {
        return res.status(404).json({
          message:
            'Người này chưa được chia sẻ công việc',
        });
      }

      const permission = (
        task.sharePermissions || []
      ).find(
        (item) =>
          String(item.user) === String(userId)
      );

      if (permission) {
        permission.role = role;
      } else {
        task.sharePermissions.push({
          user: userId,
          role: role,
        });
      }

      await task.save();

      await task.populate([
        {
          path: 'createdBy',
          select: 'fullName name email',
        },
        {
          path: 'assignedTo',
          select: 'fullName name email',
        },
        {
          path: 'assignedUsers',
          select: 'fullName name email',
        },
        {
          path: 'sharedWith',
          select: 'fullName name email',
        },
        {
          path: 'sharePermissions.user',
          select: 'fullName name email',
        },
      ]);

      return res.status(200).json({
        message: 'Thay đổi quyền thành công',
        task: task,
      });
    } catch (error) {
      console.error(
        'Lỗi thay đổi quyền:',
        error.message
      );

      return res.status(500).json({
        message:
          'Không thể thay đổi quyền chia sẻ',
      });
    }
  }
);

// =====================================================
// 9. C.6 - THU HỒI QUYỀN CHIA SẺ
// =====================================================
router.delete(
  '/:id/share/:userId',
  xacThuc,
  async (req, res) => {
    try {
      const { id, userId } = req.params;

      if (
        !mongoose.isValidObjectId(id) ||
        !mongoose.isValidObjectId(userId)
      ) {
        return res.status(400).json({
          message: 'ID không hợp lệ',
        });
      }

      const task = await Task.findOne({
        _id: id,
        createdBy: req.userId,
      });

      if (!task) {
        return res.status(404).json({
          message:
            'Không tìm thấy công việc hoặc không có quyền thu hồi',
        });
      }

      const daChiaSe = (task.sharedWith || [])
        .some(
          (user) =>
            String(user) === String(userId)
        );

      if (!daChiaSe) {
        return res.status(404).json({
          message:
            'Người này chưa được chia sẻ công việc',
        });
      }

      task.sharedWith = task.sharedWith.filter(
        (user) =>
          String(user) !== String(userId)
      );

      task.sharePermissions =
        task.sharePermissions.filter(
          (item) =>
            String(item.user) !== String(userId)
        );

      await task.save();

      await task.populate([
        {
          path: 'createdBy',
          select: 'fullName name email',
        },
        {
          path: 'assignedTo',
          select: 'fullName name email',
        },
        {
          path: 'assignedUsers',
          select: 'fullName name email',
        },
        {
          path: 'sharedWith',
          select: 'fullName name email',
        },
        {
          path: 'sharePermissions.user',
          select: 'fullName name email',
        },
      ]);

      return res.status(200).json({
        message:
          'Thu hồi quyền chia sẻ thành công',
        task: task,
      });
    } catch (error) {
      console.error(
        'Lỗi thu hồi quyền:',
        error.message
      );

      return res.status(500).json({
        message:
          'Không thể thu hồi quyền chia sẻ',
      });
    }
  }
);

// =====================================================
// 10. CHỈNH SỬA CÔNG VIỆC
// =====================================================
router.put('/:id', xacThuc, async (req, res) => {
  try {
    if (
      !mongoose.isValidObjectId(req.params.id)
    ) {
      return res.status(400).json({
        message: 'ID công việc không hợp lệ',
      });
    }

    const task = await Task.findById(
      req.params.id
    );

    if (!task) {
      return res.status(404).json({
        message: 'Không tìm thấy công việc',
      });
    }

    const laNguoiTao =
      String(task.createdBy) ===
      String(req.userId);

    const quyenChiaSe = (
      task.sharePermissions || []
    ).find(
      (item) =>
        String(item.user) === String(req.userId)
    );

    const laEditor =
      quyenChiaSe?.role === 'editor' &&
      (task.sharedWith || []).some(
        (id) => String(id) === String(req.userId)
      );

    if (!laNguoiTao && !laEditor) {
      return res.status(403).json({
        message:
          'Bạn không có quyền chỉnh sửa công việc này',
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

    if (
      typeof title !== 'string' ||
      !title.trim()
    ) {
      return res.status(400).json({
        message: 'Vui lòng nhập tên công việc',
      });
    }

    if (
      !['Thấp', 'Trung bình', 'Cao']
        .includes(priority)
    ) {
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
        message:
          'Hạn hoàn thành phải sau ngày bắt đầu',
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
    console.error(
      'Lỗi cập nhật công việc:',
      error.message
    );

    return res.status(500).json({
      message: 'Không thể cập nhật công việc',
    });
  }
});

// =====================================================
// 11. XÓA CÔNG VIỆC
// =====================================================
router.delete('/:id', xacThuc, async (req, res) => {
  try {
    if (
      !mongoose.isValidObjectId(req.params.id)
    ) {
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
    console.error(
      'Lỗi xóa công việc:',
      error.message
    );

    return res.status(500).json({
      message: 'Không thể xóa công việc',
    });
  }
});

module.exports = router;
