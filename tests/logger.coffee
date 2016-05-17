chai = require 'chai'
expect = chai.expect
chai.should()
sinon = require 'sinon'

logger = require('./../scripts/logger.coffee')
fs = require('fs')

describe 'ログのテスト', ->
  FNAME = 'tmp.log'
  DIR_PATH = logger.getLogDirPath()

  after ->
    fs.unlink DIR_PATH+'/'+FNAME

  it "ログ保存&読み取りテスト", (done)->
    writer = logger.getWriter('debug', FNAME)

    obj = new Object()
    obj.invoked = () ->
    mock = sinon.mock(obj)
    mock.expects("invoked").twice()

    writer.error('some error messages')
    writer.error('some error messages')

    reader = logger.getReader('debug', FNAME)
    reader
      .on 'line', (line) ->
        obj.invoked()
      .on 'end', () ->
        mock.verify()
        mock.restore()
        done()
