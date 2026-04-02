const Expense = require('../models/Expense');
const { getTodayUsage } = require('../services/limitService');

async function listExpenses(req, res) {
  const data = await Expense.find({ userId: req.user.userId }).sort({ spentAt: -1 }).limit(100);
  res.json(data);
}

async function createExpense(req, res) {
  const payload = { ...req.body, userId: req.user.userId, spentAt: req.body.spentAt || new Date() };
  const expense = await Expense.create(payload);
  const usage = await getTodayUsage(req.user.userId);
  res.status(201).json({ expense, usage });
}

async function updateExpense(req, res) {
  const expense = await Expense.findOneAndUpdate({ _id: req.params.id, userId: req.user.userId }, req.body, { new: true });
  res.json(expense);
}

async function deleteExpense(req, res) {
  await Expense.findOneAndDelete({ _id: req.params.id, userId: req.user.userId });
  res.status(204).send();
}

module.exports = { listExpenses, createExpense, updateExpense, deleteExpense };
