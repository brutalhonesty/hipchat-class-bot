// Description:
//   Gets the daily top10 torrents and looks up a user on What.cd
//
// Dependencies:
//   "scrypt": "^3.0.1"
//
// Configuration:
//   HUBOT_KEYBASE_EMAIL_OR_USERNAME - Your Keybase.io Username or Email
//   HUBOT_KEYBASE_PASSWORD - Your Keybase.io Password
//
// Commands:
//   hubot keybase user keybase <username> - Looks up the Keybase.io username requested.
//   hubot keybase user domain <domain> - Looks up the Keybase.io username requested based on a domain.
//   hubot keybase user twitter <username> - Looks up the Keybase.io username requested based on a domain.
//   hubot keybase user github <username> - Looks up the Keybase.io username requested based on a domain.
//   hubot keybase user reddit <username> - Looks up the Keybase.io username requested based on a domain.
//   hubot keybase user hackernews <username> - Looks up the Keybase.io username requested based on a domain.
//   hubot keybase user coinbase <username> - Looks up the Keybase.io username requested based on a domain.
//   hubot keybase login - Logs the Keybase.io username in and returns the session.
//
// Author:
//   brutalhonesty

var scrypt = require('scrypt');
var crypto = require('crypto');
var username = process.env.HUBOT_KEYBASE_EMAIL_OR_USERNAME;
var password = process.env.HUBOT_KEYBASE_PASSWORD;

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

  return robot.respond(/keybase user (keybase|domain|github|twitter|reddit|hackernews|coinbase) (\w+)$/i, function(msg) {
    if(msg.match[1] === 'keybase') {
      var lookupType = 'usernames';
    } else {
      lookupType = msg.match[1];
    }
    msg.http('https://keybase.io')
    .path('/_/api/1.0/user/lookup.json?'+lookupType+'=' + msg.match[2])
    .get()(function (err, res, body) {
        if(err) {
          msg.send(err);
          return;
        }
        body = JSON.parse(body);
        if(body.status.code === 0) {
          msg.send("User " + body.them[0].basics.username + " (" + body.them[0].profile.full_name + ") from " + body.them[0].profile.location);
          var proofTypes = body.them[0].proofs_summary.by_proof_type;
          if(proofTypes.twitter) {
            for (var i = 0; i < proofTypes.twitter.length; i++) {
              msg.send("Twitter: " + proofTypes.twitter[i].nametag);
            }
          }
          if(proofTypes.github) {
            for (var i = 0; i < proofTypes.github.length; i++) {
              msg.send("Github: " + proofTypes.github[i].nametag);
            }
          }
          if(proofTypes.reddit) {
            for (var i = 0; i < proofTypes.reddit.length; i++) {
              msg.send("Reddit: " + proofTypes.reddit[i].nametag);
            }
          }
          if(proofTypes.coinbase) {
            for (var i = 0; i < proofTypes.coinbase.length; i++) {
              msg.send("CoinBase: " + proofTypes.coinbase[i].nametag);
            }
          }
          if(proofTypes.hackernews) {
            for (var i = 0; i < proofTypes.hackernews.length; i++) {
              msg.send("Hacker News: " + proofTypes.hackernews[i].nametag);
            }
          }
          if(proofTypes.generic_web_site) {
            for (var i = 0; i < proofTypes.generic_web_site.length; i++) {
              msg.send("Website: " + proofTypes.generic_web_site[i].nametag);
            }
          }
          if(proofTypes.dns) {
            for (var i = 0; i < proofTypes.dns.length; i++) {
              msg.send("DNS: " + proofTypes.dns[i].nametag);
            }
          }
        }
    });
  });
}
