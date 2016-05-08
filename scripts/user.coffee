USERS_KEY = 'users'

exports.getAll = (robot) ->
  return robot.brain.get(USERS_KEY) or null

exports.save = (users, robot) ->
  if users?
    #users = this.sortUsersByGrade(users)
    i = 1
    users.map (el) ->
      el["id"] = i++
  robot.brain.set(USERS_KEY, users)

exports.getBy = (property, value, robot) ->
  # 一意にユーザを識別するプロパティのみ指定可
  unless property == "name" || property == "id"
    return null
  users = this.getAll(robot)
  unless users?
    return null
  result = null
  users.forEach (user, index) ->
    if value == user[property]
      result = [user, index]
  return result

exports.set = (user_info, robot) ->
  if this.getBy("name", user_info["name"], robot)?
    throw Error "User name is duplicate"
  users = this.getAll(robot) or []
  users.push(user_info)
  this.save(users, robot)

exports.update = (id, prop, value, robot) ->
  if prop=="name" && this.getBy("name", value, robot)?
    throw Error "User name is duplicate"
  if prop=="id"
    throw Error "Cannot set id"
  update_user_info = this.getBy("id", id, robot)
  unless update_user_info?
    throw Error "There are no specified user"
  user  = update_user_info[0]
  index = update_user_info[1]
  unless user[prop]?
    throw Error "Assigned property doesn't exist"
  user[prop] = value
  users = this.getAll(robot)
  users[index] = user
  this.save(users, robot)

exports.remove = (id, robot) ->
  remove_user_info = this.getBy("id", id, robot)
  unless remove_user_info?
    throw Error "Assigned user name doesn't exist"
  index = remove_user_info[1]
  users = this.getAll(robot)
  delete users.splice(index,1)
  if users.length == 0
    users = null
  this.save(users, robot)

exports.swap = (id1, id2, robot) ->
  user1 = this.getBy("id",id1,robot)
  user2 = this.getBy("id",id2,robot)
  unless user1? || user2?
    throw Error "Specified user id doesn't exist"
  index1 = user1[1]
  index2 = user2[1]
  users = this.getAll(robot)
  users[index1] = user2[0]
  users[index2] = user1[0]
  this.save(users, robot)

exports.sortUsersByGrade = (users) ->
  unless users?
    throw Error "Users are empty"
  sortedUsers = []
  b4 = []
  m1 = []
  m2 = []
  for user in users
    switch user["grade"]
      when "B4"
        b4.push(user)
      when "M1"
        m1.push(user)
      when "M2"
        m2.push(user)
      else
        throw Error "Invalid user in users"
  Array.prototype.push.apply(sortedUsers, b4)
  Array.prototype.push.apply(sortedUsers, m1)
  Array.prototype.push.apply(sortedUsers, m2)
  return sortedUsers

