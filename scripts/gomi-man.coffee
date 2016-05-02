# Description:
#   Utility commands surrounding Hubot uptime.

calendar = require("./google-calendar.coffee")
scheduler = require("./scheduler.coffee")
user = require("./user.coffee")
async = require("async")
DUTY_ROSTER_KEY = 'duty_roster_key'

module.exports = (robot) ->


  robot.respond /assign members/i, (msg) ->
    async.waterfall [
      (callback) ->
        calendar.authorize(robot,
          (oauth2Client) ->
            callback null, oauth2Client
        )
        return
    , (auth, callback) ->
      unless auth?
        msg.send "Error occured"
        return
      calendar.getEvents(auth, ["clean"],
        (dates) ->
          callback null, dates
      )
    , (dates, callback) ->
      users        = user.getAll(robot)
      lastUserName = scheduler.getLastAssignedUserName(robot) or users[0]["name"]
      assigns      = scheduler.assign(users, dates, lastUserName)
      robot.brain.set(DUTY_ROSTER_KEY, assigns)
      scheduler.setLastAssignedUserName(assigns[assigns.length-1]["assign"],robot)
      callback null, assigns
    , (assigns, err, val) ->
      msg.send "Some members were assigned to duty roster!"
      msg.send assigns
      return
    ]


  robot.respond /show duty roster/i, (msg) ->
    duty_roster = robot.brain.get(DUTY_ROSTER_KEY) or null
    unless duty_roster?
      msg.send "No members were assigned. Please
    assign members to duty roster by `assign members` command."
      return
    msg.send duty_roster


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
