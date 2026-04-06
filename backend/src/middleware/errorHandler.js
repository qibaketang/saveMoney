const { ERROR_CODES } = require('../constants/errorCodes');
const { AppError } = require('../utils/appError');

function notFoundHandler(req, res, next) {
  next(new AppError(404, ERROR_CODES.RESOURCE_NOT_FOUND, `接口不存在: ${req.method} ${req.originalUrl}`));
}

function errorHandler(err, req, res, next) {
  const status = err.httpStatus || 500;
  const code = err.code || ERROR_CODES.INTERNAL_SERVER_ERROR;
  const message = err.message || '服务器内部错误';
  const details = err.details || null;

  if (status >= 500) {
    console.error(err);
  }

  res.status(status).json({
    code,
    message,
    details,
    requestId: res.locals.requestId,
    timestamp: new Date().toISOString()
  });
}

module.exports = { notFoundHandler, errorHandler };
