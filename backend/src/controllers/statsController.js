const Expense = require('../models/Expense');

async function monthlyStats(req, res) {
  const now = new Date();
  const start = new Date(now.getFullYear(), now.getMonth(), 1);
  const end = new Date(now.getFullYear(), now.getMonth() + 1, 1);

  const categoryStats = await Expense.aggregate([
    { $match: { userId: req.user.userId, spentAt: { $gte: start, $lt: end } } },
    { $group: { _id: '$category', total: { $sum: '$amount' } } },
    { $sort: { total: -1 } }
  ]);

  const dailyTrend = await Expense.aggregate([
    { $match: { userId: req.user.userId, spentAt: { $gte: start, $lt: end } } },
    { $group: { _id: { $dayOfMonth: '$spentAt' }, total: { $sum: '$amount' } } },
    { $sort: { '_id': 1 } }
  ]);

  res.json({ categoryStats, dailyTrend });
}

module.exports = { monthlyStats };
