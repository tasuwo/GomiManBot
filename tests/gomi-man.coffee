Helper = require('hubot-test-helper')
helper = new Helper('./../scripts/gomi-man.coffee')
user   = require('./../scripts/user.coffee')

expect = require('chai').expect
co     = require('co')
sinon  = require('sinon')

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

  context '保存', ->
    beforeEach ->
      co =>
        yield room.user.say 'alice', 'hubot  save me as B4'

    it '先頭に空白が存在した場合にも登録できる', ->
      expect(room.messages).to.eql [
        ['alice', 'hubot  save me as B4']
        ['hubot', 'Save alice as B4!']
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
        yield room.user.say 'alice', 'hubot remove 1'
        yield room.user.say 'alice', 'hubot save me as B4'
        yield room.user.say 'alice', 'hubot users list'

    it 'IDをふりわける', ->
      expect(room.messages).to.eql [
        ['alice', 'hubot save me as M1']
        ['hubot', 'Save alice as M1!']
        ['bob', 'hubot save me as M2']
        ['hubot', 'Save bob as M2!']
        ['alice', 'hubot remove 1']
        ['hubot', 'Successfully removed!']
        ['alice', 'hubot save me as B4']
        ['hubot', 'Save alice as B4!']
        ['alice', 'hubot users list']
        ['hubot', 'Registerd users are as follows...']
        ['hubot', '`1` name:bob, grade:M2']
        ['hubot', '`2` name:alice, grade:B4']
      ]


  context '更新', ->
    beforeEach ->
      co =>
        yield room.user.say 'alice', 'hubot save me as B4'
        yield room.user.say 'alice', 'hubot update 1 : name > bob'
        yield room.user.say 'alice', 'hubot users list'

    it 'ユーザ情報を更新する', ->
      expect(room.messages).to.eql [
        ['alice', 'hubot save me as B4']
        ['hubot', 'Save alice as B4!']
        ['alice', 'hubot update 1 : name > bob']
        ['hubot', 'Successfully updated!']
        ['alice', 'hubot users list']
        ['hubot', 'Registerd users are as follows...']
        ['hubot', '`1` name:bob, grade:B4']
      ]
  context '更新', ->
    beforeEach ->
      co =>
        yield room.user.say 'alice', 'hubot save me as B4'
        yield room.user.say 'alice', 'hubot update 1 : name >
        alice'

    it '重複した名前に更新しようとした場合にはエラーを出力する', ->
      expect(room.messages).to.eql [
          ['alice', 'hubot save me as B4']
          ['hubot', 'Save alice as B4!']
          ['alice', 'hubot update 1 : name > alice']
          ['hubot', 'Error: User name is duplicate']
      ]

  context '更新', ->
    beforeEach ->
      co =>
        yield room.user.say 'alice', 'hubot save me as B4'
        yield room.user.say 'alice', 'hubot update 1 : test >
        alice'

    it '存在しないプロパティを更新しようとした場合はエラーを出力する', ->
      expect(room.messages).to.eql [
          ['alice', 'hubot save me as B4']
          ['hubot', 'Save alice as B4!']
          ['alice', 'hubot update 1 : test > alice']
          ['hubot', 'Error: Assigned property doesn\'t exist']
      ]

  context '削除', ->
    beforeEach ->
      co =>
        yield room.user.say 'alice', 'hubot save me as B4'
        yield room.user.say 'alice', 'hubot remove 1'
        yield room.user.say 'alice', 'hubot users list'

    it 'ユーザを削除する(すべてのユーザが削除されると，usersがnullにな
      る)', ->
      expect(room.messages).to.eql [
          ['alice', 'hubot save me as B4']
          ['hubot', 'Save alice as B4!']
          ['alice', 'hubot remove 1']
          ['hubot', 'Successfully removed!']
          ['alice', 'hubot users list']
          ['hubot', 'There are no users. Please regist users by `save me
      as B4|M1|M2`']
      ]

  context '削除', ->
    beforeEach ->
      co =>
        yield room.user.say 'alice', 'hubot remove 1'

    it '存在しないユーザを削除しようとしたらエラーを出力する', ->
      expect(room.messages).to.eql [
          ['alice', 'hubot remove 1']
          ['hubot', 'Error: Assigned user name doesn\'t exist']
      ]

  context '交換', ->
    getAllStub = null

    beforeEach ->
      usersData = [
        {"id":1, "name":"tasuwo", "grade":"M1"},
        {"id":2, "name":"tozawa", "grade":"M2"},
        {"id":3, "name":"tetsuwo", "grade":"B4"},
        {"id":4, "name":"aaa", "grade":"M1"},
      ]
      getAllStub = sinon.stub(user, 'getAll')
      getAllStub.returns(usersData)
      co =>
        yield room.user.say 'alice', 'hubot users swap 2 4'
        yield room.user.say 'alice', 'hubot users list'
        yield room.user.say 'alice', 'hubot users swap 0 10'

    afterEach ->
      user.getAll.restore()

    it 'ユーザの順番を交換する', ->
      expect(room.messages.toString()).to.equal [
        ['alice', 'hubot users swap 2 4']
        ['hubot', 'Swapped user 2 and 4!']
        ['alice', 'hubot users list']
        ['hubot', 'Registerd users are as follows...']
        ['hubot', '`1` name:tasuwo, grade:M1']
        ['hubot', '`2` name:aaa, grade:M1']
        ['hubot', '`3` name:tetsuwo, grade:B4']
        ['hubot', '`4` name:tozawa, grade:M2']
        ['alice', 'hubot users swap 0 10']
        ['hubot', 'Error: Specified user id doesn\'t exist']
      ].toString()


  context 'ユーザ割り当て', ->
    getAllStub = null

    beforeEach ->
      usersData = [
        {"id":1, "name":"tasuwo", "grade":"M1"},
        {"id":2, "name":"tozawa", "grade":"M2"},
        {"id":3, "name":"tetsuwo", "grade":"B4"},
        {"id":4, "name":"aaa", "grade":"M1"},
      ]
      getAllStub = sinon.stub(user, 'getAll')
      getAllStub.returns(usersData)
      co =>
        yield room.user.say 'alice', 'hubot assign from 2'
        yield room.user.say 'alice', 'hubot assign from 5'

    afterEach ->
      user.getAll.restore()

    it 'ユーザ割り当てを途中から開始する', ->
      expect(room.messages).to.eql [
        ['alice', 'hubot assign from 2'],
        ['hubot', 'Assign from `2` tozawa in next assignment!'],
        ['alice', 'hubot assign from 5'],
        ['hubot', 'Error: There are no specified user']
      ]

  context 'チャンネル設定', ->
    beforeEach ->
      co =>
        yield room.user.say 'alice', 'hubot channel check'
        yield room.user.say 'alice', 'hubot channel set develop'
        yield room.user.say 'alice', 'hubot channel check'

    it '通知用チャンネルを保存する', ->
      expect(room.messages).to.eql [
        ['alice', 'hubot channel check']
        ['hubot', 'No channel registered. Please save channel by
      `channel set <channel name>` command.']
        ['alice', 'hubot channel set develop']
        ['hubot', 'I\'ll send notification to channel: #develop!']
        ['alice', 'hubot channel check']
        ['hubot', 'Notify channel is set to #develop']
      ]
