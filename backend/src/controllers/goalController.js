const SavingGoal = require('../models/SavingGoal');

async function getGoal(req, res) {
  const data = await SavingGoal.findOne({ userId: req.user.userId });
  res.json(data);
}

async function saveGoal(req, res) {
  const data = await SavingGoal.findOneAndUpdate({ userId: req.user.userId }, req.body, { new: true, upsert: true });
  res.json(data);
}

module.exports = { getGoal, saveGoal };
