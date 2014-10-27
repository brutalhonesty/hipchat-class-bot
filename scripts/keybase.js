# Description:
#   Gets the daily top10 torrents and looks up a user on What.cd
#
# Dependencies:
#   "scrypt": "^3.0.1"
#
# Configuration:
#   HUBOT_KEYBASE_EMAIL_OR_USERNAME - Your Keybase.io Username or Email
#   HUBOT_KEYBASE_PASSWORD - Your Keybase.io Password
#
# Commands:
#   hubot keybase user <username> - Looks up the Keybase.io username requested.
#   hubot keybase user domain <username> - Looks up the Keybase.io username requested based on a domain.
#   hubot keybase user twitter <username> - Looks up the Keybase.io username requested based on a domain.
#   hubot keybase user github <username> - Looks up the Keybase.io username requested based on a domain.
#   hubot keybase user reddit <username> - Looks up the Keybase.io username requested based on a domain.
#   hubot keybase user hackernews <username> - Looks up the Keybase.io username requested based on a domain.
#   hubot keybase user coinbase <username> - Looks up the Keybase.io username requested based on a domain.
#   hubot keybase login - Logs the Keybase.io username in and returns the session.
#
# Author:
#   brutalhonesty

var scrypt = require('scrypt');
var crypto = require('crypto');
var username = process.env.HUBOT_KEYBASE_EMAIL_OR_USERNAME;
var password process.env.HUBOT_KEYBASE_PASSWORD;

scrypt.kdf.config.saltEncoding = "ascii";
scrypt.kdf.config.keyEncoding = "ascii";

module.exports = function(robot) {

  return robot.respond(/keybase login$/i, function(msg) {
    if(!username) {
      msg.send("Please set the HUBOT_KEYBASE_EMAIL_OR_USERNAME environment variable.");
      return;
    }
    if(!password) {
      msg.send("Please set the HUBOT_KEYBASE_PASSWORD environment variable.");
      return;
    }
    msg.http("https://keybase.io")
      .path("/_/api/1.0/getsalt.json?email_or_username=" + username)
      .get()(function(err, res, body) {
        if(err) {
          msg.send(err);
          return;
        }
        body = JSON.parse(body);
        if(body.status.code === 0) {
          var loginSession = body.login_session;
          var csrfToken = body.csrf_token;
          var salt = body.salt;
          var bytes = [];
          for(var i=0; i< salt.length-1; i+=2){
              bytes.push(parseInt(salt.substr(i, 2), 16));
          }
          var binarySalt = String.fromCharCode.apply(String, bytes);
          scrypt.kdf(password, {N: Math.pow(2,15), r:8, p:1}, 224, binarySalt, function(err, result){
            var hash = crypto.createHmac('sha512', result.hash.slice(192, 224));
            hash.update(new Buffer(loginSession, 'base64'));
            var hashed_data = hash.digest('hex');
            var params = "csrf_token=" + csrfToken + "&login_session=" + loginSession + "&email_or_username=" + username + "&hmac_pwh=" + hashed_data;
            msg.http("https://keybase.io")
            .path("/_/api/1.0/login.json")
            .post(params)(function (err, res, body) {
              if(err) {
                msg.send(err);
                return;
              }
              body = JSON.parse(body);
              if(body.status.code === 0) {
                msg.send(body.session);
              } else {
                msg.send(body.status.des);
              }
            });
        } else {
          msg.send(body.status.des);
        }
      });
  });
}
