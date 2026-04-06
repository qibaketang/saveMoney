const jwt = require('jsonwebtoken');
const { ERROR_CODES } = require('../constants/errorCodes');
const { AppError } = require('../utils/appError');

function auth(req, res, next) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) {
    return next(new AppError(401, ERROR_CODES.AUTH_MISSING_TOKEN, '未登录，请先登录'));
  }

  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch (error) {
    return next(new AppError(401, ERROR_CODES.AUTH_INVALID_TOKEN, '登录已失效，请重新登录'));
  }
}

module.exports = auth;
