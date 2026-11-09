
const express = require('express');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');

const Task = require('../models/Task');
const User = require('../models/User');
const Notification = require('../models/Notification');
const EmailLog = require('../models/EmailLog');
const { guiEmail } = require('../services/emailService');

const router = express.Router();

// ========================================
// 1. XÁC THỰC NGƯỜI DÙNG
// ========================================
function xacThuc(req, res, next) {
  const authHeader = req.headers.authorization || '';

  if (!authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      message: 'Vui lòng đăng nhập'
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
        message: 'Token không hợp lệ'
      });
    }

    req.userId = userId;
    next();
  } catch (error) {
    return res.status(401).json({
      message: 'Token không hợp lệ hoặc đã hết hạn'
    });
  }
}

// ========================================
// 2. CÁC HÀM DÙNG CHUNG
// ========================================
function layTenNguoiDung(user) {
  return (
    user?.fullName ||
    user?.name ||
    user?.email ||
    'Một người dùng'
  );
}

function dinhDangNgayD3(ngay) {
  if (!ngay) return 'Chưa xác định';

  return new Date(ngay).toLocaleDateString('vi-VN', {
    timeZone: 'Asia/Ho_Chi_Minh'
  });
}

function layDanhSachNguoiLienQuan(task, nguoiThucHien) {
  const danhSachId = [
    task.createdBy,
    task.assignedTo,
    ...(task.assignedUsers || []),
    ...(task.sharedWith || [])
  ];

  return [
    ...new Set(
      danhSachId
        .filter(Boolean)
        .map(id => String(id))
    )
  ].filter(id => id !== String(nguoiThucHien));
}

// ========================================
// 3. D.6 - GỬI EMAIL VÀ LƯU LỊCH SỬ
// ========================================
async function guiEmailVaLuuLichSu(
  task,
  user,
  type,
  tieuDe,
  noiDung
) {
  if (!user?.email) return false;

  let thanhCong = false;
  let thongBaoLoi = '';

  try {
    thanhCong =
      (await guiEmail(
        user.email,
        tieuDe,
        noiDung
      )) === true;

    if (!thanhCong) {
      thongBaoLoi = 'Gửi email thất bại';
    }
  } catch (error) {
    thongBaoLoi = error.message;

    console.error(
      'D.6 - Lỗi gửi email:',
      error.message
    );
  }

  try {
    await EmailLog.create({
      task: task._id,
      recipient: user._id,
      email: user.email,
      type: type,
      dueDate: task.dueDate,
      subject: tieuDe,
      content: noiDung,
      status: thanhCong ? 'success' : 'failed',
      sentAt: thanhCong ? new Date() : null,
      errorMessage: thongBaoLoi
    });

    console.log(
      'D.6 - Đã lưu lịch sử:',
      type,
      user.email,
      thanhCong ? 'success' : 'failed'
    );
  } catch (error) {
    console.error(
      'D.6 - Lỗi lưu lịch sử:',
      error.message
    );
  }

  return thanhCong;
}

// ========================================
// 4. D.1 - EMAIL KHI GIAO CÔNG VIỆC
// ========================================
async function guiEmailGiaoViec(task, user, nguoiGiao) {
  try {
    if (!user?.email) return false;

    const tieuDe =
      `Task Manager - Bạn được giao công việc: ${task.title}`;

    const noiDung = `
Xin chào ${layTenNguoiDung(user)}!

Bạn vừa được giao một công việc mới trong Task Manager.

THÔNG TIN CÔNG VIỆC

Tên công việc: ${task.title}
Mô tả: ${task.description || 'Không có mô tả'}
Người giao: ${layTenNguoiDung(nguoiGiao)}
Mức độ ưu tiên: ${task.priority || 'Trung bình'}
Hạn hoàn thành: ${dinhDangNgayD3(task.dueDate)}

Vui lòng đăng nhập ứng dụng Task Manager
để xem chi tiết và thực hiện công việc.

Trân trọng,
Task Manager
`;

    return await guiEmailVaLuuLichSu(
      task,
      user,
      'task_assigned',
      tieuDe,
      noiDung
    );
  } catch (error) {
    console.error(
      'Lỗi gửi email giao việc:',
      error.message
    );
    return false;
  }
}

// ========================================
// 5. D.2 - EMAIL MỜI CHIA SẺ CÔNG VIỆC
// ========================================
async function guiEmailMoiChiaSe(
  task,
  user,
  nguoiMoi,
  role
) {
  try {
    if (!user?.email) return false;

    const quyen = role === 'editor'
      ? 'Tham gia và chỉnh sửa công việc (editor)'
      : 'Xem công việc (viewer)';

    const tieuDe =
      `Task Manager - Lời mời tham gia công việc: ${task.title}`;

    const noiDung = `
Xin chào ${layTenNguoiDung(user)}!

${layTenNguoiDung(nguoiMoi)} vừa mời bạn xem hoặc
tham gia một công việc trong Task Manager.

THÔNG TIN CÔNG VIỆC

Tên công việc: ${task.title}
Mô tả: ${task.description || 'Không có mô tả'}
Người mời: ${layTenNguoiDung(nguoiMoi)}
Quyền của bạn: ${quyen}
Hạn hoàn thành: ${dinhDangNgayD3(task.dueDate)}

Vui lòng đăng nhập ứng dụng Task Manager
để xem công việc được chia sẻ.

Trân trọng,
Task Manager
`;

    return await guiEmailVaLuuLichSu(
      task,
      user,
      'task_shared',
      tieuDe,
      noiDung
    );
  } catch (error) {
    console.error(
      'Lỗi gửi email mời chia sẻ:',
      error.message
    );
    return false;
  }
}

// ========================================
// 6. D.3 - EMAIL KHI THÔNG TIN THAY ĐỔI
// ========================================
async function guiEmailThayDoiCongViec(
  task,
  user,
  nguoiSua,
  danhSachThayDoi
) {
  try {
    if (
      !user?.email ||
      danhSachThayDoi.length === 0
    ) {
      return false;
    }

    const tieuDe =
      `Task Manager - Công việc được cập nhật: ${task.title}`;

    const noiDung = `
Xin chào ${layTenNguoiDung(user)}!

${layTenNguoiDung(nguoiSua)} vừa cập nhật thông tin
công việc "${task.title}" trong Task Manager.

NHỮNG THÔNG TIN ĐÃ THAY ĐỔI

${danhSachThayDoi.join('\n')}

Vui lòng đăng nhập ứng dụng Task Manager
để xem thông tin công việc mới nhất.

Trân trọng,
Task Manager
`;

    return await guiEmailVaLuuLichSu(
      task,
      user,
      'task_updated',
      tieuDe,
      noiDung
    );
  } catch (error) {
    console.error(
      'Lỗi gửi email cập nhật công việc:',
      error.message
    );
    return false;
  }
}

// ========================================
// 7. D.4 - EMAIL KHI CÔNG VIỆC HOÀN THÀNH
// ========================================
async function guiEmailHoanThanhCongViec(
  task,
  user,
  nguoiHoanThanh
) {
  try {
    if (!user?.email) return false;

    const tieuDe =
      `Task Manager - Công việc đã hoàn thành: ${task.title}`;

    const noiDung = `
Xin chào ${layTenNguoiDung(user)}!

Công việc "${task.title}" đã được đánh dấu
ĐÃ HOÀN THÀNH trong hệ thống Task Manager.

THÔNG TIN CÔNG VIỆC

Tên công việc: ${task.title}
Mô tả: ${task.description || 'Không có mô tả'}
Người cập nhật: ${layTenNguoiDung(nguoiHoanThanh)}
Mức độ ưu tiên: ${task.priority || 'Trung bình'}
Hạn hoàn thành: ${dinhDangNgayD3(task.dueDate)}
Trạng thái: Đã hoàn thành

Bạn có thể đăng nhập ứng dụng Task Manager
để xem chi tiết công việc.

Trân trọng,
Task Manager
`;

    const ketQua = await guiEmailVaLuuLichSu(
      task,
      user,
      'task_completed',
      tieuDe,
      noiDung
    );

    if (ketQua) {
      console.log(
        `D.4 - Đã gửi email hoàn thành tới ${user.email}`
      );
    } else {
      console.log(
        `D.4 - Gửi email hoàn thành thất bại: ${user.email}`
      );
    }

    return ketQua;
  } catch (error) {
    console.error(
      'D.4 - Lỗi gửi email hoàn thành:',
      error.message
    );
    return false;
  }
}

// ========================================
// 8. D.7 - TẠO THÔNG BÁO MONGODB
// ========================================
async function taoThongBao({
  recipient,
  sender,
  task,
  title,
  message,
  type
}) {
  try {
    if (String(recipient) === String(sender)) {
      return false;
    }

    await Notification.create({
      recipient,
      sender,
      task,
      title,
      message,
      type,
      isRead: false
    });

    console.log('Đã tạo thông báo:', title);
    return true;
  } catch (error) {
    console.error(
      'Lỗi tạo thông báo:',
      error.message
    );
    return false;
  }
}

// ========================================
// 9. TÌM NGƯỜI DÙNG THEO EMAIL
// ========================================
router.get('/users', xacThuc, async (req, res) => {
  try {
    const email = String(req.query.email || '')
      .trim()
      .toLowerCase();

    if (!email) {
      return res.status(400).json({
        message: 'Vui lòng nhập email người nhận'
      });
    }

    const user = await User.findOne({
      email
    }).select('_id fullName name email');

    if (!user) {
      return res.status(404).json({
        message: 'Không tìm thấy tài khoản'
      });
    }

    return res.json({ user });
  } catch (error) {
    return res.status(500).json({
      message: 'Không thể tìm người dùng'
    });
  }
});

// ========================================
// 10. TẠO CÔNG VIỆC
// ========================================
router.post('/', xacThuc, async (req, res) => {
  try {
    const {
      title,
      description,
      priority,
      startDate,
      dueDate
    } = req.body;

    if (
      typeof title !== 'string' ||
      !title.trim()
    ) {
      return res.status(400).json({
        message: 'Vui lòng nhập tên công việc'
      });
    }

    if (!startDate || !dueDate) {
      return res.status(400).json({
        message: 'Vui lòng chọn đầy đủ ngày'
      });
    }

    const start = new Date(startDate);
    const due = new Date(dueDate);

    if (
      Number.isNaN(start.getTime()) ||
      Number.isNaN(due.getTime())
    ) {
      return res.status(400).json({
        message: 'Ngày không hợp lệ'
      });
    }

    if (due < start) {
      return res.status(400).json({
        message: 'Hạn hoàn thành phải sau ngày bắt đầu'
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
      assignedUsers: [req.userId]
    });

    return res.status(201).json({
      message: 'Tạo công việc thành công',
      task
    });
  } catch (error) {
    console.error(
      'Lỗi tạo công việc:',
      error.message
    );

    return res.status(500).json({
      message: 'Không thể tạo công việc'
    });
  }
});

// ========================================
// 11. LẤY DANH SÁCH CÔNG VIỆC
// ========================================
router.get('/', xacThuc, async (req, res) => {
  try {
    const tasks = await Task.find({
      $or: [
        { createdBy: req.userId },
        { assignedTo: req.userId },
        { assignedUsers: req.userId },
        { sharedWith: req.userId }
      ]
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

    return res.json({ tasks });
  } catch (error) {
    console.error(
      'Lỗi lấy công việc:',
      error.message
    );

    return res.status(500).json({
      message: 'Không thể lấy danh sách công việc'
    });
  }
});

// ========================================
// 12. GIAO CÔNG VIỆC CHO MỘT NGƯỜI
// D.1 + D.6 + D.7
// ========================================
router.put('/:id/assign', xacThuc, async (req, res) => {
  try {
    const taskId = req.params.id;
    const { assignedTo } = req.body;

    if (
      !mongoose.isValidObjectId(taskId) ||
      !mongoose.isValidObjectId(assignedTo)
    ) {
      return res.status(400).json({
        message: 'ID không hợp lệ'
      });
    }

    const task = await Task.findOne({
      _id: taskId,
      createdBy: req.userId
    });

    if (!task) {
      return res.status(404).json({
        message:
          'Không tìm thấy công việc hoặc không có quyền giao'
      });
    }

    const user = await User.findById(assignedTo);

    if (!user) {
      return res.status(404).json({
        message: 'Tài khoản người nhận không tồn tại'
      });
    }

    const danhSachCu = (task.assignedUsers || [])
      .map(id => String(id));

    const daDuocGiao =
      danhSachCu.includes(String(user._id)) ||
      String(task.assignedTo) === String(user._id);

    task.assignedTo = user._id;

    if (!danhSachCu.includes(String(user._id))) {
      task.assignedUsers.push(user._id);
    }

    await task.save();

    let daGuiEmail = false;

    if (
      !daDuocGiao &&
      String(user._id) !== String(req.userId)
    ) {
      const nguoiGiao = await User.findById(req.userId);

      await taoThongBao({
        recipient: user._id,
        sender: req.userId,
        task: task._id,
        title: 'Bạn được giao công việc mới',
        message:
          `${layTenNguoiDung(nguoiGiao)} đã giao cho bạn ` +
          `công việc "${task.title}".`,
        type: 'task_assigned'
      });

      daGuiEmail = await guiEmailGiaoViec(
        task,
        user,
        nguoiGiao
      );
    }

    return res.json({
      message: 'Giao công việc thành công',
      task,
      assignee: {
        _id: user._id,
        fullName: user.fullName || user.name || '',
        email: user.email
      },
      emailSent: daGuiEmail
    });
  } catch (error) {
    console.error(
      'Lỗi giao công việc:',
      error.message
    );

    return res.status(500).json({
      message: 'Không thể giao công việc'
    });
  }
});

// ========================================
// 13. GIAO CÔNG VIỆC CHO NHIỀU NGƯỜI
// ========================================
router.put(
  '/:id/assign-many',
  xacThuc,
  async (req, res) => {
    try {
      const { userIds, primaryUserId } = req.body;

      if (!mongoose.isValidObjectId(req.params.id)) {
        return res.status(400).json({
          message: 'ID công việc không hợp lệ'
        });
      }

      if (
        !Array.isArray(userIds) ||
        userIds.length === 0
      ) {
        return res.status(400).json({
          message: 'Vui lòng chọn ít nhất một người'
        });
      }

      if (
        !userIds.every(id =>
          mongoose.isValidObjectId(id)
        )
      ) {
        return res.status(400).json({
          message: 'Danh sách người nhận không hợp lệ'
        });
      }

      const task = await Task.findOne({
        _id: req.params.id,
        createdBy: req.userId
      });

      if (!task) {
        return res.status(404).json({
          message:
            'Không tìm thấy công việc hoặc không có quyền giao'
        });
      }

      const uniqueIds = [
        ...new Set(userIds.map(id => String(id)))
      ];

      const users = await User.find({
        _id: { $in: uniqueIds }
      }).select('_id fullName name email');

      if (users.length !== uniqueIds.length) {
        return res.status(404).json({
          message: 'Có tài khoản người nhận không tồn tại'
        });
      }

      const oldIds = (task.assignedUsers || [])
        .map(id => String(id));

      if (task.assignedTo) {
        oldIds.push(String(task.assignedTo));
      }

      const danhSachCu = new Set(oldIds);

      const nguoiMoi = users.filter(user =>
        !danhSachCu.has(String(user._id)) &&
        String(user._id) !== String(req.userId)
      );

      const allIds = [
        ...new Set([...oldIds, ...uniqueIds])
      ];

      if (primaryUserId !== undefined) {
        if (!mongoose.isValidObjectId(primaryUserId)) {
          return res.status(400).json({
            message:
              'ID người phụ trách chính không hợp lệ'
          });
        }

        if (!allIds.includes(String(primaryUserId))) {
          return res.status(400).json({
            message:
              'Người phụ trách chính phải thuộc danh sách được giao'
          });
        }

        const primaryUser = await User.findById(
          primaryUserId
        );

        if (!primaryUser) {
          return res.status(404).json({
            message:
              'Người phụ trách chính không tồn tại'
          });
        }

        task.assignedTo = primaryUser._id;
      }

      task.assignedUsers = allIds;
      await task.save();

      let soEmailThanhCong = 0;
      let soEmailThatBai = 0;

      if (nguoiMoi.length > 0) {
        const nguoiGiao = await User.findById(
          req.userId
        );

        await Promise.all(
          nguoiMoi.map(user =>
            taoThongBao({
              recipient: user._id,
              sender: req.userId,
              task: task._id,
              title: 'Bạn được giao công việc mới',
              message:
                `${layTenNguoiDung(nguoiGiao)} đã giao ` +
                `cho bạn công việc "${task.title}".`,
              type: 'task_assigned'
            })
          )
        );

        const ketQuaGui = await Promise.all(
          nguoiMoi.map(user =>
            guiEmailGiaoViec(
              task,
              user,
              nguoiGiao
            )
          )
        );

        soEmailThanhCong = ketQuaGui.filter(
          ketQua => ketQua === true
        ).length;

        soEmailThatBai =
          nguoiMoi.length - soEmailThanhCong;
      }

      await task.populate([
        {
          path: 'assignedTo',
          select: 'fullName name email'
        },
        {
          path: 'assignedUsers',
          select: 'fullName name email'
        },
        {
          path: 'sharedWith',
          select: 'fullName name email'
        }
      ]);

      return res.json({
        message:
          'Giao công việc cho nhiều người thành công',
        task,
        assignedUsers: task.assignedUsers,
        emailSuccess: soEmailThanhCong,
        emailFailed: soEmailThatBai
      });
    } catch (error) {
      console.error(
        'Lỗi giao nhiều người:',
        error.message
      );

      return res.status(500).json({
        message:
          'Không thể giao công việc cho nhiều người'
      });
    }
  }
);

// ========================================
// 14. CHIA SẺ CÔNG VIỆC
// D.2 + D.6 + D.7
// ========================================
router.post('/:id/share', xacThuc, async (req, res) => {
  try {
    const { userId, role = 'viewer' } = req.body;

    if (
      !mongoose.isValidObjectId(req.params.id) ||
      !mongoose.isValidObjectId(userId)
    ) {
      return res.status(400).json({
        message: 'ID không hợp lệ'
      });
    }

    if (!['viewer', 'editor'].includes(role)) {
      return res.status(400).json({
        message: 'Quyền chia sẻ không hợp lệ'
      });
    }

    const task = await Task.findOne({
      _id: req.params.id,
      createdBy: req.userId
    });

    if (!task) {
      return res.status(404).json({
        message:
          'Không tìm thấy công việc hoặc không có quyền chia sẻ'
      });
    }

    if (String(userId) === String(req.userId)) {
      return res.status(400).json({
        message: 'Không thể chia sẻ cho chính mình'
      });
    }

    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({
        message: 'Không tìm thấy tài khoản người nhận'
      });
    }

    const daChiaSe = (task.sharedWith || []).some(
      id => String(id) === String(userId)
    );

    if (daChiaSe) {
      return res.status(400).json({
        message:
          'Công việc đã được chia sẻ cho người này'
      });
    }

    task.sharedWith.push(user._id);

    task.sharePermissions.push({
      user: user._id,
      role
    });

    await task.save();

    const nguoiChiaSe = await User.findById(
      req.userId
    );

    await taoThongBao({
      recipient: user._id,
      sender: req.userId,
      task: task._id,
      title: 'Bạn được chia sẻ công việc',
      message:
        `${layTenNguoiDung(nguoiChiaSe)} đã chia sẻ ` +
        `công việc "${task.title}" với bạn.`,
      type: 'task_shared'
    });

    const daGuiEmailMoi = await guiEmailMoiChiaSe(
      task,
      user,
      nguoiChiaSe,
      role
    );

    await task.populate([
      {
        path: 'createdBy',
        select: 'fullName name email'
      },
      {
        path: 'assignedTo',
        select: 'fullName name email'
      },
      {
        path: 'assignedUsers',
        select: 'fullName name email'
      },
      {
        path: 'sharedWith',
        select: 'fullName name email'
      },
      {
        path: 'sharePermissions.user',
        select: 'fullName name email'
      }
    ]);

    return res.json({
      message: 'Chia sẻ công việc thành công',
      emailSent: daGuiEmailMoi,
      task,
      sharedUser: {
        _id: user._id,
        fullName: user.fullName || user.name || '',
        email: user.email,
        role
      }
    });
  } catch (error) {
    console.error(
      'Lỗi chia sẻ công việc:',
      error.message
    );

    return res.status(500).json({
      message: 'Không thể chia sẻ công việc'
    });
  }
});

// ========================================
// 15. THAY ĐỔI QUYỀN CHIA SẺ
// ========================================
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
          message: 'ID không hợp lệ'
        });
      }

      if (!['viewer', 'editor'].includes(role)) {
        return res.status(400).json({
          message: 'Quyền chia sẻ không hợp lệ'
        });
      }

      const task = await Task.findOne({
        _id: id,
        createdBy: req.userId
      });

      if (!task) {
        return res.status(404).json({
          message:
            'Không tìm thấy công việc hoặc không có quyền thay đổi'
        });
      }

      const daChiaSe = (task.sharedWith || []).some(
        user => String(user) === String(userId)
      );

      if (!daChiaSe) {
        return res.status(404).json({
          message:
            'Người này chưa được chia sẻ công việc'
        });
      }

      const permission = (
        task.sharePermissions || []
      ).find(
        item => String(item.user) === String(userId)
      );

      if (permission) {
        permission.role = role;
      } else {
        task.sharePermissions.push({
          user: userId,
          role
        });
      }

      await task.save();

      await task.populate([
        {
          path: 'createdBy',
          select: 'fullName name email'
        },
        {
          path: 'assignedTo',
          select: 'fullName name email'
        },
        {
          path: 'assignedUsers',
          select: 'fullName name email'
        },
        {
          path: 'sharedWith',
          select: 'fullName name email'
        },
        {
          path: 'sharePermissions.user',
          select: 'fullName name email'
        }
      ]);

      return res.json({
        message: 'Thay đổi quyền thành công',
        task
      });
    } catch (error) {
      return res.status(500).json({
        message: 'Không thể thay đổi quyền chia sẻ'
      });
    }
  }
);

// ========================================
// 16. THU HỒI QUYỀN CHIA SẺ
// ========================================
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
          message: 'ID không hợp lệ'
        });
      }

      const task = await Task.findOne({
        _id: id,
        createdBy: req.userId
      });

      if (!task) {
        return res.status(404).json({
          message:
            'Không tìm thấy công việc hoặc không có quyền thu hồi'
        });
      }

      const daChiaSe = (task.sharedWith || []).some(
        user => String(user) === String(userId)
      );

      if (!daChiaSe) {
        return res.status(404).json({
          message:
            'Người này chưa được chia sẻ công việc'
        });
      }

      task.sharedWith = task.sharedWith.filter(
        user => String(user) !== String(userId)
      );

      task.sharePermissions =
        task.sharePermissions.filter(
          item => String(item.user) !== String(userId)
        );

      await task.save();

      await task.populate([
        {
          path: 'createdBy',
          select: 'fullName name email'
        },
        {
          path: 'assignedTo',
          select: 'fullName name email'
        },
        {
          path: 'assignedUsers',
          select: 'fullName name email'
        },
        {
          path: 'sharedWith',
          select: 'fullName name email'
        },
        {
          path: 'sharePermissions.user',
          select: 'fullName name email'
        }
      ]);

      return res.json({
        message: 'Thu hồi quyền chia sẻ thành công',
        task
      });
    } catch (error) {
      return res.status(500).json({
        message: 'Không thể thu hồi quyền chia sẻ'
      });
    }
  }
);

// ========================================
// 17. CHỈNH SỬA CÔNG VIỆC
// D.3 + D.4 + D.6
// ========================================
router.put('/:id', xacThuc, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({
        message: 'ID công việc không hợp lệ'
      });
    }

    const task = await Task.findById(req.params.id);

    if (!task) {
      return res.status(404).json({
        message: 'Không tìm thấy công việc'
      });
    }

    const laNguoiTao =
      String(task.createdBy) === String(req.userId);

    const quyenChiaSe = (
      task.sharePermissions || []
    ).find(
      item =>
        String(item.user) === String(req.userId)
    );

    const laEditor =
      quyenChiaSe?.role === 'editor' &&
      (task.sharedWith || []).some(
        id => String(id) === String(req.userId)
      );

    if (!laNguoiTao && !laEditor) {
      return res.status(403).json({
        message:
          'Bạn không có quyền chỉnh sửa công việc này'
      });
    }

    const {
      title,
      description,
      priority,
      status,
      startDate,
      dueDate
    } = req.body;

    if (
      typeof title !== 'string' ||
      !title.trim()
    ) {
      return res.status(400).json({
        message: 'Vui lòng nhập tên công việc'
      });
    }

    if (!['Thấp', 'Trung bình', 'Cao'].includes(priority)) {
      return res.status(400).json({
        message: 'Mức ưu tiên không hợp lệ'
      });
    }

    const trangThaiHopLe = [
      'Chưa thực hiện',
      'Đang thực hiện',
      'Đã hoàn thành'
    ];

    if (!trangThaiHopLe.includes(status)) {
      return res.status(400).json({
        message: 'Trạng thái không hợp lệ'
      });
    }

    if (!startDate || !dueDate) {
      return res.status(400).json({
        message: 'Vui lòng chọn đầy đủ ngày'
      });
    }

    const start = new Date(startDate);
    const due = new Date(dueDate);

    if (
      Number.isNaN(start.getTime()) ||
      Number.isNaN(due.getTime())
    ) {
      return res.status(400).json({
        message: 'Ngày không hợp lệ'
      });
    }

    if (due < start) {
      return res.status(400).json({
        message:
          'Hạn hoàn thành phải sau ngày bắt đầu'
      });
    }

    // Kiểm tra D.4
    const trangThaiCu = task.status;

    const vuaHoanThanh =
      trangThaiCu !== 'Đã hoàn thành' &&
      status === 'Đã hoàn thành';

    // So sánh D.3
    const danhSachThayDoi = [];

    if (task.title !== title.trim()) {
      danhSachThayDoi.push(
        `Tên công việc: ${task.title} -> ${title.trim()}`
      );
    }

    if (
      (task.description || '') !==
      (description || '')
    ) {
      danhSachThayDoi.push(
        `Mô tả: ${task.description || 'Không có'} ` +
        `-> ${description || 'Không có'}`
      );
    }

    if (task.priority !== priority) {
      danhSachThayDoi.push(
        `Mức ưu tiên: ${task.priority} -> ${priority}`
      );
    }

    if (
      new Date(task.startDate).getTime() !==
      start.getTime()
    ) {
      danhSachThayDoi.push(
        `Ngày bắt đầu: ${dinhDangNgayD3(task.startDate)} ` +
        `-> ${dinhDangNgayD3(start)}`
      );
    }

    if (
      new Date(task.dueDate).getTime() !==
      due.getTime()
    ) {
      danhSachThayDoi.push(
        `Hạn hoàn thành: ${dinhDangNgayD3(task.dueDate)} ` +
        `-> ${dinhDangNgayD3(due)}`
      );
    }

    // Lưu công việc
    task.title = title.trim();
    task.description = description || '';
    task.priority = priority;
    task.status = status;
    task.startDate = start;
    task.dueDate = due;

    await task.save();

    let soEmailThanhCong = 0;
    let soEmailThatBai = 0;

    let soEmailD4ThanhCong = 0;
    let soEmailD4ThatBai = 0;

    if (
      danhSachThayDoi.length > 0 ||
      vuaHoanThanh
    ) {
      try {
        const uniqueIds = layDanhSachNguoiLienQuan(
          task,
          req.userId
        );

        if (uniqueIds.length > 0) {
          const nguoiNhan = await User.find({
            _id: { $in: uniqueIds }
          }).select('fullName name email');

          const nguoiSua = await User.findById(
            req.userId
          ).select('fullName name email');

          // D.3 - Email cập nhật
          if (danhSachThayDoi.length > 0) {
            const ketQuaD3 = await Promise.all(
              nguoiNhan.map(user =>
                guiEmailThayDoiCongViec(
                  task,
                  user,
                  nguoiSua,
                  danhSachThayDoi
                )
              )
            );

            soEmailThanhCong = ketQuaD3.filter(
              ketQua => ketQua === true
            ).length;

            soEmailThatBai =
              nguoiNhan.length - soEmailThanhCong;
          }

          // D.4 - Email hoàn thành
          if (vuaHoanThanh) {
            console.log(
              `D.4 - Công việc hoàn thành: ${task.title}`
            );

            const ketQuaD4 = await Promise.all(
              nguoiNhan.map(user =>
                guiEmailHoanThanhCongViec(
                  task,
                  user,
                  nguoiSua
                )
              )
            );

            soEmailD4ThanhCong = ketQuaD4.filter(
              ketQua => ketQua === true
            ).length;

            soEmailD4ThatBai =
              nguoiNhan.length - soEmailD4ThanhCong;

            console.log(
              `D.4 - Gửi thành công: ${soEmailD4ThanhCong}`
            );

            console.log(
              `D.4 - Gửi thất bại: ${soEmailD4ThatBai}`
            );
          }
        }
      } catch (emailError) {
        console.error(
          'Lỗi xử lý email sau khi lưu công việc:',
          emailError.message
        );
      }
    }

    return res.json({
      message: 'Cập nhật công việc thành công',
      task,
      changes: danhSachThayDoi,

      emailSuccess: soEmailThanhCong,
      emailFailed: soEmailThatBai,

      justCompleted: vuaHoanThanh,
      completionEmailSuccess: soEmailD4ThanhCong,
      completionEmailFailed: soEmailD4ThatBai
    });
  } catch (error) {
    console.error(
      'Lỗi cập nhật công việc:',
      error.message
    );

    return res.status(500).json({
      message: 'Không thể cập nhật công việc'
    });
  }
});

// ========================================
// 18. XÓA CÔNG VIỆC
// ========================================
router.delete('/:id', xacThuc, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({
        message: 'ID công việc không hợp lệ'
      });
    }

    const task = await Task.findOneAndDelete({
      _id: req.params.id,
      createdBy: req.userId
    });

    if (!task) {
      return res.status(404).json({
        message:
          'Không tìm thấy công việc hoặc không có quyền xóa'
      });
    }

    return res.json({
      message: 'Xóa công việc thành công'
    });
  } catch (error) {
    console.error(
      'Lỗi xóa công việc:',
      error.message
    );

    return res.status(500).json({
      message: 'Không thể xóa công việc'
    });
  }
});

module.exports = router;
