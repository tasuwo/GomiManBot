user = require("./user.coffee")
LAST_ASSIGNED_USER_KEY = 'last_assigned_user'


exports.getLastAssignedUserName = (robot) ->
  return robot.brain.get(LAST_ASSIGNED_USER_KEY)


exports.setLastAssignedUserName = (user, robot) ->
  robot.brain.set(LAST_ASSIGNED_USER_KEY, user)


assign = (users, dateAndDuties, lastAssignedUserName) ->
  unless users? || dateAndDuties? || lastAssignedUserName?
    throw Error "Invalid arguement : some arguements are empty"
  if users == [] || dateAndDuties == []
    throw Error "Invalid arguement : some arguements are empty"
  startIndex      = null
  assignedMembers = null
  try
    startIndex      = user.getIndexByName(lastAssignedUserName, users)+1
    assignedMembers = decideMembersForAssignment(
      startIndex,
      Object.keys(dateAndDuties).length, users
    )
  catch error
    throw Error error

  assignments = []
  key = Object.keys(dateAndDuties)
  for i in [0...key.length]
    date = key[i]
    duty = dateAndDuties[date][0]
    assignmentOfEachDate = []
    assignmentOfEachDate["date"]   = date
    assignmentOfEachDate["duty"]   = duty
    assignmentOfEachDate["assign"] = assignedMembers[i]["name"]
    assignments.push(assignmentOfEachDate)
  return assignments
exports.assign = assign


decideMembersForAssignment = (startIndex, nMember, users) ->
  unless startIndex? || nMember? || users?
    throw Error "Invalid arguement : some arguements are empty"
  if startIndex < 0 || nMember <= 0
    throw Error "Invalid arguement : some arguements' value are invalid"
  #          head
  #        |------|
  #               loop
  #        |-----------------|
  #                   tail
  #                |---------|
  # users |1|2|...|m|...|n-1|n|
  assignedMembers = []
  nTail = users.length - startIndex
  Array.prototype.push.apply(
    assignedMembers,
    users.slice(startIndex,users.length)
  )
  if nMember - nTail > 0
    nExtraUsers = nMember - nTail
    nLoop       = parseInt(nExtraUsers/users.length)
    nHead       = parseInt(nExtraUsers%users.length)
    if nLoop != 0
      for i in [0...nLoop]
        Array.prototype.push.apply(assignedMembers, users)
    if nHead != 0
      Array.prototype.push.apply(assignedMembers, users.slice(0, nHead))
  return assignedMembers
exports.decideMembersForAssignment = decideMembersForAssignment
