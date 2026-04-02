const router = require('express').Router();
const auth = require('../middleware/auth');
const controller = require('../controllers/limitController');
router.use(auth);
router.get('/', controller.getLimit);
router.put('/', controller.upsertLimit);
module.exports = router;
