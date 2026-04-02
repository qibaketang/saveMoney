const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  phone: { type: String, required: true, unique: true },
  passwordHash: { type: String },
  nickname: { type: String, default: '新用户' },
  avatarUrl: String,
  notificationSettings: {
    limitAlert: { type: Boolean, default: true },
    overLimitAlert: { type: Boolean, default: true },
    pushEnabled: { type: Boolean, default: true },
    smsEnabled: { type: Boolean, default: false }
  }
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
