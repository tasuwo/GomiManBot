Helper = require('hubot-test-helper')
helper = new Helper('./../scripts/gomi-man.coffee')

expect = require('chai').expect
co     = require('co')

describe 'ユーザコマンドのテスト', ->
  room = null

  beforeEach ->
    room = helper.createRoom()

  afterEach ->
    room.destroy()

  context '保存', ->
    beforeEach ->
      co =>
        yield room.user.say 'alice', 'hubot save me as B4'
        yield room.user.say 'bob', 'hubot save me as M1'

    it '保存されたことを通知する', ->
      expect(room.messages).to.eql [
        ['alice', 'hubot save me as B4']
        ['hubot', 'Save alice as B4!']
        ['bob', 'hubot save me as M1']
        ['hubot', 'Save bob as M1!']
      ]

  context '保存', ->
    beforeEach ->
      co =>
        yield room.user.say 'alice', 'hubot save me as B4'
        yield room.user.say 'alice', 'hubot save me as M1'

    it 'ユーザ名が重複していた場合にはエラーを出力する', ->
      expect(room.messages).to.eql [
        ['alice', 'hubot save me as B4']
        ['hubot', 'Save alice as B4!']
        ['alice', 'hubot save me as M1']
        ['hubot', 'Error: User name is duplicate']
      ]

  context '表示', ->
    beforeEach ->
      co =>
        yield room.user.say 'alice', 'hubot save me as B4'
        yield room.user.say 'bob', 'hubot save me as M1'
        yield room.user.say 'alice', 'hubot users list'

    it '登録されたユーザ一覧を表示する', ->
      expect(room.messages).to.eql [
        ['alice', 'hubot save me as B4']
        ['hubot', 'Save alice as B4!']
        ['bob', 'hubot save me as M1']
        ['hubot', 'Save bob as M1!']
        ['alice', 'hubot users list']
        ['hubot', 'Registerd users are as follows...']
        ['hubot', '`1` name:alice, grade:B4']
        ['hubot', '`2` name:bob, grade:M1']
      ]

  context '表示', ->
    beforeEach ->
      co =>
        yield room.user.say 'alice', 'hubot users list'

    it 'ユーザが存在しない場合には，登録を促すメッセージを表示する', ->
      expect(room.messages).to.eql [
        ['alice', 'hubot users list']
        ['hubot', 'There are no users. Please regist users by `save me
      as B4|M1|M2`']
      ]

  context '表示', ->
    beforeEach ->
      co =>
        yield room.user.say 'alice', 'hubot save me as M1'
        yield room.user.say 'bob', 'hubot save me as M2'
        yield room.user.say 'alice', 'hubot remove alice'
        yield room.user.say 'alice', 'hubot save me as B4'
        yield room.user.say 'alice', 'hubot users list'

    it 'IDをふりわける', ->
      expect(room.messages).to.eql [
        ['alice', 'hubot save me as M1']
        ['hubot', 'Save alice as M1!']
        ['bob', 'hubot save me as M2']
        ['hubot', 'Save bob as M2!']
        ['alice', 'hubot remove alice']
        ['hubot', 'Successfully removed!']
        ['alice', 'hubot save me as B4']
        ['hubot', 'Save alice as B4!']
        ['alice', 'hubot users list']
        ['hubot', 'Registerd users are as follows...']
        ['hubot', '`1` name:alice, grade:B4']
        ['hubot', '`2` name:bob, grade:M2']
      ]


  context '更新', ->
    beforeEach ->
      co =>
        yield room.user.say 'alice', 'hubot save me as B4'
        yield room.user.say 'alice', 'hubot update alice : name > bob'
        yield room.user.say 'alice', 'hubot users list'

    it 'ユーザ情報を更新する', ->
      expect(room.messages).to.eql [
        ['alice', 'hubot save me as B4']
        ['hubot', 'Save alice as B4!']
        ['alice', 'hubot update alice : name > bob']
        ['hubot', 'Successfully updated!']
        ['alice', 'hubot users list']
        ['hubot', 'Registerd users are as follows...']
        ['hubot', '`1` name:bob, grade:B4']
      ]
  context '更新', ->
    beforeEach ->
      co =>
        yield room.user.say 'alice', 'hubot save me as B4'
        yield room.user.say 'alice', 'hubot update alice : name >
        alice'

    it '重複した名前に更新しようとした場合にはエラーを出力する', ->
      expect(room.messages).to.eql [
          ['alice', 'hubot save me as B4']
          ['hubot', 'Save alice as B4!']
          ['alice', 'hubot update alice : name > alice']
          ['hubot', 'Error: User name is duplicate']
      ]

  context '更新', ->
    beforeEach ->
      co =>
        yield room.user.say 'alice', 'hubot save me as B4'
        yield room.user.say 'alice', 'hubot update alice : test >
        alice'

    it '存在しないプロパティを更新しようとした場合はエラーを出力する', ->
      expect(room.messages).to.eql [
          ['alice', 'hubot save me as B4']
          ['hubot', 'Save alice as B4!']
          ['alice', 'hubot update alice : test > alice']
          ['hubot', 'Error: Assigned property doesn\'t exist']
      ]

  context '削除', ->
    beforeEach ->
      co =>
        yield room.user.say 'alice', 'hubot save me as B4'
        yield room.user.say 'alice', 'hubot remove alice'
        yield room.user.say 'alice', 'hubot users list'

    it 'ユーザを削除する(すべてのユーザが削除されると，usersがnullにな
      る)', ->
      expect(room.messages).to.eql [
          ['alice', 'hubot save me as B4']
          ['hubot', 'Save alice as B4!']
          ['alice', 'hubot remove alice']
          ['hubot', 'Successfully removed!']
          ['alice', 'hubot users list']
          ['hubot', 'There are no users. Please regist users by `save me
      as B4|M1|M2`']
      ]

  context '削除', ->
    beforeEach ->
      co =>
        yield room.user.say 'alice', 'hubot remove alice'

    it '存在しないユーザを削除しようとしたらエラーを出力する', ->
      expect(room.messages).to.eql [
          ['alice', 'hubot remove alice']
          ['hubot', 'Error: Assigned user name doesn\'t exist']
      ]

