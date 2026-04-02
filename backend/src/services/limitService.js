const Expense = require('../models/Expense');
const Limit = require('../models/Limit');
const { dayRange } = require('../utils/date');

async function getTodayUsage(userId) {
  const limit = await Limit.findOne({ userId });
  const { start, end } = dayRange();
  const expenses = await Expense.find({ userId, spentAt: { $gte: start, $lt: end } });
  const spent = expenses.reduce((sum, item) => sum + item.amount, 0);
  const dailyLimit = limit?.dailyLimit ?? 250;
  return {
    dailyLimit,
    spent,
    remaining: dailyLimit - spent,
    status: spent > dailyLimit ? 'over' : spent / dailyLimit >= 0.8 ? 'warning' : 'safe'
  };
}

module.exports = { getTodayUsage };
