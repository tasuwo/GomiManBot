module.exports = (robot) ->
  USERS_KEY = 'users'
  MAX_ID_KEY = 'max_id'

  getMaxId = () ->
    return robot.brain.get(MAX_ID_KEY) or 0

  getUsers = () ->
    return robot.brain.get(USERS_KEY) or []

  setUser = (user_info) ->
    user_info["id"] = getMaxId()+1
    users = getUsers()
    users.push(user_info)
    console.log(users)
    robot.brain.set(USERS_KEY, users)

  robot.respond /list/i, (msg) ->
    users = getUsers()
    console.log(users)
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
    msg.send "save!!"

