sinon = require 'sinon'
chai = require 'chai'
expect = chai.expect
chai.should()

user = require('./../scripts/user.coffee')

describe 'ユーザデータに対する操作',->
  usersData = null
  getAllStub = null
  userMock = null

  before ->
    getAllStub = sinon.stub(user, 'getAll')

  beforeEach ->
    usersData = [
      {"id":1, "name":"tasuwo", "grade":"M1"},
      {"id":2, "name":"tozawa", "grade":"M2"},
      {"id":3, "name":"tetsuwo", "grade":"B4"},
      {"id":4, "name":"aaa", "grade":"M1"},
    ]
    userMock = sinon.mock(user)
    getAllStub.returns(usersData)

#  afterEach ->
#    getAllStub.restore()

  it "ユーザを学年順にソートする", ->
    sortedUsers = user.sortUsersByGrade(usersData)
    expect(sortedUsers[0]["grade"]=="B4").be.true
    expect(sortedUsers[1]["grade"]=="M1").be.true
    expect(sortedUsers[2]["grade"]=="M1").be.true
    expect(sortedUsers[3]["grade"]=="M2").be.true

  it "ユーザ情報から任意のユーザを取得する", ->
    # TODO: 順番に依存しない形式への書き換え
    expect(user.getBy("name","tozawa",null)[1]==1).be.true
    expect(user.getBy("id",3,null)[1]==2).be.true
    expect(user.getBy("test","test",null)==null).be.true

  it "ユーザを保存する", ->
    user_info01 = {"name": "test", "grade": "M1"}
    result_users = usersData.concat(user_info01)
    userMock.expects('save').withArgs(result_users,null)
    user.set(user_info01, null)
    userMock.verify()
    userMock.restore()

    user_info02 = {"name": "tasuwo", "grade": "B4"}
    expect(user.set.bind(user, user_info02, null)).to.throw(Error)

  it "ユーザを更新する", ->
    result_users = [
      {"id":1, "name":"tasuwo", "grade":"M1"},
      {"id":2, "name":"tozawa", "grade":"M2"},
      {"id":3, "name":"tetsuwo", "grade":"B4"},
      {"id":4, "name":"bbb", "grade":"M1"},
    ]
    userMock.expects('save').withArgs(result_users,null)
    user.update(4,"name","bbb",null)
    userMock.verify()
    userMock.restore()
    # 名前が重複
    expect(user.update.bind(user,2,"name","tasuwo",null)).to.throw(Error)
    # IDを変更
    expect(user.update.bind(user,2,"id",6,null)).to.throw(Error)
    # 存在しないユーザ
    expect(user.update.bind(user,8,"name","ccc",null)).to.throw(Error)
    # 存在しないプロパティ
    expect(user.update.bind(user,1,"test","aaa",null)).to.throw(Error)

  it "ユーザを削除する", ->
    result_users = [
      {"id":1, "name":"tasuwo", "grade":"M1"},
      {"id":2, "name":"tozawa", "grade":"M2"},
      {"id":4, "name":"aaa", "grade":"M1"},
    ]
    userMock.expects('save').withArgs(result_users, null)
    user.remove(3, null)
    userMock.verify()
    userMock.restore()

    # 存在しないユーザ
    expect(user.remove.bind(user,5,null)).to.throw(Error)

