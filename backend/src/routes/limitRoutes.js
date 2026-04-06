const router = require('express').Router();
const auth = require('../middleware/auth');
const controller = require('../controllers/limitController');
const { asyncHandler } = require('../middleware/asyncHandler');

router.use(auth);
router.get('/', asyncHandler(controller.getLimit));
router.put('/', asyncHandler(controller.upsertLimit));
module.exports = router;
