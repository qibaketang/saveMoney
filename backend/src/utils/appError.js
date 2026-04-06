class AppError extends Error {
  constructor(httpStatus, code, message, details = null) {
    super(message);
    this.httpStatus = httpStatus;
    this.code = code;
    this.details = details;
  }
}

module.exports = { AppError };
