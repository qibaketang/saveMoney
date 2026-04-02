const Redis = require('ioredis');

let redis = null;
function getRedis() {
  if (!process.env.REDIS_URL) return null;
  if (!redis) redis = new Redis(process.env.REDIS_URL, { lazyConnect: true });
  return redis;
}

module.exports = { getRedis };
