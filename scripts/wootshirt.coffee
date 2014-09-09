# Description:
#   Gets the current Shirt Woot
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_WOOT_API_KEY - The Woot.com API Key
#
# Commands:
#   hubot wootshirt - Returns the daily shirt.woot.com shirt
#
# Author:
#   brutalhonesty

module.exports = (robot) ->

  apiKey = process.env.HUBOT_WOOT_API_KEY || null

  robot.respond /wootshirt$/i, (msg) ->
    unless apiKey
      msg.send "Please set the HUBOT_WOOT_API_KEY environment variable."
      return
    msg.http("https://api.woot.com")
    .path('/2/events.json')
    .header("Accept", "application/json")
    .query(key: apiKey, site: "shirt.woot.com", eventType: "Daily")
    .get() (err, res, body) ->
      if err
        msg.send err
        return
      body = JSON.parse body
      msg.send body[0].title
      photoUrl = null
      for photo in body[0].Offers[0].Photos
        if photo.Tags
          for tag in photo.Tags
            if tag is "fullsize-0"
              photoUrl = photo.Url
              msg.send photoUrl