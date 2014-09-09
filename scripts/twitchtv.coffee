# Description:
#   Gets whether the Twitch.TV streamer is online.
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_TWITCH_TV_CLIENT_ID - Your Twitch.Tv Client Id
#
# Commands:
#   hubot twitchtv user <username> - Returns whether the user is streaming or not.
#   hubot twitchtv favorites add <username> - Adds a user to your favorite list.
#   hubot twitchtv favorites remove <username> - Removes a user to your favorite list.
#   hubot twitchtv favorites  - Shows the stream info about each user in your friends list.
#
# Author:
#   brutalhonesty

module.exports = (robot) ->

  clientId = process.env.HUBOT_TWITCH_TV_CLIENT_ID || null

  robot.respond /twitchtv user (\w+)$/i, (msg) ->
    unless clientId
      msg.send 'Please set the HUBOT_TWITCH_TV_CLIENT_ID environment variable.'
      return
    msg.http('https://api.twitch.tv')
    .path('/kraken/streams/' + msg.match[1] + '/?client_id=' + clientId)
    .get() (err, res, body) ->
      if err
        msg.send err
        return
      body = JSON.parse body
      if body.stream is null
        msg.send 'User is offline.'
        return
      msg.send 'User is playing ' + body.stream.game + ' with ' + body.stream.viewers + ' viewers.'
      msg.send body.stream.preview.medium

  robot.respond /twitchtv favorites add (\w+)$/i, (msg) ->
    twitchUsers = robot.brain.get 'twitchtv_users'
    unless twitchUsers
      twitchUsers = []
    twitchUsers.push msg.match[1]
    robot.brain.set 'twitchtv_users', twitchUsers
    msg.send 'User ' + msg.match[1] + ' added.'
    return

  robot.respond /twitchtv favorites remove (\w+)$/i, (msg) ->
    twitchUsers = robot.brain.get 'twitchtv_users'
    unless twitchUsers
      msg.send 'No favorites in list.'
      return
    deleted = false
    for user, index in twitchUsers
      if user is msg.match[1]
        twitchUsers.splice index, 1
        deleted = true
    if deleted
      robot.brain.set 'twitchtv_users', twitchUsers
      msg.send 'User ' + msg.match[1] + ' removed.'
      return
    else
      msg.send 'User ' + msg.match[1] + ' not found.'
      return

  robot.respond /twitchtv favorites$/i, (msg) ->
    twitchUsers = robot.brain.get 'twitchtv_users'
    unless twitchUsers
      msg.send 'No favorites in list.'
      return
    msg.http('https://api.twitch.tv')
    .path('/kraken/streams/?channel=' + twitchUsers.join ',')
    .get() (err, res, body) ->
      if err
        msg.send err
        return
      body = JSON.parse body
      if body.streams.length is 0
        msg.send "User(s) are offline."
        return
      for stream in body.streams
        msg.send stream.channel.display_name + ' is playing ' + stream.game + ' with ' + stream.viewers + ' viewers.'
        msg.send stream.preview.medium


