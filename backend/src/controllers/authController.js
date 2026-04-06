const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { ERROR_CODES } = require('../constants/errorCodes');
const { sendSuccess } = require('../utils/apiResponse');
const { AppError } = require('../utils/appError');

async function login(req, res) {
  const { phone } = req.body;

  if (!phone || !/^1\d{10}$/.test(phone)) {
    throw new AppError(400, ERROR_CODES.AUTH_INVALID_PHONE, '手机号格式不正确');
  }

  let user = await User.findOne({ phone });
  if (!user) user = await User.create({ phone, nickname: `用户${phone.slice(-4)}` });
  const token = jwt.sign({ userId: user._id, phone: user.phone }, process.env.JWT_SECRET, { expiresIn: '7d' });
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

module.exports = { login };
