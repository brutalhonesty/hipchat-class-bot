# Description:
#   Gets the daily top10 torrents and looks up a user on What.cd
#
# Dependencies:
#   "cheerio": "^0.17.0"
#   "querystring": "^0.2.0"
#   "request": "^2.42.0"
#   hipchat-api script from "hubot-scripts"
#
# Configuration:
#   HUBOT_WHAT_CD_USERNAME - Your What.cd username
#   HUBOT_WHAT_CD_PASSWORD - Your What.cd password
#   HUBOT_HIPCHAT_USERNAME - The Bots username to display
#   HUBOT_HIPCHAT_ROOMS - The rooms the bot is assigned to
#   HUBOT_HIPCHAT_TOKEN - The hipchat auth token.
#   HEROKU_URL - The url of the bot server.
#
# Commands:
#   hubot whatcd top10 - Returns the current daily top10 albums
#   hubot whatcd user <username> - Returns information about a What.cd user
#
# Author:
#   brutalhonesty

querystring = require 'querystring'
cheerio = require 'cheerio'
request = require 'request'
url = process.env.HEROKU_URL or null
botName = process.env.HUBOT_HIPCHAT_USERNAME or null
username = process.env.HUBOT_WHAT_CD_USERNAME or null
password = process.env.HUBOT_WHAT_CD_PASSWORD or null

module.exports = (robot) ->

  robot.respond /whatcd top10$/i, (msg) ->
    unless username and password
      msg.send "Please set the HUBOT_WHAT_CD_USERNAME and HUBOT_WHAT_CD_PASSWORD environment variable."
      return
    unless username
      msg.send "Please set the HUBOT_WHAT_CD_USERNAME environment variable."
      return
    unless password
      msg.send "Please set the HUBOT_WHAT_CD_PASSWORD environment variable."
      return
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
    params = "username=" + username + "&password=" + password
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
    msg.http("https://what.cd")
    .path("/login.php")
    .header("Accept", "*/*")
    .header("Content-Type", "application/x-www-form-urlencoded; charset=utf-8")
    .post(params) (err, res, body) ->
      if err
        msg.send err
        return
      if res.statusCode is 302
        cookie = res.headers["set-cookie"][1]
        msg.http("https://what.cd")
        .path("/ajax.php?action=top10")
        .header("Accept", "application/json, */*")
        .header("Cookie", cookie)
        .get() (err, res, body) ->
          if err
            msg.send err
            return
          body = JSON.parse body
          if body.status is "failure"
            msg.send body.error
            return
          for resp in body.response
            if resp.tag is "day"
              $ = cheerio.load('<table></table>')
              $('table').append('<tr><th>Artist</th><th>Album</th><th>Format</th><th>Encoding</th><th>Seeders</th><th>Leechers</th></tr>')
              for album in resp.results
                $('table').append('<tr><td>'+ album.artist + '</td><td>' + album.groupName + '</td><td>'+ album.format + '</td><td>'+ album.encoding + '</td><td>'+ album.seeders + '</td><td>'+ album.leechers + '</td></tr>')
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
              return
      else
        msg.send "Error: response status code was " + res.statusCode
        return

  robot.respond /whatcd user (\w+)$/i, (msg) ->
    unless username and password
      msg.send "Please set the HUBOT_WHAT_CD_USERNAME and HUBOT_WHAT_CD_PASSWORD environment variable."
      return
    unless username
      msg.send "Please set the HUBOT_WHAT_CD_USERNAME environment variable."
      return
    unless password
      msg.send "Please set the HUBOT_WHAT_CD_PASSWORD environment variable."
      return
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
    params = "username=" + username + "&password=" + password
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
    msg.http("https://what.cd")
    .path("/login.php")
    .header("Accept", "*/*")
    .header("Content-Type", "application/x-www-form-urlencoded; charset=utf-8")
    .post(params) (err, res, body) ->
      if err
        msg.send err
        return
      if res.statusCode is 302
        cookie = res.headers["set-cookie"][1]
        msg.http("https://what.cd")
        .path("/ajax.php?action=usersearch&search=" + msg.match[1])
        .header("Accept", "application/json")
        .header("Cookie", cookie)
        .get() (err, res, body) ->
          if err
            msg.send err
            return
          body = JSON.parse body
          if body.status is "failure"
            msg.send body.error
            return
          userId = body.response.results[0].userId
          msg.http("https://what.cd")
          .path("/ajax.php?action=user&id=" + userId)
          .header("Accept", "application/json")
          .header("Cookie", cookie)
          .get() (err, res, body) ->
            if err
              msg.send err
              return
            body = JSON.parse body
            if body.status is "failure"
              msg.send body.error
              return
            $ = cheerio.load('<table></table>')
            $('table').append('<tr><th>Rank</th><th>Upload</th><th>Download</th><th>Ratio</th></tr>')
            $('table').append('<tr><td>'+ body.response.personal.class + '</td><td>' + parseInt(body.response.stats.uploaded) / 1024 / 1024 / 1024 + ' GB</td><td>'+ parseInt(body.response.stats.downloaded) / 1024 / 1024 / 1024 + ' GB</td><td>'+ parseFloat(body.response.stats.ratio) + '</td></tr>')
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
            return
      else
        msg.send "Error: response status code was " + res.statusCode
        return
