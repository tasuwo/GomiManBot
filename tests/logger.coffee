chai = require 'chai'
expect = chai.expect
chai.should()
sinon = require 'sinon'

Logger = require('./../scripts/logger.coffee')
fs = require('fs')

describe 'ログのテスト', ->
  FNAME = 'tmp.log'
  DIR_PATH = Logger.getLogDirPath()
  logger = new Logger(FNAME)

  after ->
    fs.unlink DIR_PATH+'/'+FNAME

  it "ログ保存&読み取りテスト", (done)->
    writer = logger.getWriter()

    obj = new Object()
    obj.invoked = () ->
    mock = sinon.mock(obj)
    mock.expects("invoked").twice()

    writer.error('some error messages')
    writer.error('some error messages')

    reader = logger.getReader()
    reader
      .on 'line', (line) ->
        obj.invoked()
      .on 'end', () ->
        mock.verify()
        mock.restore()
        done()
