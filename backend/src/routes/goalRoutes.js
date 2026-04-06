const router = require('express').Router();
const auth = require('../middleware/auth');
const controller = require('../controllers/goalController');
const { asyncHandler } = require('../middleware/asyncHandler');

router.use(auth);
router.get('/', asyncHandler(controller.getGoal));
router.put('/', asyncHandler(controller.saveGoal));
module.exports = router;
