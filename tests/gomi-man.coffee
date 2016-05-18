Helper = require('hubot-test-helper')
helper = new Helper('./../scripts/gomi-man.coffee')
User = require('./../scripts/user.coffee').User
Assignment = require('./../scripts/assignment.coffee')

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
    it '自分を保存する', ->
      co =>
        yield room.user.say 'alice', 'hubot save me as grade:B4'
        yield room.user.say 'bob', 'hubot save me as grade:M1'
        expect(room.messages).to.eql [
          ['alice', 'hubot save me as grade:B4']
          ['hubot', 'Save alice!']
          ['bob', 'hubot save me as grade:M1']
          ['hubot', 'Save bob!']
        ]

    it '他人を保存する', ->
      co =>
        yield room.user.say 'alice', 'hubot save bob as grade:M1'
        yield room.user.say 'alice', 'hubot users list'
        expect(room.messages).to.eql [
          ['alice', 'hubot save bob as grade:M1']
          ['hubot', 'Save bob!']
          ['alice', 'hubot users list']
          ['hubot', 'Registerd users are as follows...\n`1` name:bob, grade:M1']
        ]

    it '複数の情報を保存できる', ->
      co =>
        yield room.user.say 'alice', 'hubot save me as grade:B4, no:11t4054x'
        yield room.user.say 'alice', 'hubot users list'
        expect(room.messages).to.eql [
          ['alice', 'hubot save me as grade:B4, no:11t4054x']
          ['hubot', 'Save alice!']
          ['alice', 'hubot users list']
          ['hubot', 'Registerd users are as follows...\n`1` name:alice, grade:B4, no:11t4054x']
        ]

    it 'ユーザ名が重複していた場合にはエラーを出力する', ->
      co =>
        yield room.user.say 'alice', 'hubot save me as grade:B4'
        yield room.user.say 'alice', 'hubot save me as grade:M1'
        expect(room.messages).to.eql [
          ['alice', 'hubot save me as grade:B4']
          ['hubot', 'Save alice!']
          ['alice', 'hubot save me as grade:M1']
          ['hubot', 'Error: User name is duplicate']
        ]

    it 'IDをセットしようとした場合にはエラー', ->
      co =>
        yield room.user.say 'alice', 'hubot save me as grade:B4, id:3'
        expect(room.messages).to.eql [
          ['alice', 'hubot save me as grade:B4, id:3']
          ['hubot', 'Cannot set id']
        ]

    it 'ユーザ名が"me"の場合にはエラー', ->
      co =>
        yield room.user.say 'me', 'hubot save me as grade:M1'
        expect(room.messages).to.eql [
          ['me', 'hubot save me as grade:M1']
          ['hubot', 'Your name \'me\' means \'yourself\' for me... please rename']
        ]

    it '先頭に空白が存在した場合にも登録できる', ->
      co =>
        yield room.user.say 'alice', 'hubot  save me as grade:B4'
        expect(room.messages).to.eql [
          ['alice', 'hubot  save me as grade:B4']
          ['hubot', 'Save alice!']
        ]

  context '表示', ->
    it '登録されたユーザ一覧を表示する', ->
      co =>
        yield room.user.say 'alice', 'hubot save me as grade:B4'
        yield room.user.say 'bob', 'hubot save me as grade:M1'
        yield room.user.say 'alice', 'hubot users list'
        expect(room.messages).to.eql [
          ['alice', 'hubot save me as grade:B4']
          ['hubot', 'Save alice!']
          ['bob', 'hubot save me as grade:M1']
          ['hubot', 'Save bob!']
          ['alice', 'hubot users list']
          ['hubot', 'Registerd users are as follows...\n`1` name:alice, grade:B4\n`2` name:bob, grade:M1']
        ]

    it 'ユーザが存在しない場合には，登録を促すメッセージを表示する', ->
      co =>
        yield room.user.say 'alice', 'hubot users list'
        expect(room.messages).to.eql [
          ['alice', 'hubot users list']
          ['hubot', 'There are no users. Please regist users by `save (me|<name>) as <prop>:<val>, ...`']
        ]

    it 'IDをふりわける', ->
      co =>
        yield room.user.say 'alice', 'hubot save me as grade:M1'
        yield room.user.say 'bob', 'hubot save me as grade:M2'
        yield room.user.say 'alice', 'hubot users remove 1'
        yield room.user.say 'alice', 'hubot save me as grade:B4'
        yield room.user.say 'alice', 'hubot users list'
        expect(room.messages).to.eql [
          ['alice', 'hubot save me as grade:M1']
          ['hubot', 'Save alice!']
          ['bob', 'hubot save me as grade:M2']
          ['hubot', 'Save bob!']
          ['alice', 'hubot users remove 1']
          ['hubot', 'Successfully removed!']
          ['alice', 'hubot save me as grade:B4']
          ['hubot', 'Save alice!']
          ['alice', 'hubot users list']
          ['hubot', 'Registerd users are as follows...\n`1` name:bob, grade:M2\n`2` name:alice, grade:B4']
        ]

  context '更新', ->
    it 'ユーザ情報を更新する', ->
      co =>
        yield room.user.say 'alice', 'hubot save me as grade:B4'
        yield room.user.say 'alice', 'hubot users update 1 : name > bob'
        yield room.user.say 'alice', 'hubot users list'
        expect(room.messages).to.eql [
          ['alice', 'hubot save me as grade:B4']
          ['hubot', 'Save alice!']
          ['alice', 'hubot users update 1 : name > bob']
          ['hubot', 'Successfully updated!']
          ['alice', 'hubot users list']
          ['hubot', 'Registerd users are as follows...\n`1` name:bob, grade:B4']
        ]

    it '重複した名前に更新しようとした場合にはエラーを出力する', ->
      co =>
        yield room.user.say 'alice', 'hubot save me as grade:B4'
        yield room.user.say 'alice', 'hubot users update 1 : name >
        alice'
        expect(room.messages).to.eql [
          ['alice', 'hubot save me as grade:B4']
          ['hubot', 'Save alice!']
          ['alice', 'hubot users update 1 : name > alice']
          ['hubot', 'Error: User name is duplicate']
        ]

    # it '存在しないプロパティを更新しようとした場合はエラーを出力する', ->
    #   co =>
    #     yield room.user.say 'alice', 'hubot save me as grade:B4'
    #     yield room.user.say 'alice', 'hubot users update 1 : test >
    #     alice'
    #     expect(room.messages).to.eql [
    #       ['alice', 'hubot save me as grade:B4']
    #       ['hubot', 'Save alice!']
    #       ['alice', 'hubot users update 1 : test > alice']
    #       ['hubot', 'Error: Assigned property doesn\'t exist']
    #   ]

  context '削除', ->
    it 'ユーザを削除する(すべてのユーザが削除されると，usersがnullになる)', ->
      co =>
        yield room.user.say 'alice', 'hubot save me as grade:B4'
        yield room.user.say 'alice', 'hubot users remove 1'
        yield room.user.say 'alice', 'hubot users list'
        expect(room.messages).to.eql [
          ['alice', 'hubot save me as grade:B4']
          ['hubot', 'Save alice!']
          ['alice', 'hubot users remove 1']
          ['hubot', 'Successfully removed!']
          ['alice', 'hubot users list']
          ['hubot', 'There are no users. Please regist users by `save (me|<name>) as <prop>:<val>, ...`']
        ]

    it '存在しないユーザを削除しようとしたらエラーを出力する', ->
      co =>
        yield room.user.say 'alice', 'hubot users remove 1'
        expect(room.messages).to.eql [
          ['alice', 'hubot users remove 1']
          ['hubot', 'Error: Assigned user name doesn\'t exist']
        ]

  context '交換', ->
    getAllStub = null

    before ->
      usersData = [
        {"id":1, "name":"tasuwo", "grade":"M1"},
        {"id":2, "name":"tozawa", "grade":"M2"},
        {"id":3, "name":"tetsuwo", "grade":"B4"},
        {"id":4, "name":"aaa", "grade":"M1"},
      ]
      getAllStub = sinon.stub(User.prototype, 'getAll')
      getAllStub.returns(usersData)

    after ->
      User.prototype.getAll.restore()

    it 'ユーザの順番を交換する', ->
      co =>
        yield room.user.say 'alice', 'hubot users swap 2 4'
        yield room.user.say 'alice', 'hubot users list'
        yield room.user.say 'alice', 'hubot users swap 0 10'
        expect(room.messages.toString()).to.equal [
          ['alice', 'hubot users swap 2 4']
          ['hubot', 'Swapped user 2 and 4!']
          ['alice', 'hubot users list']
          ['hubot', 'Registerd users are as follows...\n`1` name:tasuwo, grade:M1\n`2` name:aaa, grade:M1\n`3` name:tetsuwo, grade:B4\n`4` name:tozawa, grade:M2']
          ['alice', 'hubot users swap 0 10']
          ['hubot', 'Error: Specified user id doesn\'t exist']
        ].toString()

  context 'ユーザ割り当て', ->
    getAssignmentsListStub = null
    getAllStub = null

    before ->
      assignmentsList = [
        {"id":1, "date":"2016-10-3", "duty":"ゴミ捨て", "assign":"tozawa"},
        {"id":2, "date":"2016-10-20", "duty":"ゴミ捨て", "assign":"tasuku"}
      ]
      getAssignmentsListStub = sinon.stub(Assignment.prototype, 'getList')
      getAssignmentsListStub.returns(assignmentsList)
      usersData = [
        {"id":1, "name":"tasuwo", "grade":"M1"},
        {"id":2, "name":"tozawa", "grade":"M2"},
        {"id":3, "name":"tetsuwo", "grade":"B4"},
        {"id":4, "name":"aaa", "grade":"M1"},
      ]
      getAllStub = sinon.stub(User.prototype, 'getAll')
      getAllStub.returns(usersData)

    after ->
      Assignment.prototype.getList.restore()
      User.prototype.getAll.restore()

    it 'ユーザ割り当てが行われていない場合はその旨を通知する', (done)->
      co =>
        yield room.user.say 'alice', 'hubot assign list'
        yield done()
        expect(room.messages).to.eql [
          ['alice', 'hubot assign list']
          ['hubot', 'There are no assignments. Please assign users to duty by `assign users` command.']
        ]

    it 'ユーザの割り当て表を表示する', ->
      co =>
        yield room.user.say 'alice', 'hubot assign list'
        expect(room.messages).to.eql [
          ['alice', 'hubot assign list']
          ['hubot', '`1` date:2016-10-3, duty:ゴミ捨て, member:tozawa\n`2` date:2016-10-20, duty:ゴミ捨て, member:tasuku']
        ]

    it 'ユーザ割り当てを途中から開始する', (done)->
      co =>
        yield room.user.say 'alice', 'hubot assign from 2'
        yield room.user.say 'alice', 'hubot assign from 5'
        yield done()
        expect(room.messages).to.eql [
          ['alice', 'hubot assign from 2'],
          ['hubot', 'Assign from `2` tozawa in next assignment!'],
          ['alice', 'hubot assign from 5'],
          ['hubot', 'Error: There are no specified user']
        ]

  context 'ユーザ操作', ->
    getAllStub = null

    beforeEach ->
      usersData = [
        {"id":1, "name":"tasuwo", "grade":"M1", "stNo":"16nm722x"},
        {"id":2, "name":"tozawa", "grade":"M2", "stNo":"15nm722x"},
        {"id":3, "name":"tetsuwo", "grade":"B4", "stNo":"11t4054x"},
        {"id":4, "name":"aaa", "grade":"M1", "stNo":"16nm701x"},
      ]
      getAllStub = sinon.stub(User.prototype, 'getAll')
      getAllStub.returns(usersData)

    afterEach ->
      User.prototype.getAll.restore()

    it 'ユーザをソートする', (done)->
      co =>
        yield room.user.say 'alice', 'hubot users sort by ???'
        yield room.user.say 'alice', 'hubot users sort by grade'
        yield done()
        expect(room.messages).to.eql [
          ['alice', 'hubot users sort by ???']
          ['hubot', 'There are no method for sort']
          ['alice', 'hubot users sort by grade']
          ['hubot', 'Users were sorted by grade!']
        ]

  context 'チャンネル設定', ->
    it '通知用チャンネルを保存する', ->
      co =>
        yield room.user.say 'alice', 'hubot channel check'
        yield room.user.say 'alice', 'hubot channel set develop'
        yield room.user.say 'alice', 'hubot channel check'
        expect(room.messages).to.eql [
          ['alice', 'hubot channel check']
          ['hubot', 'No channel registered. Please save channel by `channel set <channel name>` command.']
          ['alice', 'hubot channel set develop']
          ['hubot', 'I\'ll send notification to channel: #develop !']
          ['alice', 'hubot channel check']
          ['hubot', 'Notify channel is set to #develop ']
        ]
