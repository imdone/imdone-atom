var KeenTracking = require('keen-tracking');

// Configure a client instance
var client = new KeenTracking({
  projectId: '5ad4b047c9e77c0001a03747',
  writeKey: '114ADADE7BD4883071292ECA509E032E3241BB7D62C5EFDD34AE1C6525C4A7B91328F514BA46376CCA7A59C85172B32940C8A062DBC99795B7A67EC052F23792D0C386E27184D4AA22B771A6085C5B7B55D28B1C6BEBCA7A81CCF816D524E5FC'
});

var user;

var send = function(name, data) {
  if (name === 'authenticated') user = data
  else if (user) data.user = {email: user.email, id: user.id}
  client.recordEvent(name, data);
}
module.exports = {
  send,
  click: function (e) {
    console.log('*********************************',e)
  }
}
