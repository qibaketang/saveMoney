const router = require('express').Router();
const auth = require('../middleware/auth');
const { monthlyStats } = require('../controllers/statsController');
router.use(auth);
router.get('/monthly', monthlyStats);
module.exports = router;
