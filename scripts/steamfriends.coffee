# Description:
#   Gets current Steam Friends online for a given Steam ID
#
# Dependencies:
#   "cheerio": "^0.17.0"
#   "querystring": "^0.2.0"
#   "request": "^2.42.0"
#
# Configuration:
#   HUBOT_HIPCHAT_USERNAME - The Bots username to display
#   HUBOT_HIPCHAT_ROOMS - The rooms the bot is assigned to
#   HEROKU_URL - The url of the bot server.
#
# Commands:
#   hubot steamfriends <friend id> - Returns the list of friends online and their games.
#
# Author:
#   brutalhonesty

querystring = require 'querystring'
cheerio = require 'cheerio'
request = require 'request'
url = process.env.HEROKU_URL
botName = HUBOT_HIPCHAT_USERNAME

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
      userList = body.list.user
      $ = cheerio.load('<table></table>')
      $('table').append('<tr><th>Player</th><th>Game</th></tr>')
      for user in userList
        $('table').append('<tr><td>'+ user.names + '<td>'+ user.games + '</td></td></tr>')
      response = {}
      response.color = 'green'
      response.room_id = process.env.HUBOT_HIPCHAT_ROOMS.split(',')[0].split('@')[0].split('_')[1]
      response.notify = true
      response.message_format = 'html'
      response.from = botName
      response.message = encodeURIComponent($.html())
      params = querystring.stringify(response)
      request "#{url}/hubot/hipchat?#{params}", (error, response, body) ->
        if error msg.send error