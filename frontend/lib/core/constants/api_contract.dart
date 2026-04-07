class ApiEnvelopeKeys {
  static const code = 'code';
  static const message = 'message';
  static const data = 'data';
  static const requestId = 'requestId';
  static const timestamp = 'timestamp';
}

class ApiErrorCodes {
  static const authMissingToken = 'AUTH_MISSING_TOKEN';
  static const authInvalidToken = 'AUTH_INVALID_TOKEN';
  static const authInvalidPhone = 'AUTH_INVALID_PHONE';
  static const authInvalidPassword = 'AUTH_INVALID_PASSWORD';
  static const authInvalidVerifyCode = 'AUTH_INVALID_VERIFY_CODE';
  static const authPhoneExists = 'AUTH_PHONE_EXISTS';
  static const authUserNotFound = 'AUTH_USER_NOT_FOUND';
  static const authWrongPassword = 'AUTH_WRONG_PASSWORD';

  static const validationFailed = 'VALIDATION_FAILED';
  static const resourceNotFound = 'RESOURCE_NOT_FOUND';

  static const internalServerError = 'INTERNAL_SERVER_ERROR';
}
