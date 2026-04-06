const router = require('express').Router();
const auth = require('../middleware/auth');
const controller = require('../controllers/expenseController');
const { asyncHandler } = require('../middleware/asyncHandler');

router.use(auth);
router.get('/', asyncHandler(controller.listExpenses));
router.post('/', asyncHandler(controller.createExpense));
router.put('/:id', asyncHandler(controller.updateExpense));
router.delete('/:id', asyncHandler(controller.deleteExpense));
module.exports = router;
