# Description
#   Assign users to duty on google api
#
# Configuration:
#   None
#
# Commands:
#   auth get url - Get url to retrieve authorization code
#   auth with <code> - Retrive access token and store it with authorization code
#   assign users - Retrive duties from google calendar and assign users to them
#   assign reset - Reset assignments
#   assign list - Assignments list
#   assign from <uid> - Set user who will be assigned to duty at first in next assignment
#   channel set <name> - Set notification channel (default: develop)
#   channel check - Check norification channel
#   users list - Show users saved in this app
#   users sort by <method> - Sort user based on method. (method: grade)
#   users swap <id> <id> - Swap user position in the list
#   save me as <grade> - Save user who send this command as specified grade (grade: B4, M1, M2)
#   update <id> : <prop> > <value> - Update specified user's <property>'s value to <value>
#   remove <id> - Remove specified user
#
# Author:
#   tasuwo <kamuhata.you@gmail.com>

api = require("./googleapi.coffee")
user = require("./user.coffee")
async = require("async")
cron = require("./cron.coffee")
as = require("./assignment.coffee")

module.exports = (robot) ->
  regexes = []
  cron.startJobs(robot)

  # TODO : set automatically when bot is invited
  regex = "channel set (.+)$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    channel = msg.match[0].replace(/\s+/g, " ").split(" ")[3]
    cron.setNotifyChannel(channel, robot)
    msg.send "I'll send notification to channel: ##{channel}!"

  regex = "channel check$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    channel = cron.getNotifyChannel(robot)
    unless channel?
      msg.send "No channel registered. Please save channel by `channel
  set <channel name>` command."
      return
    msg.send "Notify channel is set to ##{channel}"

  regex = "auth get url$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    msg.send do api.getAuthUrlMsg

  regex = "auth with (.+)$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    code = msg.match[0].replace(/\s+/g, " ").split(" ")[3]
    api.getNewToken code, (res, err) ->
      if err
        msg.send err; return
      msg.send res
    , robot

  regex = "assign users$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    try
      as.assign(robot, (err, preStoredFlg) ->
        if err
          msg.send err
          return
        messages = if preStoredFlg
        then ["Assignment of this month has perfomed as follows"]
        else ["Some members were assigned to duty as follows!"]
        Array.prototype.push.apply(messages, as.getAssignmentsListMsg(as.getAssignmentsList(robot)))

        for message in messages
          msg.send message

        cron.resetAssignCronJobs
        cron.startAssignCronJobs(robot, as.getAssignmentsList(robot))
      )
    catch error
      msg.send error

  regex = "assign list$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    messages = as.getAssignmentsListMsg(as.getAssignmentsList(robot))
    for message in messages
      msg.send message

  regex = "assign reset$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    as.resetAssignmentsList robot
    msg.send "Successfully reset assignment!"

  regex = "assign from [0-9]+$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    id = parseInt(msg.match[0].replace(/\s+/g, " ").split(" ")[3])
    try
      as.setLastAssignedUser(id, robot)
      u = user.getBy("id", id, robot)
      unless u? then throw Error "There are no specified user"
      msg.send "Assign from `#{id}` #{u[0]["name"]} in next assignment!"
    catch error
      msg.send "#{error}"

  regex = "users list$"; regexes.push regex
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

  regex = "users sort by (grade)$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    sortMethod = msg.match[0].replace(/\s+/g, " ").split(" ")[4]
    users = user.getAll(robot)
    unless users?
      msg.send "There are no users. Please regist users by `save me as B4|M1|M2`"
    switch sortMethod
      when "grade"
        users = user.sortUsersByGrade(users)
    user.save(users, robot)
    msg.send "Users were sorted by grade!"

  regex = "users swap [0-9]+ [0-9]+$"
  robot.respond "/"+regex+"/", (msg) ->
    id1 = parseInt(msg.match[0].replace(/\s+/g, " ").split(" ")[3])
    id2 = parseInt(msg.match[0].replace(/\s+/g, " ").split(" ")[4])
    try
      user.swap(id1,id2,robot)
      msg.send "Swapped user #{id1} and #{id2}!"
    catch error
      msg.send "#{error}"

  regex = "save me as (B4|M1|M2)$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    name  = msg.envelope.user.name
    grade = msg.match[0].replace(/\s+/g, " ").split(" ")[4]
    user_info = {
      "name": name,
      "grade": grade
    }
    try
      user.set(user_info, robot)
      msg.send "Save #{name} as #{grade}!"
    catch error
      msg.send "#{error}"

  regex = "update [0-9]+ : (.+) > (.+)$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    id   = parseInt(msg.match[0].split(" ")[2])
    prop = msg.match[0].replace(/\s+/g, " ").split(" ")[4]
    val  = msg.match[0].replace(/\s+/g, " ").split(" ")[6]
    try
      user.update(id, prop, val, robot)
      msg.send "Successfully updated!"
    catch error
      msg.send "#{error}"

  regex = "remove [0-9]+$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    id = parseInt(msg.match[0].replace(/\s+/g, " ").split(" ")[2])
    try
      user.remove(id, robot)
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
