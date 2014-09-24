# Description:
#   Gets current Ventrilo status or clients connected.
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
#   hubot ventrilostatus info <ip address | hostname> <port number> - Returns the status of the server.
#   hubot ventrilostatus clients <ip address | hostname> <port number> - Returns the list of clients connected to the server.
#
# Author:
#   brutalhonesty

querystring = require 'querystring'
cheerio = require 'cheerio'
request = require 'request'
url = process.env.HEROKU_URL or null
botName = process.env.HUBOT_HIPCHAT_USERNAME or null

module.exports = (robot) ->

  robot.respond /ventrilostatus info ((\d?\d?\d)\.(\d?\d?\d)\.(\d?\d?\d)\.(\d?\d?\d)) (\d+)/i, (msg) ->
    msg.http("http://ventrilostatus.net/json/" + msg.match[1] + ":" + msg.match[6] + "/")
    .header("Accept", "application/json")
    .get() (err, res, body) ->
      if err
        msg.send err
        return
      body = JSON.parse body
      if body.error
        msg.send body.error
        return
      msg.send body.name + " has been up for " + body.uptime + " seconds and has " + body.client.length + " clients connected."

  robot.respond /ventrilostatus clients ((\d?\d?\d)\.(\d?\d?\d)\.(\d?\d?\d)\.(\d?\d?\d)) (\d+)/i, (msg) ->
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
      msg.http("http://ventrilostatus.net/json/" + msg.match[1] + ":" + msg.match[6]  + "/")
      .header("Accept", "application/json")
      .get() (err, res, body) ->
        if err
          msg.send err
          return
        body = JSON.parse body
        if body.error
          msg.send body.error
          return
        $ = cheerio.load('<table></table>')
        $('table').append('<tr><th>User</th><th>Admin</th><th>Ping</th><th>Comment</th></tr>')
        for client in body.client
          if client.admin is 1
            admin_entity = '&#x2713;'
          else
            admin_entity = '&#x2717;'
          $('table').append('<tr><td>'+ client.name + '</td><td>' + admin_entity + '</td><td>'+ client.ping + '</td><td>'+ client.comm or '' + '</td></tr>')
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