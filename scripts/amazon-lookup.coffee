# Description:
#   Gets the product and price information for a given Amazon product.
#
# Dependencies:
#  "aws2": "^0.1.5"
#
# Configuration:
#   HUBOT_AWS_ACCESS_KEY_ID - Your AWS Access Key Id
#   HUBOT_AWS_SECRET_ACCESS_KEY - Your AWS Secret Access Key
#
# Commands:
#   <Amazon link> - returns the info about the link.
#
# Author:
#   brutalhonesty

aws2  = require 'aws2'

module.exports = (robot) ->

  robot.hear /(?:http|https):\/\/(?:www.)?(?:smile.)?(?:amazon|amzn).com(?:\/.*){0,1}(?:\/dp\/|\/gp\/product\/)(.*)\//i, (msg) ->

    msg.send 'Hello world'
    unless process.env.HUBOT_AWS_ACCESS_KEY_ID
      msg.send "Please set the HUBOT_AWS_ACCESS_KEY_ID environment variable."
      return
    unless process.env.HUBOT_AWS_SECRET_ACCESS_KEY
      msg.send "Please set the HUBOT_AWS_SECRET_ACCESS_KEY environment variable."
      return
    lookupOptions = {
      host: 'webservices.amazon.com',
      path: '/onca/xml?Service=AWSECommerceService&Operation=ItemLookup&ItemId='+msg.match[0]+'&AssociateTag=foobar',
    }
    aws2.sign(lookupOptions, {
      accessKeyId: process.env.HUBOT_AWS_ACCESS_KEY_ID,
      secretAccessKey: process.env.HUBOT_AWS_SECRET_ACCESS_KEY
    });
    msg.send JSON.stringify(lookupOptions);