
const mongoose = require('mongoose');

// Schema lưu lịch sử gửi email nhắc hạn
const emailLogSchema = new mongoose.Schema(
  {
    // Công việc được nhắc hạn
    task: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Task',
      required: true
    },

    // Người nhận email
    recipient: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },

    // Địa chỉ email nhận thông báo
    email: {
      type: String,
      required: true,
      trim: true,
      lowercase: true
    },

    // Loại email
    type: {
      type: String,
      default: 'deadline_reminder'
    },

    // Hạn hoàn thành công việc
    dueDate: {
      type: Date,
      required: true
    },

    // Trạng thái gửi email
    status: {
      type: String,
      enum: ['pending', 'success', 'failed'],
      default: 'pending'
    },

    // Thời gian gửi email thành công
    sentAt: {
      type: Date,
      default: null
    },

    // Lưu thông báo lỗi nếu gửi thất bại
    errorMessage: {
      type: String,
      default: ''
    }
  },
  {
    timestamps: true
  }
);

// Tránh gửi email nhắc hạn trùng
// cho cùng một công việc, người nhận và hạn hoàn thành
emailLogSchema.index(
  {
    task: 1,
    recipient: 1,
    type: 1,
    dueDate: 1
  },
  {
    unique: true
  }
);

// Lấy model đã tồn tại hoặc tạo model mới
const EmailLog =
  mongoose.models.EmailLog ||
  mongoose.model('EmailLog', emailLogSchema);

// Xuất trực tiếp model để server.js sử dụng
module.exports = EmailLog;
