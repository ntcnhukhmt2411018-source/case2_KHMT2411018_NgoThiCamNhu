
const mongoose = require('mongoose');

// ========================================
// LƯU LỊCH SỬ GỬI EMAIL
// ========================================

const emailLogSchema = new mongoose.Schema(
  {
    // Công việc liên quan
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

    // Địa chỉ email người nhận
    email: {
      type: String,
      required: true,
      trim: true,
      lowercase: true
    },

    // Loại email
    // task_assigned: Giao công việc
    // task_shared: Mời chia sẻ công việc
    // task_updated: Cập nhật công việc
    // task_completed: Hoàn thành công việc
    // deadline_reminder: Nhắc việc trước hạn
    type: {
      type: String,
      enum: [
        'task_assigned',
        'task_shared',
        'task_updated',
        'task_completed',
        'deadline_reminder'
      ],
      default: 'deadline_reminder'
    },

    // Hạn hoàn thành công việc
    dueDate: {
      type: Date,
      required: true
    },

    // Tiêu đề email
    subject: {
      type: String,
      default: ''
    },

    // Nội dung email
    content: {
      type: String,
      default: ''
    },

    // Trạng thái gửi email
    status: {
      type: String,
      enum: [
        'pending',
        'success',
        'failed'
      ],
      default: 'pending'
    },

    // Thời gian gửi thành công
    sentAt: {
      type: Date,
      default: null
    },

    // Thông báo lỗi nếu gửi thất bại
    errorMessage: {
      type: String,
      default: ''
    }
  },
  {
    timestamps: true
  }
);

// ========================================
// CHỐNG GỬI TRÙNG EMAIL NHẮC HẠN D.5
// ========================================

// Chỉ áp dụng unique cho deadline_reminder
// Các email D.1 - D.4 có thể lưu nhiều lần

emailLogSchema.index(
  {
    task: 1,
    recipient: 1,
    type: 1,
    dueDate: 1
  },
  {
    unique: true,
    partialFilterExpression: {
      type: 'deadline_reminder'
    }
  }
);

// ========================================
// INDEX HỖ TRỢ TRA CỨU LỊCH SỬ
// ========================================

// Tìm lịch sử theo công việc
emailLogSchema.index({
  task: 1,
  createdAt: -1
});

// Tìm lịch sử theo người nhận
emailLogSchema.index({
  recipient: 1,
  createdAt: -1
});

// Tìm lịch sử theo trạng thái
emailLogSchema.index({
  status: 1,
  createdAt: -1
});

// ========================================
// KHỞI TẠO MODEL
// ========================================

// Tránh lỗi OverwriteModelError
const EmailLog =
  mongoose.models.EmailLog ||
  mongoose.model('EmailLog', emailLogSchema);

// Xuất model để các file khác sử dụng
module.exports = EmailLog;
