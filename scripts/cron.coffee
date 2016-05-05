as = require('./assignment.coffee')
cronJob = require('cron').CronJob

assignCronJobs = []

translateDateToCronSetting = (date) ->
  if date.split("-").length != 3
    throw Error "Invalid arguement"
  month = parseInt(date.split("-")[1])
  day   = parseInt(date.split("-")[2])
  return '0 0 12 ' + day + ' ' + month + ' *'
exports.translateDateToCronSetting = translateDateToCronSetting

translateCronSettingToDate = (cronSetting) ->
  if cronSetting.split(" ").length != 6
    throw Error "Invalid arguement"
  month = parseInt(cronSetting.split(" ")[4])
  day   = parseInt(cronSetting.split(" ")[3])
  return "#{month}/#{day}"
exports.translateCronSettingToDate = translateCronSettingToDate

decrementDayOfCronSetting = (cronSetting) ->
  settings = cronSetting.split(" ")
  if settings.length != 6
    throw Error "Invalid arguement"
  day   = parseInt(settings[3])
  month = parseInt(settings[4])
  # 月ごとの最終日を考慮するのが面倒なので，最小にあわせておく
  settings[3] = if day>1 then day-1 else 29
  if day == 1
    settings[4] = if month==1 then 12 else month-1
  return settings.join(" ")
exports.decrementDayOfCronSetting = decrementDayOfCronSetting

exports.startJobs = (robot, channnel) ->
  new cronJob('0 0 12 1 */1 *', (channel) =>
    envelope = room: channel
    messages = [ "@channel Check!" ]
    as.assign(robot, (resultMsgs, err) ->
      if err
        robot.send envelope, "Error: " + err + ", so cannnot extcute cron job"; return
      for resultMsg in resultMsgs
        messages.push resultMsg
      for message in messages
          robot.send envelope, message
    )
  ).start()

resetAssignCronJobs = () ->
  if assignCronJobs.length >0
    for job in assignCronJobs
      job.stop()
    assignCronJobs = []

startAssignCronJobs = (robot, assignments) ->
  if assignments?
    msg = ['Assigned cron jobs are follows']
    for assignment in assignments
      assignedDate = translateDateToCronSetting(assignment["date"])
      notifiedDate = decrementDayOfCronSetting(assignedDate)
      assignCronJobs.push(
        new cronJob(notifiedDate, (channel) =>
          envelope = room: channel
          robot.send envelope, "@"+assignment["assign"]+" You are assigned to duty in tommorow"
        )
      )
      msgDate = translateCronSettingToDate notifiedDate
      msgName = assignment["assign"]
      msg.push "date:#{msgDate}, name:#{msgName}"
    for job in assignCronJobs
      job.start()
    return msg
  else
    throw Error "There are no assignment for creating cron jobs"
exports.startAssignCronJobs = startAssignCronJobs

getAssignCronJobsState = (state) ->
  if assignCronJobs == []
    return ["There are no cron jobs"]
  else
    msg = []
    for job in assignCronJobs
      msg.push job
exports.getAssignCronJobsState = getAssignCronJobsState
