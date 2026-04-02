const Limit = require('../models/Limit');
const { getTodayUsage } = require('../services/limitService');

async function getLimit(req, res) {
  let data = await Limit.findOne({ userId: req.user.userId });
  if (!data) data = await Limit.create({ userId: req.user.userId });
  const usage = await getTodayUsage(req.user.userId);
  res.json({ ...data.toObject(), usage });
}

async function upsertLimit(req, res) {
  const data = await Limit.findOneAndUpdate(
    { userId: req.user.userId },
    { ...req.body, monthlyLimit: (req.body.dailyLimit || 250) * 30 },
    { new: true, upsert: true }
  );
  res.json(data);
}

module.exports = { getLimit, upsertLimit };
