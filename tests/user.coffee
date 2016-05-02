chai = require 'chai'
expect = chai.expect
chai.should()

user = require('./../scripts/user.coffee')

describe 'ユーザデータに対する操作',->
  users = null

  before ->
    users = [
      {"name":"tasuwo", "grade":"M1"},
      {"name":"tozawa", "grade":"M2"},
      {"name":"tetsuwo", "grade":"B4"}
    ]

  it "名前からインデックスを取得する", ->
    expect(user.getIndexByName("tasuwo", users)==0).be.true
    expect(user.getIndexByName("tozawa", users)==1).be.true
    expect(user.getIndexByName("tetsuwo", users)==2).be.true
