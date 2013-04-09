// Setup connection to real-time market data
var io = require('socket.io-client');
var feed = io.connect('https://feed.bitfloor.com/1');

// Using redis client as datastore
var redis = require('redis');
var client = redis.createClient();

// Logging completed orders in Redis
feed.on('match', function(data) {
  console.log('seq', data['seq'])
  
  date = new Date()
  hour = date.getHours()
  day = date.getDate()
  month = date.getMonth() + 1

  trade_key = month.toString() + day.toString() + hour.toString()

  client.sadd(trade_key, data['seq'])
  client.hmset(data['seq'], 'timestamp', data['timestamp'], 'price', data['price'], 'size', data['size'])
});
