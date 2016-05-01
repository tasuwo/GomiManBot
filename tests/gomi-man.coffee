Helper = require('hubot-test-helper')
expect = require('chai').expect

helper = new Helper('./../scripts/gomi-man.coffee')

describe 'ユーザを保存する', ->
  room = null

  beforeEach ->
    room = helper.createRoom()

  afterEach ->
    room.destroy()

  context 'ユーザ自身の呼びかけにより，brainにユーザ情報を保持し，結果を返す', ->
    beforeEach ->
      room.user.say 'alice', 'hubot save me as B4'
      room.user.say 'bob', 'hubot save me as M1'
      room.user.say 'ken', 'hubot save me as M3'
      room.user.say 'sayuri', 'hubot save me as '

    it '保存されたことを通知する', ->
      expect(room.messages).to.eql [
        ['alice', 'hubot save me as B4']
        ['bob', 'hubot save me as M1']
        ['ken', 'hubot save me as M3']
        ['sayuri', 'hubot save me as ']
        ['hubot', 'save alice as B4']
        ['hubot', 'save bob as M1']
      ]

