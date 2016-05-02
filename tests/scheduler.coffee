Helper = require('hubot-test-helper')
chai = require 'chai'
expect = chai.expect
chai.should()
# add should method to Object.prototype

scheduler = require('./../scripts/scheduler.coffee')

describe '掃除当番メンバーの取得',->
  users = null
  dates = null

  before ->
    users = [
      {"id":"a", "name":"tasuwo", "grade":"M1"},
      {"id":"b", "name":"tozawa", "grade":"M2"},
      {"id":"c", "name":"tetsuwo", "grade":"B4"}
    ]
    dates = {
      "2016-04-01": ["ゴミ"],
      "2016-04-10": ["ゴミ"],
      "2016-04-12": ["缶"],
      "2016-04-18": ["ゴミ"],
    }

  it "当番が巡回しない場合", ->
    members = scheduler.extractDutyMembers(0,3,users)
    expect(members.length == 3).be.true
    expect(members[0]["id"]=="a").be.true
    expect(members[1]["id"]=="b").be.true
    expect(members[2]["id"]=="c").be.true

  it "当番が一巡する場合", ->
    members = scheduler.extractDutyMembers(1,3,users)
    expect(members.length == 3).be.true
    expect(members[0]["id"]=="b").be.true
    expect(members[1]["id"]=="c").be.true
    expect(members[2]["id"]=="a").be.true

  it "当番が複数回巡回する場合", ->
    members = scheduler.extractDutyMembers(1,6,users)
    expect(members[0]["id"]=="b").be.true
    expect(members[1]["id"]=="c").be.true
    expect(members[2]["id"]=="a").be.true
    expect(members[3]["id"]=="b").be.true
    expect(members[4]["id"]=="c").be.true
    expect(members[5]["id"]=="a").be.true

  it "ユーザに当番を割り当てる(最初のメンバーから割り当て)", ->
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
