
const mongoose = require('mongoose');

// 1. Tạo cấu trúc dữ liệu công việc
const taskSchema = new mongoose.Schema(
  {
    // Tên công việc
    title: {
      type: String,
      required: true,
      trim: true,
    },

    // Mô tả công việc
    description: {
      type: String,
      default: '',
    },

    // Người tạo công việc
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },

    // Người phụ trách chính
    assignedTo: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },

    // DANH SÁCH NGƯỜI ĐƯỢC GIAO CÔNG VIỆC (MỚI)
    assignedUsers: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],

    // Mức độ ưu tiên
    priority: {
      type: String,
      enum: ['Thấp', 'Trung bình', 'Cao'],
      default: 'Trung bình',
    },

    // Trạng thái công việc
    status: {
      type: String,
      enum: [
        'Chưa thực hiện',
        'Đang thực hiện',
        'Đã hoàn thành',
      ],
      default: 'Chưa thực hiện',
    },

    // Ngày bắt đầu
    startDate: {
      type: Date,
      required: true,
    },

    // Hạn hoàn thành
    dueDate: {
      type: Date,
      required: true,
    },

    // Danh sách người được chia sẻ công việc
    sharedWith: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],
  },
  {
    // Tự động lưu thời gian tạo và cập nhật
    timestamps: true,
  }
);

// 2. Tạo model Task để lưu vào MongoDB
module.exports = mongoose.model('Task', taskSchema);
