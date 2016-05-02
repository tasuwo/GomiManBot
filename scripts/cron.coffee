cronJob = require('cron').CronJob

translateDateToCronSetting = (date) ->
  if date.split("-").length != 3
    throw Error "Invalid arguement"
  month = parseInt(date.split("-")[1])
  day   = parseInt(date.split("-")[2])
  return '0 12 ' + day + ' ' + month + ' * *'
exports.translateDateToCronSetting = translateDateToCronSetting

# module.exports = (robot) ->
#   # 月のはじめに assign する
#   cronjob = new cronJob('0 12 1 */1 * *', () =>
#     envelope = room: "#chireiden"
#     robot.send envelope, "@channel ゴミだせ"
#   )
#   cronjob.start()

#   # 前日にユーザに通知する
