as = require('./assignment.coffee')
cronJob = require('cron').CronJob
logger = require('./logger.coffee')
LOG_FNAME = 'cron.log'
exports.LOG_FNAME = LOG_FNAME
writer = logger.getWriter('debug', LOG_FNAME)

assignCronJobs = []
NOTIFY_CHANNEL = "norify channel"

exports.sendMessage = (robot, envelope, msg) ->
  robot.send envelope, msg

exports.setNotifyChannel = (channel, robot) ->
  # TODO: Check channel existence
  robot.brain.set(NOTIFY_CHANNEL, channel)

exports.getNotifyChannel = (robot) ->
  return robot.brain.get(NOTIFY_CHANNEL)

exports.resetAssignCronJobs = () ->
  if assignCronJobs.length >0
    for job in assignCronJobs
      job.stop()
    assignCronJobs = []

exports.getAssignCronJobsState = (state) ->
  if assignCronJobs == []
    return ["There are no cron jobs"]
  else
    msg = []
    for job in assignCronJobs
      msg.push job

exports.translateDateToCronSetting = (date) ->
  if date.split("-").length != 3
    throw Error "Invalid arguement"
  # node-cron では Months は 0-11 なので，1を引いておく
  month = parseInt(date.split("-")[1]) - 1
  day   = parseInt(date.split("-")[2])
  return '0 0 12 ' + day + ' ' + month + ' *'

# exports.translateCronSettingToDate = (cronSetting) ->
#   if cronSetting.split(" ").length != 6
#     throw Error "Invalid arguement"
#   # node-cron では Months は 0-11 なので，1を足しておく
#   month = parseInt(cronSetting.split(" ")[4]) + 1
#   day   = parseInt(cronSetting.split(" ")[3])
#   return "#{month}/#{day}"

exports.decrementDayOfCronSetting = (cronSetting) ->
  settings = cronSetting.split(" ")
  if settings.length != 6
    throw Error "Invalid arguement"
  day   = parseInt(settings[3])
  month = parseInt(settings[4])
  # 月ごとの最終日を考慮するのが面倒なので，最小にあわせておく
  settings[3] = if day>1 then day-1 else 29
  if day == 1
    # node-cron では Months は 0-11
    settings[4] = if month==0 then 11 else month-1
  return settings.join(" ")

exports.startJobs = (robot) ->
  new cronJob('0 0 12 1 */1 *', () =>
    envelope = room: (this.getNotifyChannel(robot) or "develop")
    messages = [ "@channel Check!" ]
    as.assign(robot, (resultMsgs, err) ->
      if err
        this.sendMessage(robot, envelope, "Error: " + err + ", so cannnot extcute cron job")
      for resultMsg in resultMsgs
        messages.push resultMsg
      for message in messages
        this.sendMessage(robot, envelope, message)
    )
  ).start()

exports.startAssignCronJobs = (robot, assignments) ->
  unless assignments?
    throw Error "There are no assignment for creating cron jobs"
  this.resetAssignCronJobs()
  for assignment in assignments
    assignedDate = this.translateDateToCronSetting(assignment["date"])
    notifiedDate = this.decrementDayOfCronSetting(assignedDate)
    assignCronJobs.push(
      new cronJob(notifiedDate, () =>
        envelope = room: (this.getNotifyChannel(robot) or "develop")
        this.sendMessage(robot, envelope, "@"+assignment["assign"]+" You are assigned to duty in tommorow")
      )
    )
    writer.info('Save cron job! date:%s, to:%s', notifiedDate, assignment["assign"])
  for job in assignCronJobs
    job.start()
