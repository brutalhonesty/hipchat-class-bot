# Description:
#   Gets the cleartext password of a hash or hashes the cleartext password into various types.
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot leakdb <type> <plaintext> - Returns the requested hash for the plaintext word
#   hubot leakdb <hash> - Returns the cleartext password if it exists in the data
#   hubot leakdb types - Returns the hash types that are available.
#
# Author:
#   brutalhonesty

module.exports = (robot) ->
  robot.respond /leakdb (gost|md4|md5|mysql4_mysql5|ntlm|plaintext|ripemd160|sha1|sha224|sha256|sha384|sha512|whirlpool) (\w+)/i, (msg) ->
    msg.http("http://api.leakdb.abusix.com")
    .query(j: msg.match[2])
    .header("Accept", "application/json")
    .get() (err, res, body) ->
      body = JSON.parse(body)
      if body.found
        msg.send body.hashes[0][msg.match[1]]
        return
      else
        msg.send "Hash not found in DB."
        return

  robot.respond /leakdb (?!gost|md4|md5|mysql4_mysql5|ntlm|plaintext|ripemd160|sha1|sha224|sha256|sha384|sha512|whirlpool|types)(\w+)/i, (msg) ->
    msg.http("http://api.leakdb.abusix.com")
    .query(j: msg.match[1])
    .header("Accept", "application/json")
    .get() (err, res, body) ->
      body = JSON.parse(body)
      if body.found and body.type isnt "plaintext"
        msg.send "Type: " + body.type + ", plaintext: " + body.hashes[0]["plaintext"]
        return
      else if body.found
        msg.send "Input was not a valid hash."
        return
      else
        msg.send "Hash not found in DB."
        return

  robot.respond /leakdb types/i, (msg) ->
    msg.http("http://api.leakdb.abusix.com")
    .query(j: "foo")
    .header("Accept", "application/json")
    .get() (err, res, body) ->
      body = JSON.parse(body)
      msg.send JSON.stringify(Object.keys(body.hashes[0]))
      return