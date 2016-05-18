Assignment = require('./assignment')
CronJob = require('cron').CronJob
Logger = require('./logger.coffee')

class CronSettingConverter
  @convertDateToCronSetting: (date) ->
    if date.split("-").length != 3
      throw Error "Invalid arguement"
    # node-cron では Months は 0-11 なので，1を引いておく
    month = parseInt(date.split("-")[1]) - 1
    day   = parseInt(date.split("-")[2])
    '0 0 12 ' + day + ' ' + month + ' *'

  @convertCronSettingToDayBefore: (cronSetting) ->
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
    settings.join(" ")

class NotificationChannel
  @BRAIN_KEY: "notification_channel_key"

  constructor: (robot) ->
    @robot = robot

  set: (channel) ->
    @robot.brain.set NotificationChannel.BRAIN_KEY, channel

  get: () ->
    @robot.brain.get NotificationChannel.BRAIN_KEY

class CronJobManager
  @LOG_FNAME: "cron.log"

  constructor: (robot) ->
    @monthlyJob = null
    @assignedCronJobs = []
    @robot = robot
    @assignment = new Assignment(robot)

  _sendMessage: (envelope, msg) ->
    @robot.send envelope, msg

  resetAssignedCronJobs: () ->
    if @assignedCronJobs.length >0
      for job in @assignedCronJobs
        job.srttop()
      @assignedCronJobs = []

  getAssignedCronJobs: () ->
    if @assignedCronJobs == []
      return ["There are no cron jobs"]
    else
      msg = []
      for job in assignCronJobs
        msg.push job

  startMonthlyJobTo: (channel) ->
    @monthlyJob = new CronJob('0 0 12 1 */1 *', () =>
      envelope = room: (channel or "general")
      messages = [ "@channel Check!" ]
      @assignment.assign(@robot, (resultMsgs, err) ->
        if err
          this._sendMessage envelope, "Error: " + err + ", so cannnot extcute cron job"
        for resultMsg in resultMsgs
          messages.push resultMsg
        for message in messages
          this._sendMessage envelope, message
      )
    )

    @monthlyJob.start()

  startJobsBasedOn: (assignments, channel) ->
    unless assignments?
      throw Error "There are no assignment for creating cron jobs"

    this.resetAssignedCronJobs()
    for assignment in assignments
      assignedDate = CronSettingConverter.convertDateToCronSetting(assignment["date"])
      notifiedDate = CronSettingConverter.convertCronSettingToDayBefore(assignedDate)
      @assignedCronJobs.push(
        new CronJob(notifiedDate, () =>
          envelope = room: (channel or "general")
          this._sendMessage envelope, "@"+assignment["assign"]+" You are assigned to duty in tommorow"
        )
      )

    for job in @assignedCronJobs
      job.start()

module.exports = {
  CronSettingConverter
  NotificationChannel
  CronJobManager
}
