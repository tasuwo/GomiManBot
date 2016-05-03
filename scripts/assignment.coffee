calendar = require("./google-calendar.coffee")
scheduler = require("./scheduler.coffee")
user = require("./user.coffee")
async = require("async")

ASSIGNMENTS_KEY = 'assignments_key'
LAST_ASSIGNED_MONTH = 'last_assigned_month'

getAssignmentsList = (robot) ->
  return robot.brain.get(ASSIGNMENTS_KEY) or null
exports.getAssignmentsList = getAssignmentsList

getAssignmentsListMsg = (robot) ->
  assignments = getAssignmentsList robot
  unless assignments?
    return [ "There are no assignments. Please
    assign users to duty by `assign members` command." ]
  msg = []
  for assignment in assignments
    date = assignment["date"]
    duty = assignment["duty"]
    assign = assignment["assign"]
    msg.push "date:#{date}, duty:#{duty}, assign:#{assign}"
  return msg

assign = (robot, _callback) ->
  async.waterfall [
    (callback) ->
      calendar.authorize(robot,
        (oauth2Client) ->
          callback null, oauth2Client
      )
      return
  , (auth, callback) ->
    unless auth?
      throw Error "Failed to authorize API"
    calendar.getEvents(auth, ["clean"], (dates) -> callback null, dates)
  , (dates, callback) ->
    unless dates?
      throw Error "There are no events on calendar for assignment"
    keys            = Object.keys(dates)
    thisMonth       = keys[0].split("-")[0]
    willAssignMonth = robot.brain.get(LAST_ASSIGNED_MONTH) or ""
    if thisMonth == willAssignMonth
      msg = []
      msg.push "Assignment of this month has perfomed as follows"
      Array.prototype.push.apply(msg, getAssignmentsListMsg(robot))
      callback null, [], msg, true
      return

    users = user.getAll(robot)
    unless users?
      throw Error "There are no users for assignment"
    lastUserName = scheduler.getLastAssignedUserName(robot) or users[0]["name"]
    try
      assignments  = scheduler.assign(users, dates, lastUserName)

      robot.brain.set(ASSIGNMENTS_KEY, assignments)
      scheduler.setLastAssignedUserName(assignments[assignments.length-1]["assign"],robot)
      robot.brain.set(LAST_ASSIGNED_MONTH, thisMonth)

      callback null, assignments, "", false
    catch error
      throw Error error
  ], (err, assignments, message, preStoredflg) ->
    if err
      throw Error error

    if preStoredflg
      _callback message
    else
      msg = []
      msg.push "Some members were assigned to duty as follows!"
      for assignment in assignments
        date   = assignment["date"]
        duty   = assignment["duty"]
        member = assignment["assign"]
        msg.push "date:#{date}, duty:#{duty}, member:#{member}"
      _callback msg
exports.assign = assign
