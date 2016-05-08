chai = require 'chai'
expect = chai.expect
chai.should()
sinon = require 'sinon'

assignment = require('./../scripts/assignment.coffee')
api = require('./../scripts/googleapi.coffee')
users = require('./../scripts/user.coffee')

describe '当番の割り当てに関するテスト',->
  usersData = null
  datesData = null

  before ->
    usersData = [
      {"id":1, "name":"tasuwo", "grade":"M1"},
      {"id":2, "name":"tozawa", "grade":"M2"},
      {"id":3, "name":"tetsuwo", "grade":"B4"}
    ]
    datesData = {
      "2016-04-01": ["ゴミ"],
      "2016-04-10": ["ゴミ"],
      "2016-04-12": ["缶"],
      "2016-04-18": ["ゴミ"],
    }

  context "イベントへのユーザ割り当て処理のテスト", ->
    authorizeStub = null
    getEventsStub = null
    getLastAssignedMonthStub = null
    getLastAssignedUserStub = null
    getAllStub = null
    saveAssignmentStub = null

    before ->
      authorizeStub = sinon.stub(api, 'authorize')
      getEventsStub = sinon.stub(api, 'getEvents')
      getLastAssignedMonthStub = sinon.stub(assignment, 'getLastAssignedMonth')
      getLastAssignedUserStub  = sinon.stub(assignment, 'getLastAssignedUser')
      getAllStub = sinon.stub(users, 'getAll')
      saveAssignmentStub = sinon.stub(assignment, 'saveAssignments')

    after ->
      api.authorize.restore()
      api.getEvents.restore()
      assignment.getLastAssignedMonth.restore()
      assignment.getLastAssignedUser.restore()
      users.getAll.restore()
      assignment.saveAssignments.restore()

    it '正常に割り当てが行える', (done) ->
      authorizeStub.callsArgWith(1, true, null)
      getEventsStub.callsArgWith(2, datesData)
      getLastAssignedMonthStub.returns(null)
      getLastAssignedUserStub.returns(null)
      getAllStub.returns(usersData)
      saveAssignmentStub.returns(null)
      assignment.assign(null, (err, preSotredFlg) ->
        expect(preSotredFlg==false).be.true
        done()
      )

    it '既に該当月の割り当てが終了していた場合', (done) ->
      authorizeStub.callsArgWith(1, true, null)
      getEventsStub.callsArgWith(2, datesData)
      getLastAssignedMonthStub.returns(4)
      getLastAssignedUserStub.returns(usersData[1])
      getAllStub.returns(usersData)
      saveAssignmentStub.returns(null)
      assignment.assign(null, (err, preStoredFlg) ->
        expect(preStoredFlg==true).be.true
        done()
      )

    it '例外処理 : 通信時エラーによる access token 取得失敗', (done) ->
      authorizeStub.callsArgWith(1, null, null)
      assignment.assign(null, (err, preSotredFlg) ->
        expect(err=="Failed to authorize API").be.true
        done()
      )

    it '例外処理 : 取得したはずの access token が null であった場合', (done) ->
      authorizeStub.callsArgWith(1, null, Error "someone error")
      assignment.assign(null, (err, preSotredFlg) ->
        expect(err?).be.true
        done()
      )

    it '例外処理 : 日付取得失敗', (done) ->
      authorizeStub.callsArgWith(1, true, null)
      getEventsStub.callsArgWith(2, null)
      assignment.assign(null, (err, preSotredFlg) ->
        expect(err=="There are no events on calendar for assignment").be.true
        done()
      )

    it '例外処理 : 割り当てる対象のユーザが存在しない', (done) ->
      authorizeStub.callsArgWith(1, true, null)
      getEventsStub.callsArgWith(2, datesData)
      getLastAssignedMonthStub.returns(null)
      getLastAssignedUserStub.returns(null)
      getAllStub.returns(null)
      assignment.assign(null, (err, preSotredFlg) ->
        expect(err=="There are no users for assignment").be.true
        done()
      )

  context '日程へのメンバーの割り当て', ->
    it "ユーザに当番を割り当てる(先頭のメンバーから割り当て)", ->
      assign = assignment.createAssignmentsList(usersData, datesData, usersData[0]["id"])
      expect(assign.length==4).be.true
      expect(assign[0]["date"]=="2016-04-01").be.true
      expect(assign[1]["date"]=="2016-04-10").be.true
      expect(assign[2]["date"]=="2016-04-12").be.true
      expect(assign[3]["date"]=="2016-04-18").be.true
      expect(assign[0]["assign"]=="tasuwo").be.true
      expect(assign[1]["assign"]=="tozawa").be.true
      expect(assign[2]["assign"]=="tetsuwo").be.true
      expect(assign[3]["assign"]=="tasuwo").be.true

    it "ユーザに当番を割り当てる(途中のメンバーから割り当て)", ->
      assign = assignment.createAssignmentsList(usersData, datesData, usersData[1]["id"])
      expect(assign.length==4).be.true
      expect(assign[0]["date"]=="2016-04-01").be.true
      expect(assign[1]["date"]=="2016-04-10").be.true
      expect(assign[2]["date"]=="2016-04-12").be.true
      expect(assign[3]["date"]=="2016-04-18").be.true
      expect(assign[0]["assign"]=="tozawa").be.true
      expect(assign[1]["assign"]=="tetsuwo").be.true
      expect(assign[2]["assign"]=="tasuwo").be.true
      expect(assign[3]["assign"]=="tozawa").be.true

    it "不正な引数が与えられた場合には例外を発生させる", ->
      expect(assignment.createAssignmentsList.bind(assignment, [], datesData, usersData[0]["name"])).to.throw(Error)
      expect(assignment.createAssignmentsList.bind(assignment, usersData, [], usersData[0]["name"])).to.throw(Error)

  context '当番となるメンバー達を，システムへの登録順に基づいて決定する', ->
    it "当番人数 <= 全メンバー数 であり，割り当てが先頭のメンバーに戻らない場合", ->
      members = assignment.extractUsersInOrder(0,3,usersData)
      expect(members.length == 3).be.true
      expect(members[0]["name"]=="tasuwo").be.true
      expect(members[1]["name"]=="tozawa").be.true
      expect(members[2]["name"]=="tetsuwo").be.true

    it "当番人数 <= 全メンバー数 であり，割り当てが先頭のメンバーに戻る場合", ->
      members = assignment.extractUsersInOrder(1,3,usersData)
      expect(members.length == 3).be.true
      expect(members[0]["name"]=="tozawa").be.true
      expect(members[1]["name"]=="tetsuwo").be.true
      expect(members[2]["name"]=="tasuwo").be.true

    it "当番人数 > 全メンバー数 である場合", ->
      members = assignment.extractUsersInOrder(1,6,usersData)
      expect(members[0]["name"]=="tozawa").be.true
      expect(members[1]["name"]=="tetsuwo").be.true
      expect(members[2]["name"]=="tasuwo").be.true
      expect(members[3]["name"]=="tozawa").be.true
      expect(members[4]["name"]=="tetsuwo").be.true
      expect(members[5]["name"]=="tasuwo").be.true

    it '不正な引数が与えられた場合は例外を発生させる', ->
      expect(assignment.extractUsersInOrder.bind(assignment,-1,3,usersData)).to.throw(Error)
      expect(assignment.extractUsersInOrder.bind(assignment,1,-1,usersData)).to.throw(Error)
      expect(assignment.extractUsersInOrder.bind(assignment,1,-1,null)).to.throw(Error)
