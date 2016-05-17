Log = require('log')
fs = require('fs')

class Logger
  @HOME_PATH: (process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE)
  @LOG_DIR_PATH: @HOME_PATH + '/.gomi-man-bot-log'

  constructor: (fName) ->
    @fName = fName

  @getLogDirPath: () ->
    @LOG_DIR_PATH

  _getLogFilePath: () ->
    return Logger.LOG_DIR_PATH + '/' + @fName

  _preparation: () ->
    try
      fs.mkdirSync Logger.LOG_DIR_PATH
    catch err
      if err.code != 'EEXIST' then throw err
    try
      fs.closeSync(fs.openSync this._getLogFilePath(), 'w')
    catch err
      throw err

  getWriter: () ->
    this._preparation()
    stream = fs.createWriteStream this._getLogFilePath()
    return new Log("debug", stream)

  getReader: () ->
    this._preparation()
    stream = fs.createReadStream this._getLogFilePath()
    return new Log("debug", stream)

module.exports = Logger
