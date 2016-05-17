HOME_PATH = (process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE)
LOG_DIR_PATH = HOME_PATH + '/.gomi-man-bot-log'

Log       = require('log')
fs        = require('fs')
readline  = require('readline')

exports.getLogDirPath = () ->
  return LOG_DIR_PATH

exports.getWriter = (level, fName) ->
  try
    fs.mkdirSync LOG_DIR_PATH
  catch err
    if err.code != 'EEXIST' then throw err
  try
    fs.writeFile LOG_DIR_PATH+'/'+fName, ""
  catch err
    if err.code != 'EEXIST' then throw err
  stream = fs.createWriteStream LOG_DIR_PATH + '/' + fName
  return new Log(level, stream)

exports.getReader = (level, fName) ->
  stream = fs.createReadStream LOG_DIR_PATH + '/' + fName
  return new Log(level, stream)
