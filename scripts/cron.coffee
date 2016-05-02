cronJob = require('cron').CronJob

translateDateToCronSetting = (date) ->
  if date.split("-").length != 3
    throw Error "Invalid arguement"
  month = parseInt(date.split("-")[1])
  day   = parseInt(date.split("-")[2])
  return '0 12 ' + day + ' ' + month + ' * *'
exports.translateDateToCronSetting = translateDateToCronSetting

decrementDayOfCronSetting = (cronSetting) ->
  settings = cronSetting.split(" ")
  if settings.length != 6
    throw Error "Invalid arguement"
  day   = parseInt(settings[2])
  month = parseInt(settings[3])
  if day > 1
    settings[2] = day - 1
  else
    if month == 1
      settings[3] = 12
    else
      settings[3] = month - 1
    # 月ごとの最終日を考慮するのが面倒なので，最小にあわせておく
    settings[2] = 29
  return settings.join(" ")
exports.decrementDayOfCronSetting = decrementDayOfCronSetting

# module.exports = (robot) ->
#   # 月のはじめに assign する
#   eachMonthJob = new cronJob('0 12 1 */1 * *', () =>
#     envelope = room: "#chireiden"
#     robot.send envelope, "@channel ゴミだせ"
#   )
#   eachMonthJob.start()

#   # 前日にユーザに通知する
  
