module.exports = (robot) ->

  robot.hear /ゴミ/i, (msg) ->
    msg.send msg.random ["I am gomi-man-bot."]
