function sendSuccess(res, data, message = 'OK') {
  return res.status(200).json({
    code: 0,
    message,
    data,
    requestId: res.locals.requestId,
    timestamp: new Date().toISOString()
  });
}

function sendCreated(res, data, message = 'Created') {
  return res.status(201).json({
    code: 0,
    message,
    data,
    requestId: res.locals.requestId,
    timestamp: new Date().toISOString()
  });
}

module.exports = { sendSuccess, sendCreated };
