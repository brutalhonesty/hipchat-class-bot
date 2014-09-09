# Description:
#   Gets flight information
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_FLIGHTSTATS_APP_ID - The Flightstats App Id
#   HUBOT_FLIGHTSTATS_APP_KEY - The Flightstats App Key
#
# Commands:
#   hubot flightstats <flight number> - Returns the hashes versions of the plaintext word
#   TODO hubot flightstats arrive <01/31/2014> - Returns the flights arriving on the given date (starting from the specified hour of day)
#   TODO hubot flightstats depart <01/31/2014> - Returns the flights departing on the given date (starting from the specified hour of day)
#   TODO hubot flightstats codes - Returns the airline codes
#
# Author:
#   brutalhonesty

module.exports = (robot) ->
  auth =
      appId: process.env.HUBOT_FLIGHTSTATS_APP_ID
      appKey: process.env.HUBOT_FLIGHTSTATS_APP_KEY

  robot.respond /flightstats (\d+)/i, (msg) ->
    unless auth.appId and auth.appKey
      msg.send "Please set the HUBOT_FLIGHTSTATS_APP_ID and HUBOT_FLIGHTSTATS_APP_KEY environment variable."
      return
    unless auth.appId
      msg.send "Please set the HUBOT_FLIGHTSTATS_APP_ID environment variable."
      return
    unless auth.appKey
      msg.send "Please set the HUBOT_FLIGHTSTATS_APP_KEY environment variable."
      return
    msg.http("https://api.flightstats.com/flex/flightstatus/rest/v2/json/flight/status/" + msg.match[1])
    .query(appId: auth.appId, appKey: auth.appKey)
    .get() (err, res, body) ->
      if err
        msg.send err
        return
      body = JSON.parse(body)
      if body.error
        msg.send body.error.errorMessage
        return
      msg.send JSON.stringify(body)