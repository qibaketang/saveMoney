const mongoose = require('mongoose');

const expenseSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  amount: { type: Number, required: true },
  category: { type: String, required: true },
  note: { type: String, default: '' },
  tags: [{ type: String }],
  receiptUrl: String,
  location: String,
  spentAt: { type: Date, required: true }
}, { timestamps: true });

expenseSchema.index({ userId: 1, spentAt: -1 });

module.exports = mongoose.model('Expense', expenseSchema);
