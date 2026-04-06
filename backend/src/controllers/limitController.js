const Limit = require('../models/Limit');
const { getTodayUsage } = require('../services/limitService');
const { sendSuccess } = require('../utils/apiResponse');

async function getLimit(req, res) {
  let data = await Limit.findOne({ userId: req.user.userId });
  if (!data) data = await Limit.create({ userId: req.user.userId });
  const usage = await getTodayUsage(req.user.userId);
  return sendSuccess(res, { limit: data, usage }, '获取限额配置成功');
}

async function upsertLimit(req, res) {
  const data = await Limit.findOneAndUpdate(
    { userId: req.user.userId },
    { ...req.body, monthlyLimit: (req.body.dailyLimit || 250) * 30 },
    { new: true, upsert: true }
  );
  return sendSuccess(res, { limit: data }, '保存限额配置成功');
}

module.exports = { getLimit, upsertLimit };
