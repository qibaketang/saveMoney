const { randomUUID } = require('crypto');

function requestContext(req, res, next) {
  const requestId = req.headers['x-request-id'] || randomUUID();
  res.locals.requestId = requestId;
  res.setHeader('x-request-id', requestId);
  next();
}

module.exports = { requestContext };
