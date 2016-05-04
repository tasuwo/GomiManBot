calendar = require("./google-calendar.coffee")
scheduler = require("./scheduler.coffee")
user = require("./user.coffee")
async = require("async")

ASSIGNMENTS_KEY = 'assignments_key'
LAST_ASSIGNED_MONTH = 'last_assigned_month'

getAssignmentsList = (robot) ->
  return robot.brain.get(ASSIGNMENTS_KEY) or null
exports.getAssignmentsList = getAssignmentsList

resetAssignmentsList = (robot) ->
  robot.brain.set(ASSIGNMENTS_KEY, null)
  robot.brain.set(LAST_ASSIGNED_MONTH, null)
exports.resetAssignmentsList = resetAssignmentsList

getAssignmentsListMsg = (robot) ->
  assignments = getAssignmentsList robot
  unless assignments?
    return [ "There are no assignments. Please
    assign users to duty by `assign users` command." ]
  msg = []
  for assignment in assignments
    date = assignment["date"]
    duty = assignment["duty"]
    assign = assignment["assign"]
    msg.push "date:#{date}, duty:#{duty}, assign:#{assign}"
  return msg
exports.getAssignmentsListMsg = getAssignmentsListMsg

assign = (robot, _callback) ->
  async.waterfall [
    (callback) ->
      calendar.authorize(robot, (oauth2Client, err) ->
        if err?
          callback err; return
        callback null, oauth2Client
      )
  , (auth, callback) ->
    unless auth?
      callback "Failed to authorize API"; return
    calendar.getEvents(auth, ["clean"], (dates) -> callback null, dates)
  , (dates, callback) ->
    unless dates?
      callback "There are no events on calendar for assignment"; return
    keys            = Object.keys(dates)
    thisMonth       = keys[0].split("-")[0]
    willAssignMonth = robot.brain.get(LAST_ASSIGNED_MONTH) or ""
    if thisMonth == willAssignMonth && getAssignmentsList(robot)?
      msg = []
      msg.push "Assignment of this month has perfomed as follows"
      Array.prototype.push.apply(msg, getAssignmentsListMsg(robot))
      callback null, [], msg, true; return

    users = user.getAll(robot)
    unless users?
      callback "There are no users for assignment"; return
    lastUserName = scheduler.getLastAssignedUserName(robot) or users[0]["name"]
    assignments  = scheduler.assign(users, dates, lastUserName)

    robot.brain.set(ASSIGNMENTS_KEY, assignments)
    scheduler.setLastAssignedUserName(assignments[assignments.length-1]["assign"],robot)
    robot.brain.set(LAST_ASSIGNED_MONTH, thisMonth)

    callback null, assignments, "", false
  ], (err, assignments, message, preStoredflg) ->
    if err
      _callback null, err; return

    if preStoredflg
      _callback message, null
    else
      msg = []
      msg.push "Some members were assigned to duty as follows!"
      for assignment in assignments
        date   = assignment["date"]
        duty   = assignment["duty"]
        member = assignment["assign"]
        msg.push "date:#{date}, duty:#{duty}, member:#{member}"
      _callback msg, null
exports.assign = assign
