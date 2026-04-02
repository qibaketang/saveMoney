const router = require('express').Router();
const auth = require('../middleware/auth');
const controller = require('../controllers/goalController');
router.use(auth);
router.get('/', controller.getGoal);
router.put('/', controller.saveGoal);
module.exports = router;
