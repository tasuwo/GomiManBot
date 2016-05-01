user = require("./user.coffee")

LAST_ASSIGNED_USER_KEY = 'last_assigned_user'

exports.getLastAssignedUserName = (robot) ->
  return robot.brain.get(LAST_ASSIGNED_USER_KEY)

exports.setLastAssignedUserName = (user, robot) ->
  robot.brain.set(LAST_ASSIGNED_USER_KEY, user)

assign = (users, dates, lastAssignedUserName) ->
  startIndex = user.getIndexByName(lastAssignedUserName, users)+1
  dutyMembers = extractDutyMembers(startIndex, Object.keys(dates).length, users)
  assignment = []
  keys = Object.keys(dates)
  for i in [0...keys.length]
    dateAssignment = []
    dateAssignment["date"] = keys[i]
    dateAssignment["duty"] = dates[keys[i]][0]
    dateAssignment["assign"] = dutyMembers[i]["name"]
    assignment.push(dateAssignment)
  return assignment
exports.assign = assign

extractDutyMembers = (startIndex, nMember, users) ->
  #          head
  #        |------|
  #               loop
  #        |-----------------|
  #                   tail
  #                |---------|
  # users |1|2|...|m|...|n-1|n|
  dutyMembers = []
  nTail = users.length - startIndex
  Array.prototype.push.apply(dutyMembers, users.slice(startIndex,users.length))
  if nMember - nTail > 0
    nExtraUsers = nMember - nTail
    nLoop = parseInt(nExtraUsers/users.length)
    nHead = parseInt(nExtraUsers%users.length)
    if nLoop != 0
      for i in [0...nLoop]
        Array.prototype.push.apply(dutyMembers, users)
    if nHead != 0
      Array.prototype.push.apply(dutyMembers, users.slice(0, nHead))
  return dutyMembers
exports.extractDutyMembers = extractDutyMembers
