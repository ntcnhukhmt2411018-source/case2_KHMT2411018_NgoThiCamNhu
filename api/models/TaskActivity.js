
const mongoose = require('mongoose');

const taskActivitySchema = new mongoose.Schema(
  {
    task: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Task',
      required: true,
      index: true,
    },

    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },

    action: {
      type: String,
      required: true,
      enum: [
        'created',
        'updated',
        'status_changed',
        'assigned',
        'shared',
        'permission_changed',
        'share_revoked',
      ],
    },

    description: {
      type: String,
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

taskActivitySchema.index({
  task: 1,
  createdAt: -1,
});

module.exports = mongoose.model(
  'TaskActivity',
  taskActivitySchema
);
