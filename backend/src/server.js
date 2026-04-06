require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const { connectDB } = require('./config/db');
const { requestContext } = require('./middleware/requestContext');
const { notFoundHandler, errorHandler } = require('./middleware/errorHandler');
const { sendSuccess } = require('./utils/apiResponse');

const app = express();
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));
app.use(requestContext);

app.get('/health', (_, res) => sendSuccess(res, { ok: true }, '服务健康'));
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/expenses', require('./routes/expenseRoutes'));
app.use('/api/limits', require('./routes/limitRoutes'));
app.use('/api/stats', require('./routes/statsRoutes'));
app.use('/api/goals', require('./routes/goalRoutes'));
app.use(notFoundHandler);
app.use(errorHandler);

const port = process.env.PORT || 3000;
connectDB().then(() => {
  app.listen(port, () => console.log(`API running on ${port}`));
}).catch((error) => {
  console.error(error);
  process.exit(1);
});
