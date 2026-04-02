const jwt = require('jsonwebtoken');
const User = require('../models/User');

async function login(req, res) {
  const { phone } = req.body;
  let user = await User.findOne({ phone });
  if (!user) user = await User.create({ phone, nickname: `用户${phone.slice(-4)}` });
  const token = jwt.sign({ userId: user._id, phone: user.phone }, process.env.JWT_SECRET, { expiresIn: '7d' });
  res.json({ token, user });
}

module.exports = { login };
