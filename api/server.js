
require('dotenv').config();

const express = require('express');
const mongoose = require('mongoose');

// ==========================================
// 1. PHẦN A: QUẢN LÝ TÀI KHOẢN VÀ XÁC THỰC
// ==========================================
const authRoutes = require('./routes/authRoutes');

// ==========================================
// 2. PHẦN B, C: QUẢN LÝ CÔNG VIỆC
// ==========================================
const taskRoutes = require('./routes/taskRoutes');

// ==========================================
// 3. PHẦN D: THÔNG BÁO TRONG ỨNG DỤNG
// ==========================================
const notificationRoutes = require('./routes/notificationRoutes');

// ==========================================
// 4. KHỞI TẠO EXPRESS
// ==========================================
const app = express();

// Cho phép nhận dữ liệu JSON từ Flutter
app.use(express.json());

// ==========================================
// 5. API PHẦN A
// ==========================================
// Đăng ký, đăng nhập, thông tin cá nhân, đổi mật khẩu
app.use('/api/auth', authRoutes);

// ==========================================
// 6. API PHẦN B, C
// ==========================================
// Tạo, sửa, xóa, giao và chia sẻ công việc
app.use('/api/tasks', taskRoutes);

// ==========================================
// 7. API PHẦN D - THÔNG BÁO
// ==========================================
// Lấy danh sách thông báo
// Đếm thông báo chưa đọc
// Đánh dấu thông báo đã đọc
app.use('/api/notifications', notificationRoutes);

// ==========================================
// 8. CỔNG CHẠY SERVER
// ==========================================
const PORT = process.env.PORT || 3000;

// ==========================================
// 9. KIỂM TRA SERVER
// ==========================================
app.get('/', (req, res) => {
  res.send('Node.js API dang hoat dong!');
});

// ==========================================
// 10. KẾT NỐI MONGODB VÀ KHỞI ĐỘNG SERVER
// ==========================================
async function startServer() {
  try {
    // Kết nối MongoDB
    await mongoose.connect(process.env.MONGODB_URI);

    console.log('Da ket noi MongoDB thanh cong!');

    // Khởi động Node.js
    app.listen(PORT, () => {
      console.log(
        `Server dang chay tai http://localhost:${PORT}`
      );
    });
  } catch (error) {
    console.error(
      'Loi ket noi MongoDB:',
      error.message
    );
  }
}

startServer();
