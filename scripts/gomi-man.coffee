# Description
#   Assign users to duty on google calendar
#
# Configuration:
#   None
#
# Commands:
#   gomi-man-bot auth get url - Get url and visit there, you'll be able to retrive authorization code
#   gomi-man-bot auth with <url> - Retrive access token and store it
#   gomi-man-bot assign users - Retrive duties from google calendar and assign users
#   gomi-man-bot assign reset - Reset assignments
#   gomi-man-bot assign list - Assignments list
#   gomi-man-bot users list - Display users saved in this app
#   gomi-man-bot save me as <B4|M1|M2> - Save user as B4|M1|M2
#   gomi-man-bot update <username> : <property> > <value> - Update users <property>'s value to <value>
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
  regexes = []
  cron.startJobs(robot)

  # TODO : set automatically when bot is invited
  regex = "channel set (.+)"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    channel = msg.match[0].split(" ")[3]
    cron.setNotifyChannel channel
    msg.send "I'll notify to channel: #{channel}"

  regex = "auth get url"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    msg.send do calendar.getAuthUrlMsg

  regex = "auth with (.+)"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    code = msg.match[0].split(" ")[3]
    calendar.getNewToken code, (res, err) ->
      if err
        msg.send err; return
      msg.send res
    , robot

  regex = "assign users"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    try
      as.assign(robot, (messages, err) ->
        if err
          msg.send err; return
        for message in messages
          msg.send message
      )
    catch error
      msg.send error

  regex = "assign list"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    messages = as.getAssignmentsListMsg robot
    for message in messages
      msg.send message

  regex = "assign reset"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    as.resetAssignmentsList robot
    msg.send "Successfully reset assignment!"

  regex = "users list"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    users = user.getAll(robot)
    unless users?
      msg.send "There are no users. Please regist users by `save me as B4|M1|M2`"
      return
    msg.send "Registerd users are as follows..."
    users.forEach((user) ->
      name = user["name"]
      msg.send "`#{user["id"]}` name:#{user["name"]}, grade:#{user["grade"]}"
    )

  regex = "save me as (B4|M1|M2)"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
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

  regex = "update (.+) : (.+) > (.+)"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    name = msg.match[0].split(" ")[2]
    prop = msg.match[0].split(" ")[4]
    val  = msg.match[0].split(" ")[6]
    try
      user.update(name, prop, val, robot)
      msg.send "Successfully updated!"
    catch error
      msg.send "#{error}"

  regex = "remove (.+)"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    name = msg.match[0].split(" ")[2]
    try
      user.remove(name, robot)
      msg.send "Successfully removed!"
    catch error
      msg.send "#{error}"

  # TODO: Intelligence match
  robot.hear new RegExp("^@gomi-man-bot: (?!("+regexes.join("|")+"))", "g"), (msg) ->
    msg.send msg.random [
      "I don't understand.",
      "Sorry, #{msg.envelope.user.name}, I didn't get that.",
      "That does not compute, #{msg.envelope.user.name}."
    ]
