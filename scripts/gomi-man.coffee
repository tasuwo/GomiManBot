# Description
#   Assign users to duty on google api
#
# Configuration:
#   None
#
# Commands:
#   auth get url - Get url to retrieve authorization code
#   auth with `code` - Retrive access token and store it with authorization code
#   assign users - Retrive duties from google calendar and assign users to them
#   assign reset - Reset assignments
#   assign list - Assignments list
#   assign swap `id` `id` - Swap users in assignments list
#   assign from `uid` - Set user who will be assigned to duty at first in next assignment
#   channel set `name` - Set notification channel (default: develop)
#   channel check - Check norification channel
#   users list - Show users saved in this app
#   users sort by `method` - Sort user based on method. (method: grade, stNo, reverse)
#   users swap `id` `id` - Swap user position in the list
#   save (me|`name`) as `prop`:`val`, ... - Save user who has specified name and property and value pair
#   users update `id` : `prop` > `value` - Update specified user's <property>'s value to <value>
#   users remove `id` - Remove specified user
#
# Author:
#   tasuwo <kamuhata.you@gmail.com>

api = require("./googleapi.coffee")
user = require("./user.coffee")
async = require("async")
cron = require("./cron.coffee")
as = require("./assignment.coffee")
logger = require("./logger.coffee")

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

        msg.send messages.join("\n")

        cron.startAssignCronJobs(robot, as.getAssignmentsList(robot))
      )
    catch error
      msg.send error

  regex = "assign list$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    messages = as.getAssignmentsListMsg(as.getAssignmentsList(robot))
    msg.send messages.join("\n")

  regex = "assign swap [0-9]+ [0-9]+"
  robot.respond "/"+regex+"/", (msg) ->
    id1 = parseInt(msg.match[0].replace(/\s+/g, " ").split(" ")[3])
    id2 = parseInt(msg.match[0].replace(/\s+/g, " ").split(" ")[4])
    try
      as.swap(id1, id2, robot)
      cron.startAssignCronJobs(robot, as.getAssignmentsList(robot))
      msg.send "Successfully swapped!"
    catch error
      msg.send error

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
      msg.send "There are no users. Please regist users by `save (me|<name>) as <prop>:<val>, ...`"
      return
    messages = ["Registerd users are as follows..."]
    users.forEach((user) ->
      list_str = "`#{user["id"]}`"
      for key, value of user
        if key=="id" then continue
        list_str = list_str + " #{key}:#{user[key]},"
      list_str = list_str.substr(0, list_str.length-1)
      messages.push list_str
    )
    msg.send messages.join("\n")

  regex = "users sort by (.+)$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    sortMethod = msg.match[0].replace(/\s+/g, " ").split(" ")[4]
    users = user.getAll(robot)
    unless users?
      msg.send "There are no users. Please regist users by `save (me|<name>) as <prop>:<val>, ...`"
    switch sortMethod
      when "grade"
        users = user.sortUsersByGrade(users)
      when "stNo"
        users = user.sortUsersByStNo(users)
      when "reverse"
        users = users.reverse()
      else
        msg.send "There are no method for sort"; return
    user.save(users, robot)
    msg.send "Users were sorted by #{sortMethod}!"

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
    props = new Object()
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

  regex = "users update [0-9]+ : (.+) > (.+)$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    id   = parseInt(msg.match[0].split(" ")[3])
    prop = msg.match[0].replace(/\s+/g, " ").split(" ")[5]
    val  = msg.match[0].replace(/\s+/g, " ").split(" ")[7]
    try
      user.update(id, prop, val, robot)
      msg.send "Successfully updated!"
    catch error
      msg.send "#{error}"

  regex = "users remove [0-9]+$"; regexes.push regex
  robot.respond "/"+regex+"/", (msg) ->
    id = parseInt(msg.match[0].replace(/\s+/g, " ").split(" ")[3])
    try
      user.remove(id, robot)
      msg.send "Successfully removed!"
    catch error
      msg.send "#{error}"

  regex = "debug logs (.+)$"
  robot.respond "/"+regex+"/", (msg) ->
    log_kind = msg.match[0].replace(/\s+/g, " ").split(" ")[3]
    reader = null
    switch log_kind
      when "cron"
        log_fname = cron.LOG_FNAME
        reader = logger.getReader('debug', log_fname)
      else
        msg.send "There are no log for #{log_kind}"; return
    reader
      .on 'line', (line) ->
        msg.send line.toString()
        console.log(line)

  # TODO: Intelligence match
  robot.hear new RegExp("^@gomi-man-bot: (?!("+regexes.join("|")+"))", "g"), (msg) ->
    msg.send msg.random [
      "I don't understand.",
      "Sorry, #{msg.envelope.user.name}, I didn't get that.",
      "That does not compute, #{msg.envelope.user.name}."
    ]
