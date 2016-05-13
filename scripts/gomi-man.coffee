# Description
#   Assign users to duty on google api
#
# Configuration:
#   None
#
# Commands:
#   auth get url - Get url to retrieve authorization code
#   auth with <code> - Retrive access token and store it with authorization code
#   assign users - Retrive duties from google calendar and assign users to them
#   assign reset - Reset assignments
#   assign list - Assignments list
#   assign from <uid> - Set user who will be assigned to duty at first in next assignment
#   channel set <name> - Set notification channel (default: develop)
#   channel check - Check norification channel
#   users list - Show users saved in this app
#   users sort by <method> - Sort user based on method. (method: grade)
#   users swap <id> <id> - Swap user position in the list
#   save (me|<name>) as <prop>:<val>, ... - Save user who has specified name and property and value pair
#   update <id> : <prop> > <value> - Update specified user's <property>'s value to <value>
#   remove <id> - Remove specified user
#
# Author:
#   tasuwo <kamuhata.you@gmail.com>

api = require("./googleapi.coffee")
user = require("./user.coffee")
async = require("async")
cron = require("./cron.coffee")
as = require("./assignment.coffee")
request = require("request")

module.exports = (robot) ->
  regexes = []
  cron.startJobs(robot)

  # TODO : set automatically when bot is invited
  regex = "channel set (.+)$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    channel = msg.match[0].replace(/\s+/g, " ").split(" ")[3]
    cron.setNotifyChannel(channel, robot)
    msg.send "I'll send notification to channel: ##{channel}!"

  regex = "channel check$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    channel = cron.getNotifyChannel(robot)
    unless channel?
      msg.send "No channel registered. Please save channel by `channel
  set <channel name>` command."
      return
    msg.send "Notify channel is set to ##{channel}"

  regex = "auth auto$"; regexes.push regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    url = api.getAuthUrl()
    params = api.parseUrl(url)
    decodeParams = []
    for key, value of params
      decodeParams[key] = decodeURIComponent(value)

    request {
      url: "https://accounts.google.com/o/oauth2/auth",
      qs: decodeParams
    }, (err, res, body) ->
      if err then console.log(err); return
      console.log(res)

  regex = "auth get url$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    msg.send do api.getAuthUrlMsg

  regex = "auth with (.+)$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    code = msg.match[0].replace(/\s+/g, " ").split(" ")[3]
    api.getNewToken code, (res, err) ->
      if err
        msg.send err; return
      msg.send res
    , robot

  regex = "assign users$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    try
      as.assign(robot, (err, preStoredFlg) ->
        if err
          msg.send err
          return
        messages = if preStoredFlg
        then ["Assignment of this month has perfomed as follows"]
        else ["Some members were assigned to duty as follows!"]
        Array.prototype.push.apply(messages, as.getAssignmentsListMsg(as.getAssignmentsList(robot)))

        for message in messages
          msg.send message

        cron.resetAssignCronJobs
        cron.startAssignCronJobs(robot, as.getAssignmentsList(robot))
      )
    catch error
      msg.send error

  regex = "assign list$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    messages = as.getAssignmentsListMsg(as.getAssignmentsList(robot))
    for message in messages
      msg.send message

  regex = "assign reset$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    as.resetAssignmentsList robot
    msg.send "Successfully reset assignment!"

  regex = "assign from [0-9]+$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    id = parseInt(msg.match[0].replace(/\s+/g, " ").split(" ")[3])
    try
      as.setLastAssignedUser(id, robot)
      u = user.getBy("id", id, robot)
      unless u? then throw Error "There are no specified user"
      msg.send "Assign from `#{id}` #{u[0]["name"]} in next assignment!"
    catch error
      msg.send "#{error}"

  regex = "users list$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    users = user.getAll(robot)
    unless users?
      msg.send "There are no users. Please regist users by `save
  (me|<name>) as <prop>:<val>, ...`"
      return
    msg.send "Registerd users are as follows..."
    users.forEach((user) ->
      list_str = "`#{user["id"]}`"
      for key, value of user
        if key=="id" then continue
        list_str = list_str + " #{key}:#{user[key]},"
      list_str = list_str.substr(0, list_str.length-1)
      msg.send list_str
    )

  regex = "users sort by (grade)$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    sortMethod = msg.match[0].replace(/\s+/g, " ").split(" ")[4]
    users = user.getAll(robot)
    unless users?
      msg.send "There are no users. Please regist users by `save
  (me|<name>) as <prop>:<val>, ...`"
    switch sortMethod
      when "grade"
        users = user.sortUsersByGrade(users)
    user.save(users, robot)
    msg.send "Users were sorted by grade!"

  regex = "users swap [0-9]+ [0-9]+$"
  robot.respond "/"+regex+"/", (msg) ->
    id1 = parseInt(msg.match[0].replace(/\s+/g, " ").split(" ")[3])
    id2 = parseInt(msg.match[0].replace(/\s+/g, " ").split(" ")[4])
    try
      user.swap(id1,id2,robot)
      msg.send "Swapped user #{id1} and #{id2}!"
    catch error
      msg.send "#{error}"

  regex = "save (me|.+) as (.+):(.+)(, (.+):(.+))*$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    saver_name  = msg.envelope.user.name
    if saver_name == "me"
      msg.send "Your name 'me' means 'yourself' for me... please rename"
      return
    msg_array = msg.match[0].replace(/\s+/g, " ").split(" ")
    saved_name = if msg_array[2]=="me" then saver_name else msg_array[2]
    n_props = msg_array.length - 4 # [hubot, save, <name>, as].length == 4
    props = []
    props["name"] = saved_name
    for i in [0...n_props]
      prop_str = msg_array[4+i].replace(/,/g, "").split(":")
      if prop_str[0]=="id"
        msg.send "Cannot set id"
        return
      props[prop_str[0]] = prop_str[1]
    try
      user.set(props, robot)
      msg.send "Save #{saved_name}!"
    catch error
      msg.send "#{error}"

  regex = "update [0-9]+ : (.+) > (.+)$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    id   = parseInt(msg.match[0].split(" ")[2])
    prop = msg.match[0].replace(/\s+/g, " ").split(" ")[4]
    val  = msg.match[0].replace(/\s+/g, " ").split(" ")[6]
    try
      user.update(id, prop, val, robot)
      msg.send "Successfully updated!"
    catch error
      msg.send "#{error}"

  regex = "remove [0-9]+$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    id = parseInt(msg.match[0].replace(/\s+/g, " ").split(" ")[2])
    try
      user.remove(id, robot)
      msg.send "Successfully removed!"
    catch error
      msg.send "#{error}"

  # TODO: Intelligence match
  robot.hear new RegExp("^@gomi-man-bot: (?!("+regexes.join("|")+"))", "g"), (msg) ->
    msg.send msg.random [
      "I don't understand.",
      "Sorry, #{msg.envelope.user.name}, I didn't get that.",
      "That does not compute, #{msg.envelope.user.name}."
    ]
