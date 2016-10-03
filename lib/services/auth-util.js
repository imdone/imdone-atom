var util   = require('util'),
    crypto = require('crypto'),
    url    = require('url');

function sha(data) {
  var shasum = crypto.createHash('sha256');
  return shasum.update(data).digest('hex');
}

function calculateRfc2104Hmac(data, key) {
  var signature = crypto.createHmac('sha256', key).update(data).digest('base64');
  return signature;
}

function toBase64(data) {
  return new Buffer(data).toString('base64');
}

function fromBase64(data) {
  return new Buffer(data, 'base64').toString('ascii');
}

function createStringToSign(req) {
  if (!req.headers && req.header) req.headers = req.header;
  var contentType = req.headers['Content-Type'];
  if (!contentType) contentType = "";

  var date = req.headers.Date || req.headers.date;
  if (!date) throw new Error("Missing Date Header");

  var reqUrl = req.originalUrl || req.url;
  var uri = url.parse(reqUrl).pathname;
  var version = 'HTTP/1.1';
  var method = req.method.toUpperCase();

  return util.format('%s %s %s\n%s\n%s', method, uri, version, contentType, date);
}

function getAuth(req, authType, publicKey, privateKey, appPublicKey, appPrivateKey) {
  var key = toBase64(util.format('%s:%s', appPublicKey, publicKey));
  var secret = util.format('%s:%s', appPrivateKey, privateKey);
  var stringToSign = createStringToSign(req);
  var signature = calculateRfc2104Hmac(stringToSign, secret);
  var authString = util.format('%s %s:%s', authType, key, signature);
  return authString;
}

module.exports = {
  sha: sha,
  calculateRfc2104Hmac: calculateRfc2104Hmac,
  toBase64: toBase64,
  fromBase64: fromBase64,
  createStringToSign: createStringToSign,
  getAuth: getAuth
};
