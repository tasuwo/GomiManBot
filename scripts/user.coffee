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
  # unless user[prop]?
  #   throw Error "Assigned property doesn't exist"
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

exports.sortUsersByStNo = (users) ->
  unless users?
    throw Error "Users are empty"
  usersList = []
  for user in users
    unless "stNo" of user
      throw Error "Some users doesn't have property 'stNo'"
    usersList.push(new this.StudentNumber(user["stNo"]))
  sortedUsers = []
  sortedStNumbers = bubbleSort(usersList)
  for stNo in sortedStNumbers
    for user in users
      if user["stNo"]==stNo.str
        sortedUsers.push user
        break
  return sortedUsers.reverse()

# TODO: clean code
bubbleSort = (array) ->
  return array  if not Array.isArray(array) or array.length < 2
  swap = (array, first, second) ->
    temp = array[first]
    array[first] = array[second]
    array[second] = temp
    array
  i = undefined
  l = undefined
  i = 0
  while i < array.length
    l = i
    swap array, l, l + 1  while l-- and array[l].earlierThan array[l + 1]
    i++
  array

exports.StudentNumber = class StudentNumber
  constructor: (stNo) ->
    if res = this.matchBStNo stNo
      @str    = res[0]
      @degree = "bachelor"
      @year   = parseInt(res[1])
      @no     = parseInt(res[3])
    else if res = this.matchMStNo stNo
      @str    = res[0]
      @degree = "master"
      @year   = parseInt(res[1])
      @no     = parseInt(res[3])
    else
      @degree = null

  compareTo: (stNo) =>
    unless stNo instanceof StudentNumber
      throw Error "Invarid arguement"
    return @degree==stNo.degree && @year==stNo.year && @no==stNo.no

  earlierThan: (stNo) =>
    unless stNo instanceof StudentNumber
      throw Error "Invarid arguement"
    if this.compareTo stNo
      return false
    if @degree != stNo.degree
      if @degree=="master"
        return false
      else
        return true
    else
      if @year!=stNo.year
        return @year>stNo.year
      else
        return @no<stNo.no


  matchBStNo: (stNo) =>
    bRegex = ///^
      ([0-9]{2})
      (T|t)
      ([0-9]{4})
      ([a-zA-Z]{1})
      $///i
    return stNo.match bRegex

  matchMStNo: (stNo) =>
    mRegex = ///^
      ([0-9]{2})
      (NM|nm)
      ([0-9]{3})
      ([a-zA-Z]{1})
      $///i
    return stNo.match mRegex
