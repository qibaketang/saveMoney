const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const { ERROR_CODES } = require('../constants/errorCodes');
const { sendSuccess } = require('../utils/apiResponse');
const { AppError } = require('../utils/appError');

const DEFAULT_VERIFY_CODE = process.env.DEFAULT_VERIFY_CODE || '123456';

function createToken(user) {
  return jwt.sign({ userId: user._id, phone: user.phone }, process.env.JWT_SECRET, { expiresIn: '7d' });
}

function validatePhone(phone) {
  return phone && /^1\d{10}$/.test(phone);
}

function validatePassword(password) {
  return typeof password === 'string' && password.length >= 6 && password.length <= 32;
}

async function sendVerifyCode(req, res) {
  const { phone } = req.body;

  if (!validatePhone(phone)) {
    throw new AppError(400, ERROR_CODES.AUTH_INVALID_PHONE, '手机号格式不正确');
  }

  const data = {
    phone,
    expireSeconds: 300,
    message: '短信验证码功能待接入，当前为演示验证码'
  };
  if (process.env.NODE_ENV !== 'production') {
    data.mockCode = DEFAULT_VERIFY_CODE;
  }

  return sendSuccess(res, data, '验证码已发送（演示）');
}

async function login(req, res) {
  const { phone } = req.body;

  if (!validatePhone(phone)) {
    throw new AppError(400, ERROR_CODES.AUTH_INVALID_PHONE, '手机号格式不正确');
  }

  let user = await User.findOne({ phone });
  if (!user) user = await User.create({ phone, nickname: `用户${phone.slice(-4)}` });
  const token = createToken(user);

  return sendSuccess(
    res,
    {
      accessToken: token,
      tokenType: 'Bearer',
      expiresIn: 604800,
      user
    },
    '登录成功'
  );
}

async function registerByCode(req, res) {
  const { phone, verifyCode, password, nickname } = req.body;

  if (!validatePhone(phone)) {
    throw new AppError(400, ERROR_CODES.AUTH_INVALID_PHONE, '手机号格式不正确');
  }
  if (!validatePassword(password)) {
    throw new AppError(400, ERROR_CODES.AUTH_INVALID_PASSWORD, '密码长度需为 6-32 位');
  }
  if (!verifyCode || verifyCode !== DEFAULT_VERIFY_CODE) {
    throw new AppError(400, ERROR_CODES.AUTH_INVALID_VERIFY_CODE, '验证码错误（演示环境默认 123456）');
  }

  const existingUser = await User.findOne({ phone });
  if (existingUser) {
    throw new AppError(409, ERROR_CODES.AUTH_PHONE_EXISTS, '该手机号已注册');
  }

  const passwordHash = await bcrypt.hash(password, 10);
  const user = await User.create({
    phone,
    passwordHash,
    nickname: nickname?.trim() || `用户${phone.slice(-4)}`
  });
  const token = createToken(user);

  return sendSuccess(
    res,
    {
      accessToken: token,
      tokenType: 'Bearer',
      expiresIn: 604800,
      user
    },
    '注册成功'
  );
}

async function loginByPassword(req, res) {
  const { phone, password } = req.body;

  if (!validatePhone(phone)) {
    throw new AppError(400, ERROR_CODES.AUTH_INVALID_PHONE, '手机号格式不正确');
  }
  if (!validatePassword(password)) {
    throw new AppError(400, ERROR_CODES.AUTH_INVALID_PASSWORD, '密码长度需为 6-32 位');
  }

  const user = await User.findOne({ phone });
  if (!user) {
    throw new AppError(404, ERROR_CODES.AUTH_USER_NOT_FOUND, '用户不存在，请先注册');
  }
  if (!user.passwordHash) {
    throw new AppError(400, ERROR_CODES.AUTH_INVALID_PASSWORD, '该账号未设置密码，请先完成注册');
  }

  const matched = await bcrypt.compare(password, user.passwordHash);
  if (!matched) {
    throw new AppError(401, ERROR_CODES.AUTH_WRONG_PASSWORD, '手机号或密码错误');
  }

  const token = createToken(user);
  return sendSuccess(
    res,
    {
      accessToken: token,
      tokenType: 'Bearer',
      expiresIn: 604800,
      user
    },
    '登录成功'
  );
}

module.exports = { sendVerifyCode, login, registerByCode, loginByPassword };
