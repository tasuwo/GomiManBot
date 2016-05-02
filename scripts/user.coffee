uuid = require "./uuid.coffee"

USERS_KEY = 'users'


getAll = (robot) ->
  return robot.brain.get(USERS_KEY) or null
exports.getAll = getAll


getByName = (name, robot) ->
  result = null
  users = getAll(robot)
  if users?
    users.forEach((user, index) ->
      if name == user["name"]
        result = [user, index]
    )
  return result
exports.getByName = getByName


set = (user_info, robot) ->
  if getByName(user_info["name"], robot)?
    throw Error "User name is duplicate"

  users = getAll(robot) or []
  users.push(user_info)
  robot.brain.set(USERS_KEY, users)
exports.set = set


update = (name, prop, value, robot) ->
  update_user_info = getByName(name, robot)
  user  = update_user_info[0]
  index = update_user_info[1]
  if prop=="name" && getByName(value, robot)?
    throw Error "User name is duplicate"

  unless user[prop]?
    throw Error "Assigned property doesn't exist"
  user[prop] = value

  users = getAll(robot)
  users[index] = user
  robot.brain.set(USERS_KEY, users)
exports.update = update


remove = (name, robot) ->
  remove_user_info = getByName(name, robot)
  unless remove_user_info?
    throw Error "Assigned user name doesn't exist"
  index = remove_user_info[1]

  users = getAll(robot)
  delete users.splice(index,1)
  if users.length == 0 then users = null
  robot.brain.set(USERS_KEY, users)
exports.remove = remove


getIndexByName = (name, users) ->
  for user, index in users
    if user["name"] == name
      return index
  return null
exports.getIndexByName = getIndexByName
