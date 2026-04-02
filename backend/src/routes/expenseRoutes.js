const router = require('express').Router();
const auth = require('../middleware/auth');
const controller = require('../controllers/expenseController');
router.use(auth);
router.get('/', controller.listExpenses);
router.post('/', controller.createExpense);
router.put('/:id', controller.updateExpense);
router.delete('/:id', controller.deleteExpense);
module.exports = router;
