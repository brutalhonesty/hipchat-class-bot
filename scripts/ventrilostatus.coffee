# Description:
#   Gets current Ventrilo status or clients connected.
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot ventrilostatus info <ip address | hostname> <port number> - Returns the status of the server.
#   hubot ventrilostatus clients <ip address | hostname> <port number> - Returns the list of clients connected to the server.
#
# Author:
#   brutalhonesty

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
      msg.send JSON.stringify body.client