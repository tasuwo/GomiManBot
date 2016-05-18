api = require("./googleapi.coffee")
User = require("./user.coffee").User
async = require("async")

class Assignment
  @LIST_KEY = 'assignments_key'
  @LAST_MONTH_KEY = 'last_assigned_month'
  @LAST_USER_KEY = 'last_assigned_user'

  constructor: (robot) ->
    @robot = robot
    @user = new User(robot)

  save: (assignments, dates) ->
    unless assignments?
      return
    this.setList(assignments)
    @robot.brain.set(
      Assignment.LAST_USER_KEY,
      assignments[assignments.length-1]["assign"])
    @robot.brain.set(
      Assignment.LAST_MONTH_KEY,
      parseInt(Object.keys(dates)[0].split("-")[1]))

  setList: (assignments) ->
    unless assignments?
      return
    i = 1
    assignments.map (assignment) ->
      assignment["id"] = i++
    @robot.brain.set Assignment.LIST_KEY, assignments

  getList: () ->
    @robot.brain.get Assignment.LIST_KEY or null

  getLastMonth: () ->
    @robot.brain.get Assignment.LAST_MONTH_KEY

  getLastUser: () ->
    @robot.brain.get Assignment.USERS_KEY

  setLastUserBy: (id) ->
    unless @user.getBy("id", id)?
      throw Error "There are no specified user"
    @robot.brain.set(Assignment.USERS_KEY, id)

  reset: () ->
    @robot.brain.set Assignment.LIST_KEY, null
    @robot.brain.set Assignment.LAST_MONTH_KEY, null

  swap: (id1, id2) ->
    assignments = this.getList()
    unless assignments?
      return [ "There are no assignments. Please assign users to duty by `assign users` command." ]
    tmp = assignments[id1-1]["assign"]
    assignments[id1-1]["assign"] = assignments[id2-1]["assign"]
    assignments[id2-1]["assign"] = tmp
    this.setList(assignments)

  generateStringForm: (assignments) ->
    unless assignments?
      return [ "There are no assignments. Please assign users to duty by `assign users` command." ]
    msg = []
    for assignment in assignments
      id     = assignment["id"]
      date   = assignment["date"]
      duty   = assignment["duty"]
      member = assignment["assign"]
      msg.push "`#{id}` date:#{date}, duty:#{duty}, member:#{member}"
    return msg

  assign: (callback) ->
    # TODO: replace async with generator
    async.waterfall [
      (next) =>
        api.authorize(@robot, (oauth2Client, err) ->
          if err?
            next err
            return
          unless oauth2Client?
            next "Failed to authorize API"
            return
          next null, oauth2Client
        )
    , (auth, next) =>
      api.getEvents(auth, ["clean"], (dates) ->
        unless dates?
          next "There are no events on calendar for assignment"
          return
        next null, dates
      )
    , (dates, next) =>
      if parseInt(Object.keys(dates)[0].split("-")[1]) == (this.getLastMonth() or "")
        next null, true; return

      users = @user.getAll()
      unless users?
        next "There are no users for assignment"
        return
      lastAssignedUserId = this.getLastUser() or 1
      assignments = this.createList(users, dates, lastAssignedUserId)
      this.save(assignments, dates)
      next null, false
    ], (err, preStoredflg) ->
      callback err, preStoredflg

  createList: (users, dateAndDuties, lastAssignedUserId) ->
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

    assignments = []
    for i in [0...nMembers]
      date = dates[i]
      duty = dateAndDuties[date][0]
      assignmentOfEachDate = new Object()
      assignmentOfEachDate["date"]   = date
      assignmentOfEachDate["duty"]   = duty
      assignmentOfEachDate["assign"] = assignedMembers[i]["name"]
      assignments.push(assignmentOfEachDate)
    assignments

  extractUsersInOrder: (startIndex, nMember, users) ->
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
    assignedMembers

module.exports = Assignment
