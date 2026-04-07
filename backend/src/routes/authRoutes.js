const router = require('express').Router();
const { sendVerifyCode, login, registerByCode, loginByPassword } = require('../controllers/authController');
const { asyncHandler } = require('../middleware/asyncHandler');

router.post('/send-code', asyncHandler(sendVerifyCode));
router.post('/login', asyncHandler(login));
router.post('/register', asyncHandler(registerByCode));
router.post('/login/password', asyncHandler(loginByPassword));
module.exports = router;
