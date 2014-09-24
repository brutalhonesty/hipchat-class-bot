# Description:
#   Gets current Steam Friends online for a given Steam ID
#
# Dependencies:
#   "cheerio": "^0.17.0"
#   "querystring": "^0.2.0"
#   "request": "^2.42.0"
#   hipchat-api script from "hubot-scripts"
#
# Configuration:
#   HUBOT_HIPCHAT_USERNAME - The bot username to display.
#   HUBOT_HIPCHAT_ROOMS - The rooms the bot is assigned to.
#   HUBOT_HIPCHAT_TOKEN - The hipchat auth token.
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
url = process.env.HEROKU_URL or null
botName = process.env.HUBOT_HIPCHAT_USERNAME or null

module.exports = (robot) ->

  robot.respond /steamfriends (\w+)/i, (msg) ->
    unless url
      msg.send "Please set the HEROKU_URL environment variable."
      return
    unless botName
      msg.send "Please set the HUBOT_HIPCHAT_USERNAME environment variable."
      return
    unless process.env.HUBOT_HIPCHAT_ROOMS
      msg.send "Please set the HUBOT_HIPCHAT_ROOMS environment variable."
      return
    unless process.env.HUBOT_HIPCHAT_TOKEN
      msg.send "Please set the HUBOT_HIPCHAT_TOKEN environment variable."
      return
    msg.http('https://hipchat.com')
    .path('/v1/rooms/list?format=json&auth_token=' + process.env.HUBOT_HIPCHAT_TOKEN)
    .header("Accept", "application/json")
    .get() (err, res, body) ->
      if err
        msg.send err
        return
      body = JSON.parse body
      for room in body.rooms
        if room.xmpp_jid is process.env.HUBOT_HIPCHAT_ROOMS.split(',')[0]
          roomName = room.name
      unless roomName
        msg.send "Could not find the room name."
        return
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
          $('table').append('<tr><td>'+ user.names + '</td><td>'+ user.games + '</td></tr>')
        response = {}
        response.color = 'green'
        response.room_id = roomName
        response.notify = true
        response.message_format = 'html'
        response.from = botName
        response.message = $.html()
        params = querystring.stringify(response)
        request "#{url}/hubot/hipchat?#{params}", (error, response, body) ->
          if error
            msg.send error