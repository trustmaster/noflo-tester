var coffeeScript = require('coffee-script');
if (typeof coffeeScript.register !== 'undefined') {
  coffeeScript.register();
}
module.exports = require('./lib/tester.coffee');
