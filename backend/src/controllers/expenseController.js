const Expense = require('../models/Expense');
const { getTodayUsage } = require('../services/limitService');
const { ERROR_CODES } = require('../constants/errorCodes');
const { sendSuccess, sendCreated } = require('../utils/apiResponse');
const { AppError } = require('../utils/appError');

async function listExpenses(req, res) {
  const data = await Expense.find({ userId: req.user.userId }).sort({ spentAt: -1 }).limit(100);
  return sendSuccess(res, { items: data }, '获取记账列表成功');
}

async function createExpense(req, res) {
  if (typeof req.body.amount !== 'number' || req.body.amount <= 0 || !req.body.category) {
    throw new AppError(400, ERROR_CODES.VALIDATION_FAILED, 'amount 和 category 必填且合法');
  }

  const payload = { ...req.body, userId: req.user.userId, spentAt: req.body.spentAt || new Date() };
  const expense = await Expense.create(payload);
  const usage = await getTodayUsage(req.user.userId);
  return sendCreated(res, { expense, usage }, '创建记账成功');
}

async function updateExpense(req, res) {
  const expense = await Expense.findOneAndUpdate({ _id: req.params.id, userId: req.user.userId }, req.body, { new: true });
  if (!expense) {
    throw new AppError(404, ERROR_CODES.RESOURCE_NOT_FOUND, '记账记录不存在');
  }
  return sendSuccess(res, { expense }, '更新记账成功');
}

async function deleteExpense(req, res) {
  const deleted = await Expense.findOneAndDelete({ _id: req.params.id, userId: req.user.userId });
  if (!deleted) {
    throw new AppError(404, ERROR_CODES.RESOURCE_NOT_FOUND, '记账记录不存在');
  }
  return sendSuccess(res, null, '删除记账成功');
}

module.exports = { listExpenses, createExpense, updateExpense, deleteExpense };
