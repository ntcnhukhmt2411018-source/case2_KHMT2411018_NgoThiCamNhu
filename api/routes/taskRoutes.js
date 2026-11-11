
const express = require('express');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');

const Task = require('../models/Task');
const User = require('../models/User');
const Notification = require('../models/Notification');
const EmailLog = require('../models/EmailLog');
const TaskActivity = require('../models/TaskActivity');
const { guiEmail } = require('../services/emailService');

const router = express.Router();

// ========================================
// XÁC THỰC NGƯỜI DÙNG
// ========================================
function xacThuc(req, res, next) {
  const header = req.headers.authorization || '';

  if (!header.startsWith('Bearer ')) {
    return res.status(401).json({
      message: 'Vui lòng đăng nhập'
    });
  }

  try {
    const decoded = jwt.verify(
      header.substring(7),
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
// CÁC HÀM DÙNG CHUNG
// ========================================
function layTenNguoiDung(user) {
  return user?.fullName ||
    user?.name ||
    user?.email ||
    'Một người dùng';
}

function dinhDangNgayD3(ngay) {
  if (!ngay) return 'Chưa xác định';

  return new Date(ngay).toLocaleDateString('vi-VN', {
    timeZone: 'Asia/Ho_Chi_Minh'
  });
}

function layDanhSachNguoiLienQuan(task, nguoiThucHien) {
  const ids = [
    task.createdBy,
    task.assignedTo,
    ...(task.assignedUsers || []),
    ...(task.sharedWith || [])
  ];

  return [...new Set(
    ids.filter(Boolean).map(id => String(id))
  )].filter(id => id !== String(nguoiThucHien));
}

function trongDanhSach(list, userId) {
  return (list || []).some(
    item => String(item?._id || item) === String(userId)
  );
}

function coQuyenXem(task, userId) {
  return (
    String(task.createdBy?._id || task.createdBy) ===
      String(userId) ||
    String(task.assignedTo?._id || task.assignedTo) ===
      String(userId) ||
    trongDanhSach(task.assignedUsers, userId) ||
    trongDanhSach(task.sharedWith, userId)
  );
}

async function populateTask(task) {
  await task.populate([
    { path: 'createdBy', select: 'fullName name email' },
    { path: 'assignedTo', select: 'fullName name email' },
    { path: 'assignedUsers', select: 'fullName name email' },
    { path: 'sharedWith', select: 'fullName name email' },
    {
      path: 'sharePermissions.user',
      select: 'fullName name email'
    }
  ]);

  return task;
}

// ========================================
// E.4 - LƯU LỊCH SỬ HOẠT ĐỘNG
// ========================================
async function luuLichSuCongViec(
  taskId,
  userId,
  action,
  description
) {
  try {
    await TaskActivity.create({
      task: taskId,
      user: userId,
      action,
      description
    });

    console.log('E.4 - Đã lưu lịch sử:', action);
    return true;
  } catch (error) {
    console.error(
      'E.4 - Lỗi lưu lịch sử:',
      error.message
    );
    return false;
  }
}

// ========================================
// D.6 - GỬI EMAIL VÀ LƯU EMAILLOG
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
    thanhCong = (
      await guiEmail(user.email, tieuDe, noiDung)
    ) === true;

    if (!thanhCong) {
      thongBaoLoi = 'Gửi email thất bại';
    }
  } catch (error) {
    thongBaoLoi = error.message;
    console.error('Lỗi gửi email:', error.message);
  }

  try {
    await EmailLog.create({
      task: task._id,
      recipient: user._id,
      email: user.email,
      type,
      dueDate: task.dueDate,
      subject: tieuDe,
      content: noiDung,
      status: thanhCong ? 'success' : 'failed',
      sentAt: thanhCong ? new Date() : null,
      errorMessage: thongBaoLoi
    });
  } catch (error) {
    console.error(
      'Lỗi lưu lịch sử email:',
      error.message
    );
  }

  return thanhCong;
}

// ========================================
// D.1 - EMAIL GIAO CÔNG VIỆC
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
    console.error('Lỗi email giao việc:', error.message);
    return false;
  }
}

// ========================================
// D.2 - EMAIL MỜI CHIA SẺ
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
    console.error('Lỗi email chia sẻ:', error.message);
    return false;
  }
}

// ========================================
// D.3 - EMAIL KHI THÔNG TIN THAY ĐỔI
// ========================================
async function guiEmailThayDoiCongViec(
  task,
  user,
  nguoiSua,
  danhSachThayDoi
) {
  try {
    if (!user?.email || danhSachThayDoi.length === 0) {
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
    console.error('Lỗi email cập nhật:', error.message);
    return false;
  }
}

// ========================================
// D.4 - EMAIL KHI HOÀN THÀNH
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

    console.log(
      ketQua
        ? `D.4 - Đã gửi email tới ${user.email}`
        : `D.4 - Gửi email thất bại: ${user.email}`
    );

    return ketQua;
  } catch (error) {
    console.error('Lỗi email hoàn thành:', error.message);
    return false;
  }
}

// ========================================
// D.7 - TẠO THÔNG BÁO MONGODB
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

    return true;
  } catch (error) {
    console.error('Lỗi tạo thông báo:', error.message);
    return false;
  }
}

// ========================================
// TÌM NGƯỜI DÙNG THEO EMAIL
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
// TẠO CÔNG VIỆC
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

    if (typeof title !== 'string' || !title.trim()) {
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

    // E.4 - Ghi lịch sử tạo công việc
    await luuLichSuCongViec(
      task._id,
      req.userId,
      'created',
      'Đã tạo công việc'
    );

    return res.status(201).json({
      message: 'Tạo công việc thành công',
      task
    });
  } catch (error) {
    console.error('Lỗi tạo công việc:', error.message);

    return res.status(500).json({
      message: 'Không thể tạo công việc'
    });
  }
});

// ========================================
// LẤY DANH SÁCH CÔNG VIỆC
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
    console.error('Lỗi lấy công việc:', error.message);

    return res.status(500).json({
      message: 'Không thể lấy danh sách công việc'
    });
  }
});

// ========================================
// E.4 - XEM LỊCH SỬ HOẠT ĐỘNG CÔNG VIỆC
// ========================================
router.get('/:id/activities', xacThuc, async (req, res) => {
  try {
    const taskId = req.params.id;

    if (!mongoose.isValidObjectId(taskId)) {
      return res.status(400).json({
        message: 'ID công việc không hợp lệ'
      });
    }

    const task = await Task.findById(taskId);

    if (!task) {
      return res.status(404).json({
        message: 'Không tìm thấy công việc'
      });
    }

    if (!coQuyenXem(task, req.userId)) {
      return res.status(403).json({
        message: 'Bạn không có quyền xem lịch sử'
      });
    }

    const activities = await TaskActivity.find({
      task: taskId
    })
      .populate('user', 'fullName name email')
      .sort({ createdAt: -1, _id: -1 });

    return res.json({ activities });
  } catch (error) {
    console.error('Lỗi lấy lịch sử:', error.message);

    return res.status(500).json({
      message: 'Không thể lấy lịch sử công việc'
    });
  }
});

// ========================================
// GIAO CÔNG VIỆC CHO MỘT NGƯỜI
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
        message: 'Không tìm thấy công việc hoặc không có quyền giao'
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

    const nguoiPhuTrachCu = String(task.assignedTo);

    const daDuocGiao =
      danhSachCu.includes(String(user._id)) ||
      nguoiPhuTrachCu === String(user._id);

    task.assignedTo = user._id;

    if (!danhSachCu.includes(String(user._id))) {
      task.assignedUsers.push(user._id);
    }

    await task.save();

    // E.4
    if (
      !daDuocGiao ||
      nguoiPhuTrachCu !== String(user._id)
    ) {
      await luuLichSuCongViec(
        task._id,
        req.userId,
        'assigned',
        `Đã giao công việc cho ${layTenNguoiDung(user)}`
      );
    }

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
    console.error('Lỗi giao công việc:', error.message);

    return res.status(500).json({
      message: 'Không thể giao công việc'
    });
  }
});

// ========================================
// GIAO CÔNG VIỆC CHO NHIỀU NGƯỜI
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
      const primaryCu = String(task.assignedTo);

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
            message: 'Người phụ trách chính không tồn tại'
          });
        }

        task.assignedTo = primaryUser._id;
      }

      task.assignedUsers = allIds;
      await task.save();

      // E.4 - Ghi lịch sử khi danh sách thay đổi
      const idsMoi = allIds.filter(
        id => !danhSachCu.has(String(id))
      );

      if (
        idsMoi.length > 0 ||
        primaryCu !== String(task.assignedTo)
      ) {
        const tenNguoiMoi = users
          .filter(user =>
            idsMoi.includes(String(user._id))
          )
          .map(user => layTenNguoiDung(user));

        let moTa = tenNguoiMoi.length > 0
          ? `Đã giao thêm cho: ${tenNguoiMoi.join(', ')}`
          : 'Đã thay đổi người phụ trách chính';

        if (primaryCu !== String(task.assignedTo)) {
          moTa += '; Đã cập nhật người phụ trách chính';
        }

        await luuLichSuCongViec(
          task._id,
          req.userId,
          'assigned',
          moTa
        );
      }

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

      await populateTask(task);

      return res.json({
        message: 'Giao công việc cho nhiều người thành công',
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
        message: 'Không thể giao công việc cho nhiều người'
      });
    }
  }
);

// ========================================
// CHIA SẺ CÔNG VIỆC
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

    if (trongDanhSach(task.sharedWith, userId)) {
      return res.status(400).json({
        message: 'Công việc đã được chia sẻ cho người này'
      });
    }

    task.sharedWith.push(user._id);

    task.sharePermissions.push({
      user: user._id,
      role
    });

    await task.save();

    // E.4
    await luuLichSuCongViec(
      task._id,
      req.userId,
      'shared',
      `Đã chia sẻ cho ${layTenNguoiDung(user)} ` +
      `với quyền ${role}`
    );

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

    await populateTask(task);

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
    console.error('Lỗi chia sẻ:', error.message);

    return res.status(500).json({
      message: 'Không thể chia sẻ công việc'
    });
  }
});

// ========================================
// THAY ĐỔI QUYỀN CHIA SẺ
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

      if (!trongDanhSach(task.sharedWith, userId)) {
        return res.status(404).json({
          message: 'Người này chưa được chia sẻ công việc'
        });
      }

      const permission = (
        task.sharePermissions || []
      ).find(
        item => String(item.user) === String(userId)
      );

      const quyenCu = permission?.role || 'viewer';

      if (permission) {
        permission.role = role;
      } else {
        task.sharePermissions.push({
          user: userId,
          role
        });
      }

      await task.save();

      // E.4
      if (quyenCu !== role) {
        const user = await User.findById(userId);

        await luuLichSuCongViec(
          task._id,
          req.userId,
          'permission_changed',
          `Đã đổi quyền của ${layTenNguoiDung(user)} ` +
          `từ ${quyenCu} sang ${role}`
        );
      }

      await populateTask(task);

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
// THU HỒI QUYỀN CHIA SẺ
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

      if (!trongDanhSach(task.sharedWith, userId)) {
        return res.status(404).json({
          message: 'Người này chưa được chia sẻ công việc'
        });
      }

      const user = await User.findById(userId);

      task.sharedWith = task.sharedWith.filter(
        item => String(item) !== String(userId)
      );

      task.sharePermissions =
        task.sharePermissions.filter(
          item => String(item.user) !== String(userId)
        );

      await task.save();

      // E.4
      await luuLichSuCongViec(
        task._id,
        req.userId,
        'share_revoked',
        `Đã thu hồi quyền chia sẻ của ${layTenNguoiDung(user)}`
      );

      await populateTask(task);

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
// CHỈNH SỬA CÔNG VIỆC
// D.3 + D.4 + D.6 + E.4
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
      trongDanhSach(task.sharedWith, req.userId);

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

    if (typeof title !== 'string' || !title.trim()) {
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
        message: 'Hạn hoàn thành phải sau ngày bắt đầu'
      });
    }

    const trangThaiCu = task.status;

    const vuaHoanThanh =
      trangThaiCu !== 'Đã hoàn thành' &&
      status === 'Đã hoàn thành';

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

    task.title = title.trim();
    task.description = description || '';
    task.priority = priority;
    task.status = status;
    task.startDate = start;
    task.dueDate = due;

    await task.save();

    // ====================================
    // E.4 - GHI LỊCH SỬ CHỈNH SỬA
    // ====================================
    if (danhSachThayDoi.length > 0) {
      await luuLichSuCongViec(
        task._id,
        req.userId,
        'updated',
        danhSachThayDoi.join('; ')
      );
    }

    if (trangThaiCu !== status) {
      await luuLichSuCongViec(
        task._id,
        req.userId,
        'status_changed',
        `Đã đổi trạng thái từ "${trangThaiCu}" sang "${status}"`
      );
    }

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
// XÓA CÔNG VIỆC
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

    // Xóa lịch sử gắn với công việc đã xóa.
    // Công việc đã xóa không còn xem được qua API E.4.
    try {
      await TaskActivity.deleteMany({
        task: task._id
      });
    } catch (error) {
      console.error(
        'Lỗi dọn lịch sử công việc:',
        error.message
      );
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
