
require('dotenv').config();

const express = require('express');
const mongoose = require('mongoose');
const cron = require('node-cron');

// ========================================
// 1. IMPORT ROUTES
// ========================================

const authRoutes = require('./routes/authRoutes');
const taskRoutes = require('./routes/taskRoutes');
const notificationRoutes = require('./routes/notificationRoutes');

// ========================================
// 2. IMPORT MODELS VÀ EMAIL SERVICE
// ========================================

// Dùng model Task đã đăng ký nếu có
const Task = mongoose.models.Task || require('./models/task');

const User = require('./models/User');
const EmailLog = require('./models/EmailLog');

const { guiEmail } = require('./services/emailService');

// ========================================
// 3. CẤU HÌNH SERVER
// ========================================

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// Giữ nguyên các API
app.use('/api/auth', authRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/notifications', notificationRoutes);

// Kiểm tra server
app.get('/', (req, res) => {
  res.send('Node.js API dang hoat dong!');
});

// ========================================
// 4. TỰ ĐỘNG NHẮC VIỆC TRƯỚC HẠN 24 GIỜ
// ========================================

let dangKiemTra = false;

async function kiemTraCongViecSapHetHan() {
  if (dangKiemTra) return;

  dangKiemTra = true;

  try {
    console.log('Dang kiem tra cong viec sap het han...');

    const hienTai = new Date();

    const sau24Gio = new Date(
      hienTai.getTime() + 24 * 60 * 60 * 1000
    );

    // Tìm công việc chưa hoàn thành,
    // sắp hết hạn trong 24 giờ tới
    const danhSachCongViec = await Task.find({
      dueDate: {
        $gt: hienTai,
        $lte: sau24Gio,
      },
      status: {
        $ne: 'Đã hoàn thành',
      },
    });

    console.log(
      'So cong viec sap het han:',
      danhSachCongViec.length
    );

    for (const congViec of danhSachCongViec) {
      // Lấy danh sách người được giao
      const danhSachId = [
        congViec.assignedTo,
        ...(congViec.assignedUsers || []),
      ];

      // Loại bỏ ID trùng
      const idKhongTrung = [
        ...new Set(
          danhSachId
            .filter(Boolean)
            .map(id => id.toString())
        ),
      ];

      const danhSachNguoiDung = await User.find({
        _id: {
          $in: idKhongTrung,
        },
      });

      for (const nguoi of danhSachNguoiDung) {
        if (!nguoi.email) continue;

        // Kiểm tra email đã gửi thành công chưa
        const daGui = await EmailLog.findOne({
          task: congViec._id,
          recipient: nguoi._id,
          type: 'deadline_reminder',
          dueDate: congViec.dueDate,
          status: 'success',
        });

        if (daGui) {
          console.log(
            'Email da gui truoc do:',
            nguoi.email
          );
          continue;
        }

        // Định dạng ngày hết hạn
        const ngayHetHan = new Date(
          congViec.dueDate
        ).toLocaleString('vi-VN', {
          timeZone: 'Asia/Ho_Chi_Minh',
        });

        // Tiêu đề email
        const tieuDe =
          'TaskManager - Nhắc nhở công việc sắp hết hạn';

        // Nội dung email
        const noiDung = `
Xin chào ${nguoi.fullName || 'bạn'}!

Công việc của bạn sắp đến hạn hoàn thành.

THÔNG TIN CÔNG VIỆC

Tên công việc: ${congViec.title}
Hạn hoàn thành: ${ngayHetHan}
Mức độ ưu tiên: ${congViec.priority}
Trạng thái: ${congViec.status}

Công việc này sẽ hết hạn trong vòng 24 giờ tới.

Vui lòng đăng nhập ứng dụng TaskManager
để kiểm tra và hoàn thành công việc đúng hạn.

Trân trọng,
TaskManager
`;

        // Gửi email
        const thanhCong = await guiEmail(
          nguoi.email,
          tieuDe,
          noiDung
        );

        // Lưu lịch sử gửi email
        await EmailLog.findOneAndUpdate(
          {
            task: congViec._id,
            recipient: nguoi._id,
            type: 'deadline_reminder',
            dueDate: congViec.dueDate,
          },
          {
            $set: {
              email: nguoi.email,
              status: thanhCong
                ? 'success'
                : 'failed',
              sentAt: thanhCong
                ? new Date()
                : null,
              errorMessage: thanhCong
                ? ''
                : 'Gui email that bai',
            },
          },
          {
            upsert: true,
            new: true,
            runValidators: true,
          }
        );

        if (thanhCong) {
          console.log(
            'Da gui email nhac viec den:',
            nguoi.email
          );
        } else {
          console.log(
            'Gui email nhac viec that bai:',
            nguoi.email
          );
        }
      }
    }

    console.log('Hoan thanh kiem tra nhac viec.');

  } catch (error) {
    console.error(
      'Loi kiem tra nhac viec:',
      error.message
    );
  } finally {
    dangKiemTra = false;
  }
}

// ========================================
// 5. KHỞI ĐỘNG BACKEND
// ========================================

async function startServer() {
  try {
    if (!process.env.MONGODB_URI) {
      throw new Error(
        'Chua cau hinh MONGODB_URI trong .env'
      );
    }

    await mongoose.connect(process.env.MONGODB_URI);

    console.log('Da ket noi MongoDB thanh cong!');

    app.listen(PORT, '0.0.0.0', () => {
      console.log(
        `Server dang chay tai http://localhost:${PORT}`
      );

      // Kiểm tra ngay khi khởi động
      kiemTraCongViecSapHetHan();

      // Kiểm tra tự động mỗi 5 phút
      cron.schedule('*/5 * * * *', () => {
        kiemTraCongViecSapHetHan();
      });

      console.log(
        'Da kich hoat nhac viec tu dong moi 5 phut.'
      );
    });

  } catch (error) {
    console.error(
      'Loi khoi dong server:',
      error.message
    );
  }
}

// ========================================
// 6. CHẠY SERVER
// ========================================

startServer();
