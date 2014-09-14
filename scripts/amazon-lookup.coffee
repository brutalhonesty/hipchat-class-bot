# Description:
#   Gets the product and price information for a given Amazon product.
#
# Dependencies:
#  "aws2": "^0.1.5",
#  "xml2json": "^0.5.1"
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
parser = require 'xml2json'

module.exports = (robot) ->

  robot.hear /(?:http|https):\/\/(?:www.)?(?:smile.)?(?:amazon|amzn).com(?:\/.*){0,1}(?:\/dp\/|\/gp\/product\/)(.*)\//i, (msg) ->

    unless process.env.HUBOT_AWS_ACCESS_KEY_ID
      msg.send "Please set the HUBOT_AWS_ACCESS_KEY_ID environment variable."
      return
    unless process.env.HUBOT_AWS_SECRET_ACCESS_KEY
      msg.send "Please set the HUBOT_AWS_SECRET_ACCESS_KEY environment variable."
      return
    lookupOptions = {
      host: 'webservices.amazon.com',
      path: '/onca/xml?Service=AWSECommerceService&Operation=ItemLookup&ItemId='+msg.match[1]+'&AssociateTag=foobar',
    };
    aws2.sign(lookupOptions, {
      accessKeyId: process.env.HUBOT_AWS_ACCESS_KEY_ID,
      secretAccessKey: process.env.HUBOT_AWS_SECRET_ACCESS_KEY
    });
    msg.http("https://" + lookupOptions.host)
    .path(lookupOptions.path)
    .header("Accept", "application/xml")
    .get() (err, res, body) ->
      if err
        msg.send err
        return
      jsonData = parser.toJson(body);
      jsonData = JSON.parse(jsonData);
      productTitle = jsonData['ItemLookupResponse']['Items']['Item']['ItemAttributes']['Title'];
      productTitle = productTitle.replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&#40;/g, '(').replace(/&#41;/g, ')');
      offerOptions = {
        host: 'webservices.amazon.com',
        path: '/onca/xml?Service=AWSECommerceService&Operation=ItemLookup&ResponseGroup=Offers&IdType=ASIN&ItemId='+msg.match[1]+'&AssociateTag=foobar'
      };
      aws2.sign(offerOptions, {
        accessKeyId: process.env.HUBOT_AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.HUBOT_AWS_SECRET_ACCESS_KEY
      });
      msg.http("https://" + offerOptions.host)
      .path(offerOptions.path)
      .header("Accept", "application/xml")
      .get() (err, res, body) ->
        if err
          msg.send err
          return
        jsonData = parser.toJson(body);
        jsonData = JSON.parse(jsonData);
        productNewPrice = jsonData['ItemLookupResponse']['Items']['Item']['OfferSummary']['LowestNewPrice']['FormattedPrice'];
        productNewInventory = jsonData['ItemLookupResponse']['Items']['Item']['OfferSummary']['TotalNew'];
        productUsedPrice = jsonData['ItemLookupResponse']['Items']['Item']['OfferSummary']['LowestUsedPrice']['FormattedPrice'];
        productUsedInventory = jsonData['ItemLookupResponse']['Items']['Item']['OfferSummary']['TotalUsed'];
        msg.send productTitle + ': ' + productNewInventory + ' new @ ' + productNewPrice + ', ' + productUsedInventory + ' used @ ' + productUsedPrice
