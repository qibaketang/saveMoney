require('dotenv').config();
const { connectDB } = require('../src/config/db');
const User = require('../src/models/User');
const Limit = require('../src/models/Limit');
const Expense = require('../src/models/Expense');

(async function seed() {
  await connectDB();
  const user = await User.findOneAndUpdate(
    { phone: '13800008888' },
    { phone: '13800008888', nickname: '演示用户' },
    { upsert: true, new: true }
  );
  await Limit.findOneAndUpdate(
    { userId: user._id },
    { userId: user._id, dailyLimit: 250, monthlyLimit: 7500, categories: [{ name: '餐饮', amount: 100 }, { name: '交通', amount: 50 }] },
    { upsert: true }
  );
  await Expense.deleteMany({ userId: user._id });
  await Expense.insertMany([
    { userId: user._id, amount: 12, category: '早餐', note: '豆浆油条', spentAt: new Date() },
    { userId: user._id, amount: 28, category: '咖啡', note: '拿铁', spentAt: new Date() },
    { userId: user._id, amount: 5, category: '交通', note: '地铁', spentAt: new Date() }
  ]);
  console.log('Seed done');
  process.exit(0);
})();
