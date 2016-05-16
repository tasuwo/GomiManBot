sinon = require 'sinon'
chai = require 'chai'
expect = chai.expect
chai.should()

user = require('./../scripts/user.coffee')

describe 'ユーザデータに対する操作',->
  usersData = null
  getAllStub = null
  userMock = null

  beforeEach ->
    usersData = [
      {"id":1, "name":"tasuwo", "grade":"M1"},
      {"id":2, "name":"tozawa", "grade":"M2"},
      {"id":3, "name":"tetsuwo", "grade":"B4"},
      {"id":4, "name":"aaa", "grade":"M1"},
    ]
    userMock = sinon.mock(user)
    getAllStub = sinon.stub(user, 'getAll')
    getAllStub.returns(usersData)

  afterEach ->
    user.getAll.restore()

  it "ユーザを学年順にソートする", ->
    sortedUsers = user.sortUsersByGrade(usersData)
    expect(sortedUsers[0]["grade"]=="B4").be.true
    expect(sortedUsers[1]["grade"]=="M1").be.true
    expect(sortedUsers[2]["grade"]=="M1").be.true
    expect(sortedUsers[3]["grade"]=="M2").be.true

  it "ユーザを学籍番号順にソートする", ->
    tmpData = usersData
    tmpData[0]["stNo"]="16nm722x"
    tmpData[1]["stNo"]="15nm722x"
    tmpData[2]["stNo"]="11t4054x"
    tmpData[3]["stNo"]="16nm701x"
    sortedUsers = user.sortUsersByStNo(usersData)
    expect(sortedUsers[0]["stNo"]=="11t4054x").be.true
    expect(sortedUsers[1]["stNo"]=="16nm701x").be.true
    expect(sortedUsers[2]["stNo"]=="16nm722x").be.true
    expect(sortedUsers[3]["stNo"]=="15nm722x").be.true

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

  context '学籍番号クラスのテスト', ->
    it '学籍番号の生成', ->
      bachelor = new user.StudentNumber("11t4054x")
      master   = new user.StudentNumber("15nm722x")
      noStudent = new user.StudentNumber("aaa")
      expect(bachelor.degree=="bachelor").be.true
      expect(master.degree=="master").be.true
      expect(noStudent.degree==null).be.true
    it '学籍番号の比較', ->
      bachelor1 = new user.StudentNumber("11t4054x")
      bachelor2 = new user.StudentNumber("10t4054x")
      bachelor3 = new user.StudentNumber("11t4001x")
      expect(bachelor1.earlierThan(bachelor2)).be.true
      expect(bachelor1.earlierThan(bachelor3)).be.false
      expect(bachelor1.earlierThan(bachelor1)).be.false
      master1 = new user.StudentNumber("15nm722x")
      master2 = new user.StudentNumber("14nm722x")
      master3 = new user.StudentNumber("15nm701x")
      expect(master1.earlierThan(master2)).be.true
      expect(master1.earlierThan(master3)).be.false
      expect(master1.earlierThan(master1)).be.false

      expect(master1.earlierThan(bachelor1)).be.false
      expect(bachelor1.earlierThan(master1)).be.true


