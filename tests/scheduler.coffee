Helper = require('hubot-test-helper')
chai = require 'chai'
expect = chai.expect
chai.should()
# add should method to Object.prototype

scheduler = require('./../scripts/scheduler.coffee')

describe '掃除当番のスケジューラ',->
  users = null
  dates = null

  before ->
    users = [
      {"name":"tasuwo", "grade":"M1"},
      {"name":"tozawa", "grade":"M2"},
      {"name":"tetsuwo", "grade":"B4"}
    ]
    dates = {
      "2016-04-01": ["ゴミ"],
      "2016-04-10": ["ゴミ"],
      "2016-04-12": ["缶"],
      "2016-04-18": ["ゴミ"],
    }

  context '当番となるメンバー達を，システムへの登録順に基づいて決定す
    る', ->
    it "当番人数 <= 全メンバー数 であり，割り当てが先頭のメンバーに戻
    らない場合", ->
      members = scheduler.extractDutyMembers(0,3,users)
      expect(members.length == 3).be.true
      expect(members[0]["name"]=="tasuwo").be.true
      expect(members[1]["name"]=="tozawa").be.true
      expect(members[2]["name"]=="tetsuwo").be.true

    it "当番人数 <= 全メンバー数 であり，割り当てが先頭のメンバーに戻
      る場合", ->
      members = scheduler.extractDutyMembers(1,3,users)
      expect(members.length == 3).be.true
      expect(members[0]["name"]=="tozawa").be.true
      expect(members[1]["name"]=="tetsuwo").be.true
      expect(members[2]["name"]=="tasuwo").be.true

    it "当番人数 > 全メンバー数 である場合", ->
      members = scheduler.extractDutyMembers(1,6,users)
      expect(members[0]["name"]=="tozawa").be.true
      expect(members[1]["name"]=="tetsuwo").be.true
      expect(members[2]["name"]=="tasuwo").be.true
      expect(members[3]["name"]=="tozawa").be.true
      expect(members[4]["name"]=="tetsuwo").be.true
      expect(members[5]["name"]=="tasuwo").be.true

  context '日程へのメンバーの割り当て', ->
    it "ユーザに当番を割り当てる(先頭のメンバーから割り当て)", ->
      assign = scheduler.assign(users, dates, users[2]["name"])
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
      assign = scheduler.assign(users, dates, users[0]["name"])
      expect(assign.length==4).be.true
      expect(assign[0]["date"]=="2016-04-01").be.true
      expect(assign[1]["date"]=="2016-04-10").be.true
      expect(assign[2]["date"]=="2016-04-12").be.true
      expect(assign[3]["date"]=="2016-04-18").be.true
      expect(assign[0]["assign"]=="tozawa").be.true
      expect(assign[1]["assign"]=="tetsuwo").be.true
      expect(assign[2]["assign"]=="tasuwo").be.true
      expect(assign[3]["assign"]=="tozawa").be.true
