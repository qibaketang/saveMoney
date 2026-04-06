const router = require('express').Router();
const auth = require('../middleware/auth');
const { monthlyStats } = require('../controllers/statsController');
const { asyncHandler } = require('../middleware/asyncHandler');

router.use(auth);
router.get('/monthly', asyncHandler(monthlyStats));
module.exports = router;
