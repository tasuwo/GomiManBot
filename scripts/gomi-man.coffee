# Description:
#   Utility commands surrounding Hubot uptime.
#
# Commands:
#   hubot ping - Reply with pong
#   hubot echo <text> - Reply back with <text>
#   hubot time - Reply with current time
#   hubot die - End hubot process

calendar = require("./google-calendar.coffee")
assign = require("./assignment.coffee")
user = require("./user.coffee")
async = require("async")

module.exports = (robot) ->

  robot.respond /duty roster/i, (msg) ->
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
      lastUserName = assign.getLastAssignedUserName(robot) or users[0]["name"]
      assigns      = assign.assign(users, dates, lastUserName)
      console.log(assigns)
      assign.setLastAssignedUserName(assigns[assigns.length-1]["assign"],robot)
    , (err, val) ->
      return
    ]

  robot.respond /list/i, (msg) ->
    users = user.getAll(robot)
    users.forEach((user) ->
      name = user["name"]
      msg.send "id:#{user["id"]} : name:#{user["name"]} : grade:#{user["grade"]}"
    )

  robot.respond /save me as (B4|M1|M2)/i, (msg) ->
    name = msg.envelope.user.name
    grade = msg.match[0].split(" ")[4]
    user_info = {
      "name": name,
      "grade": grade
    }
    user.set(user_info, robot)
    msg.send "save #{name} as #{grade}"

  robot.respond /update (.+) : (.+) > (.+)/i, (msg) ->
    id = msg.match[0].split(" ")[2]
    prop = msg.match[0].split(" ")[4]
    val = msg.match[0].split(" ")[6]
    if user.update(id, prop, val, robot) == null
      msg.send "Fail to update..."
    else
      msg.send "Successfully updated!"

  robot.respond /remove (.+)/i, (msg) ->
    id = msg.match[0].split(" ")[2]
    if user.remove(id, robot) == null
      msg.send "Fail to delete..."
    else
      msg.send "Successfully deleted!"
