uuid = require "./uuid.coffee"

USERS_KEY = 'users'

getAll = (robot) ->
  return robot.brain.get(USERS_KEY) or []
exports.getAll = getAll

get = (id, robot) ->
  users = getAll(robot)
  result = null
  users.forEach((user, index) ->
    if id == user["id"]
      result = [user, index]
  )
  return result
exports.get = get

set = (user_info, robot) ->
  user_info["id"] = uuid.generate()
  users = getAll(robot)
  users.push(user_info)
  robot.brain.set(USERS_KEY, users)
exports.set = set

update = (id, prop, value, robot) ->
  info = get(id, robot)
  if info == null
    return null
  user = info[0]
  index = info[1]
  # TODO: prop がないかどうかの判断
  # if prop in user
  user[prop] = value
  users = getAll(robot)
  users[index] = user
  robot.brain.set(USERS_KEY, users)
  return
  # return null
exports.update = update

remove = (id, robot) ->
  info = get(id, robot)
  if info == null
    return null
  users = getAll(robot)
  delete users[info[1]]
  robot.brain.set(USERS_KEY, users)
  return
exports.remove = remove

getIndexById = (id, users) ->
  for user, index in users
    if user["id"] == id
      return index
  return null
exports.getIndexById = getIndexById

getIndexByName = (name, users) ->
  for user, index in users
    if user["name"] == name
      return index
  return null
exports.getIndexByName = getIndexByName
