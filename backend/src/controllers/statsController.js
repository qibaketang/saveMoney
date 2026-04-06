const mongoose = require('mongoose');
const Expense = require('../models/Expense');
const { ERROR_CODES } = require('../constants/errorCodes');
const { AppError } = require('../utils/appError');
const { sendSuccess } = require('../utils/apiResponse');

async function monthlyStats(req, res) {
  const now = new Date();
  const yearRaw = req.query.year;
  const monthRaw = req.query.month;

  const year = yearRaw == null ? now.getFullYear() : Number.parseInt(String(yearRaw), 10);
  const month = monthRaw == null ? now.getMonth() + 1 : Number.parseInt(String(monthRaw), 10);

  if (
    Number.isNaN(year) ||
    Number.isNaN(month) ||
    year < 2000 ||
    year > 2100 ||
    month < 1 ||
    month > 12
  ) {
    throw new AppError(400, ERROR_CODES.VALIDATION_FAILED, 'year/month 参数不合法');
  }

  const start = new Date(year, month - 1, 1);
  const end = new Date(year, month, 1);
  const userObjectId = new mongoose.Types.ObjectId(req.user.userId);

  const categoryStats = await Expense.aggregate([
    { $match: { userId: userObjectId, spentAt: { $gte: start, $lt: end } } },
    { $group: { _id: '$category', total: { $sum: '$amount' } } },
    { $sort: { total: -1 } }
  ]);

  const dailyTrend = await Expense.aggregate([
    { $match: { userId: userObjectId, spentAt: { $gte: start, $lt: end } } },
    { $group: { _id: { $dayOfMonth: '$spentAt' }, total: { $sum: '$amount' } } },
    { $sort: { '_id': 1 } }
  ]);

  return sendSuccess(
    res,
    {
      month: {
        year,
        month,
        start: start.toISOString(),
        end: end.toISOString()
      },
      categoryStats,
      dailyTrend
    },
    '获取月度统计成功'
  );
}

module.exports = { monthlyStats };
