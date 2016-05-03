gomi_man = require('./gomi-man.coffee')
cronJob = require('cron').CronJob

translateDateToCronSetting = (date) ->
  if date.split("-").length != 3
    throw Error "Invalid arguement"
  month = parseInt(date.split("-")[1])
  day   = parseInt(date.split("-")[2])
  return '0 0 12 ' + day + ' ' + month + ' *'
exports.translateDateToCronSetting = translateDateToCronSetting

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
  childJobs = []

  new cronJob('0 0 12 1 */1 *', (channel) =>
    envelope = room: channel
    try
      messages = [ "@channel Check!" ]
      gomi_man.assign(robot, (resultMsgs) ->
        for resultMsg in resultMsgs
          msg.push resultMsg
      )
      for message in messages
        robot.send envelope, message
    catch error

    if childJobs.length > 0
      for job in childJobs
        job.stop()

    assignments = gomi_man.getAssignmentsList(robot)
    if assignments?
      for assignment in assignments
        assignedDate = translateDateToCronSetting(assignment["date"])
        notifiedDate = decideMembersForAssignment(assignedDate)
        childJobs.push(
          new cronJob(notifiedDate, () =>
            robot.send envelope, "@"+assignment["name"]+" You are
            assigned to duty in tommorow"
          )
        )
      for job in childJobs
        job.start()
  ).start()

