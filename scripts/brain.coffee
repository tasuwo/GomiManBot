uuid = require "./uuid.coffee"

module.exports = (robot) ->
  USERS_KEY = 'users'

  getUsers = () ->
    return robot.brain.get(USERS_KEY) or []

  getUser = (id) ->
    users = getUsers()
    result = null
    users.forEach((user, index) ->
      if id == user["id"]
        result = [user, index]
    )
    return result

  setUser = (user_info) ->
    user_info["id"] = uuid.generate()
    users = getUsers()
    users.push(user_info)
    robot.brain.set(USERS_KEY, users)

  updateUser = (id, prop, value) ->
    info = getUser(id)
    if info == null
      return null
    user = info[0]
    index = info[1]
    # TODO: prop がないかどうかの判断
    # if prop in user
    user[prop] = value
    users = getUsers()
    users[index] = user
    robot.brain.set(USERS_KEY, users)
    return
    # return null

  deleteUser = (id) ->
    info = getUser(id)
    if info == null
      return null
    users = getUsers()
    delete users[info[1]]
    robot.brain.set(USERS_KEY, users)
    return

  robot.respond /list/i, (msg) ->
    users = getUsers()
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
    setUser(user_info)
    msg.send "save #{name} as #{grade}"

  robot.respond /update (.+) : (.+) > (.+)/i, (msg) ->
    id = msg.match[0].split(" ")[2]
    prop = msg.match[0].split(" ")[4]
    val = msg.match[0].split(" ")[6]
    if updateUser(id, prop, val) == null
      msg.send "Fail to update..."
    else
      msg.send "Successfully updated!"

  robot.respond /delete (.+)/i, (msg) ->
    id = msg.match[0].split(" ")[2]
    if deleteUser(id) == null
      msg.send "Fail to delete..."
    else
      msg.send "Successfully deleted!"
