# Description:
#   Utility commands surrounding Hubot uptime.

calendar = require("./google-calendar.coffee")
scheduler = require("./scheduler.coffee")
user = require("./user.coffee")
async = require("async")
cron = require("./cron.coffee")
as = require("./assignment.coffee")

module.exports = (robot) ->
  robot.respond /assign/i, (msg) ->
    try
      as.assign(robot, (messages) ->
        for message in messages
          msg.send message
      )
    catch error
      msg.send error


  robot.respond /assign list/i, (msg) ->
    messages = as.getAssignmentsListMsg robot
    for message in messages
      msg.send message


  robot.respond /users list/i, (msg) ->
    users = user.getAll(robot)
    unless users?
      msg.send "There are no users. Please regist users by `save me as
    B4|M1|M2`"
      return
    msg.send "Registerd users are as follows..."
    users.forEach((user) ->
      name = user["name"]
      msg.send "name:#{user["name"]}, grade:#{user["grade"]}"
    )


  robot.respond /save me as (B4|M1|M2)/i, (msg) ->
    name  = msg.envelope.user.name
    grade = msg.match[0].split(" ")[4]
    user_info = {
      "name": name,
      "grade": grade
    }
    try
      user.set(user_info, robot)
      msg.send "Save #{name} as #{grade}!"
    catch error
      msg.send "#{error}"


  robot.respond /update (.+) : (.+) > (.+)/i, (msg) ->
    name = msg.match[0].split(" ")[2]
    prop = msg.match[0].split(" ")[4]
    val  = msg.match[0].split(" ")[6]
    try
      user.update(name, prop, val, robot)
      msg.send "Successfully updated!"
    catch error
      msg.send "#{error}"


  robot.respond /remove (.+)/i, (msg) ->
    name = msg.match[0].split(" ")[2]
    try
      user.remove(name, robot)
      msg.send "Successfully removed!"
    catch error
      msg.send "#{error}"
