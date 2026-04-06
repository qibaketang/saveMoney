const SavingGoal = require('../models/SavingGoal');
const { sendSuccess } = require('../utils/apiResponse');

async function getGoal(req, res) {
  let data = await SavingGoal.findOne({ userId: req.user.userId });
  if (!data) {
    data = await SavingGoal.create({
      userId: req.user.userId,
      name: '旅行基金',
      targetAmount: 6000,
      savedAmount: 0,
      targetDate: new Date(Date.now() + 180 * 24 * 60 * 60 * 1000)
    });
  }
  return sendSuccess(res, { goal: data }, '获取储蓄目标成功');
}

async function saveGoal(req, res) {
  const data = await SavingGoal.findOneAndUpdate({ userId: req.user.userId }, req.body, { new: true, upsert: true });
  return sendSuccess(res, { goal: data }, '保存储蓄目标成功');
}

module.exports = { getGoal, saveGoal };
