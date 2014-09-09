# Description:
#   Gets current Steam Friends online for a given Steam ID
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot steamfriends <friend id> - Returns the list of friends online and their games.
#
# Author:
#   brutalhonesty

module.exports = (robot) ->

  robot.respond /steamfriends (\w+)/i, (msg) ->
    msg.http("http://steamfriends-brutalhonesty.rhcloud.com/getFriends")
    .header("Accept", "application/json")
    .query(type: "json", steamid: msg.match[1])
    .get() (err, res, body) ->
      if err
        msg.send err
        return
      body = JSON.parse body
      msg.send JSON.stringify body.list.user