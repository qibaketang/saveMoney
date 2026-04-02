const mongoose = require('mongoose');

const savingGoalSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  name: { type: String, required: true },
  targetAmount: { type: Number, required: true },
  savedAmount: { type: Number, default: 0 },
  targetDate: { type: Date, required: true }
}, { timestamps: true });

module.exports = mongoose.model('SavingGoal', savingGoalSchema);
