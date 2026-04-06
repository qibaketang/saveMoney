const router = require('express').Router();
const { login } = require('../controllers/authController');
const { asyncHandler } = require('../middleware/asyncHandler');

router.post('/login', asyncHandler(login));
module.exports = router;
