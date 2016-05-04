# Description
#   Assign users to duty on google calendar
#
# Configuration:
#   None
#
# Commands:
#   gomi-man-bot get auth url - Get url and visit there, you'll be able to retrive
#   gomi-man-bot authorization code
#   gomi-man-bot auth with <url> - Retrive access token and store it
#   gomi-man-bot assign - Retrive duties from google calendar and assign users
#   gomi-man-bot assign list - Assignments list
#   gomi-man-bot users list - Display users saved in this app
#   gomi-man-bot save me as <B4|M1|M2> - Save user as B4|M1|M2
#   gomi-man-bot update <username> : <property> > <value> - Update users
#   gomi-man-bot <property>'s value to <value>
#   gomi-man-bot remove <username> - Remove user who has <username>
#
# Author:
#   tasuwo <kamuhata.you@gmail.com>

calendar = require("./google-calendar.coffee")
scheduler = require("./scheduler.coffee")
user = require("./user.coffee")
async = require("async")
cron = require("./cron.coffee")
as = require("./assignment.coffee")

module.exports = (robot) ->
  cron.startJobs(robot, "test")

  robot.respond /get auth url/i, (msg) ->
    msg.send do calendar.getAuthUrlMsg

  robot.respond /auth with (.+)/i, (msg) ->
    code = msg.match[0].split(" ")[3]
    calendar.getNewToken code, (res, err) ->
      if err
        msg.send err; return
      msg.send res
    , robot

  robot.respond /assign/i, (msg) ->
    try
      as.assign(robot, (messages, err) ->
        if err
          msg.send err; return
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
