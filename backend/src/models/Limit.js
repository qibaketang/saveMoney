const mongoose = require('mongoose');

const limitSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  dailyLimit: { type: Number, default: 250 },
  monthlyLimit: { type: Number, default: 7500 },
  categories: [{
    name: String,
    amount: Number,
    cycle: { type: String, enum: ['daily', 'monthly'], default: 'daily' },
    dailyLimit: { type: Number, default: 0 },
    monthlyLimit: { type: Number, default: 0 },
    warningThreshold: { type: Number, default: 80 },
    dangerThreshold: { type: Number, default: 100 }
  }]
}, { timestamps: true });

module.exports = mongoose.model('Limit', limitSchema);
