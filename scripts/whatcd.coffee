# Description:
#   Gets the daily top10 torrents and looks up a user on What.cd
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_WHAT_CD_USERNAME - Your What.cd username
#   HUBOT_WHAT_CD_PASSWORD - Your What.cd password
#
# Commands:
#   hubot whatcd top10 - Returns the current daily top10 albums
#   hubot whatcd user <username> - Returns information about a What.cd user
#
# Author:
#   brutalhonesty

module.exports = (robot) ->

  username = process.env.HUBOT_WHAT_CD_USERNAME || null
  password = process.env.HUBOT_WHAT_CD_PASSWORD || null

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
    params = "username=" + username + "&password=" + password
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
              msg.send JSON.stringify resp.results
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
    params = "username=" + username + "&password=" + password
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
            userData = rank: body.response.personal.class, upload: parseInt(body.response.stats.uploaded) / 1024 / 1024 / 1024, download: parseInt(body.response.stats.downloaded) / 1024 / 1024 / 1024, ratio: body.response.stats.ratio
            msg.send JSON.stringify userData
      else
        msg.send "Error: response status code was " + res.statusCode
        return
