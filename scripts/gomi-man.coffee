# Description:
#   Utility commands surrounding Hubot uptime.

calendar = require("./google-calendar.coffee")
scheduler = require("./scheduler.coffee")
user = require("./user.coffee")
async = require("async")
ASSIGNMENTS_KEY = 'assignments_key'
LAST_ASSIGNED_MONTH = 'last_assigned_month'

showAssignmentsList = (msg, robot) ->
  assignments = robot.brain.get(ASSIGNMENTS_KEY) or null
  unless assignments?
    msg.send "There are no assignments. Please
    assign users to duty by `assign members` command."
    return
  for assignment in assignments
    date = assignment["date"]
    duty = assignment["duty"]
    assign = assignment["assign"]
    msg.send "date:#{date}, duty:#{duty}, assign:#{assign}"

module.exports = (robot) ->
  robot.respond /assign/i, (msg) ->
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
      keys = Object.keys(dates)
      thisMonth       = keys[0].split("-")[0]
      willAssignMonth = robot.brain.get(LAST_ASSIGNED_MONTH) or ""
      if thisMonth == willAssignMonth
        msg.send "Assignment of this month has perfomed as follows"
        showAssignmentsList msg, robot
        return

      users        = user.getAll(robot)
      lastUserName = scheduler.getLastAssignedUserName(robot) or users[0]["name"]
      try
        assignments  = scheduler.assign(users, dates, lastUserName)

        robot.brain.set(ASSIGNMENTS_KEY, assignments)
        scheduler.setLastAssignedUserName(assignments[assignments.length-1]["assign"],robot)
        robot.brain.set(LAST_ASSIGNED_MONTH, thisMonth)

        callback null, assignments
      catch error
        throw Error error
    ], (err, assignments) ->
      if err
        msg.send "#{err}"
      msg.send "Some members were assigned to duty as follows!"
      for assignment in assignments
        date = assignment["date"]
        duty = assignment["duty"]
        assign = assignment["assign"]
        msg.send "date:#{date}, duty:#{duty}, assign:#{assign}"


  robot.respond /assign list/i, (msg) ->
    showAssignmentsList msg, robot


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
