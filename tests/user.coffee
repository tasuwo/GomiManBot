chai = require 'chai'
expect = chai.expect
chai.should()

user = require('./../scripts/user.coffee')

describe 'ユーザデータに対する操作',->
  users = null

  before ->
    users = [
      {"id":"a", "name":"tasuwo", "grade":"M1"},
      {"id":"b", "name":"tozawa", "grade":"M2"},
      {"id":"c", "name":"tetsuwo", "grade":"B4"}
    ]

  it "IDからインデックスを取得する", ->
    expect(user.getIndexBy("a", users)==0).be.true
    expect(user.getIndexBy("b", users)==1).be.true
    expect(user.getIndexBy("c", users)==2).be.true

