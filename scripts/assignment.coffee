api = require("./googleapi.coffee")
user = require("./user.coffee")
async = require("async")
cron = require("./cron.coffee")

ASSIGNMENTS_KEY = 'assignments_key'
LAST_ASSIGNED_MONTH = 'last_assigned_month'
LAST_ASSIGNED_USER_KEY = 'last_assigned_user'

exports.saveAssignments = (assignments, dates, robot) ->
  if assignments?
    this.setAssignmentsList(assignments, robot)
    robot.brain.set(LAST_ASSIGNED_USER_KEY, assignments[assignments.length-1]["assign"])
    robot.brain.set(LAST_ASSIGNED_MONTH, parseInt(Object.keys(dates)[0].split("-")[1]))

exports.setAssignmentsList = (assignments, robot) ->
  if assignments?
    i = 1
    assignments.map (el) ->
      el["id"] = i++
    robot.brain.set(ASSIGNMENTS_KEY, assignments)

exports.getAssignmentsList = (robot) ->
  return robot.brain.get(ASSIGNMENTS_KEY) or null

exports.getLastAssignedMonth = (robot) ->
  return robot.brain.get(LAST_ASSIGNED_MONTH)

exports.getLastAssignedUser = (robot) ->
  return robot.brain.get(LAST_ASSIGNED_USER_KEY)

exports.setLastAssignedUser = (id, robot) ->
  unless user.getBy("id",id,robot)?
    throw Error "There are no specified user"
  robot.brain.set(LAST_ASSIGNED_USER_KEY, id)

exports.resetAssignmentsList = (robot) ->
  robot.brain.set(ASSIGNMENTS_KEY, null)
  robot.brain.set(LAST_ASSIGNED_MONTH, null)

exports.swap = (id1, id2, robot) ->
  assignments = this.getAssignmentsList(robot)
  unless assignments?
    return [ "There are no assignments. Please assign users to duty by `assign users` command." ]
  tmp = assignments[id1]
  assignments[id1] = assignments[id2]
  assignments[id2] = tmp
  this.setAssignmentsList(assignments, robot)

exports.getAssignmentsListMsg = (assignments) ->
  unless assignments?
    return [ "There are no assignments. Please assign users to duty by `assign users` command." ]
  msg = ["Assignments list is following"]
  for assignment in assignments
    id     = assignment["id"]
    date   = assignment["date"]
    duty   = assignment["duty"]
    member = assignment["assign"]
    msg.push "`#{id}` date:#{date}, duty:#{duty}, member:#{member}"
  return msg

exports.assign = (robot, callback) ->
  # TODO: replace async with generator
  async.waterfall [
    (next) =>
      api.authorize(robot, (oauth2Client, err) ->
        if err?
          next err; return
        unless oauth2Client?
          next "Failed to authorize API"; return
        next null, oauth2Client
      )
  , (auth, next) =>
    api.getEvents(auth, ["clean"], (dates) ->
      unless dates?
        next "There are no events on calendar for assignment"; return
      next null, dates
    )
  , (dates, next) =>
    if parseInt(Object.keys(dates)[0].split("-")[1]) == (this.getLastAssignedMonth(robot) or "")
      next null, true; return

    users = user.getAll(robot)
    unless users?
      next "There are no users for assignment"; return
    lastAssignedUserId = this.getLastAssignedUser(robot) or 1
    assignments = this.createAssignmentsList(users, dates, lastAssignedUserId)
    this.saveAssignments(assignments, dates, robot)
    next null, false
  ], (err, preStoredflg) ->
    callback err, preStoredflg

exports.createAssignmentsList = (users, dateAndDuties, lastAssignedUserId) ->
  unless users? || dateAndDuties?
    throw Error "Invalid arguement : some arguements are empty"
  if users == [] || dateAndDuties == []
    throw Error "Invalid arguement : some arguements are empty"

  dates = Object.keys(dateAndDuties)
  nMembers = dates.length
  assignedMembers = null
  try
    startIndex = lastAssignedUserId-1
    assignedMembers = this.extractUsersInOrder(startIndex, nMembers, users)
  catch error
    throw Error error

  assignments = new Object()
  for i in [0...nMembers]
    date = dates[i]
    duty = dateAndDuties[date][0]
    assignmentOfEachDate = []
    assignmentOfEachDate["date"]   = date
    assignmentOfEachDate["duty"]   = duty
    assignmentOfEachDate["assign"] = assignedMembers[i]["name"]
    assignments.push(assignmentOfEachDate)
  return assignments

exports.extractUsersInOrder = (startIndex, nMember, users) ->
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
