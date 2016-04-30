calendar = require("./google-calendar.coffee")
user = require("./user.coffee")

module.exports = (robot) ->

  robot.respond /duty roster/i, (msg) ->
    auth = calendar.authorize(robot)
    unless auth?
      msg.send "Error occured"
      return
    console.log(calendar.getEvents(auth, ["clean"]))

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
