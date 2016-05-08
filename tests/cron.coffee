sinon = require 'sinon'
chai = require 'chai'
expect = chai.expect
chai.should()

cron = require('./../scripts/cron.coffee')
as   = require('./../scripts/assignment.coffee')

describe 'Cronに関するテスト', ->

  context "日時文字列 <=> cron設定 変換", ->
    it "日時の文字列をcronの設定に変換する", ->
      expect(cron.translateDateToCronSetting("2016-10-02") == "0 0 12 2 9 *").be.true
      expect(cron.translateDateToCronSetting("2016-01-12") == "0 0 12 12 0 *").be.true

    it "不正な引数が与えられた場合には例外を発行する", ->
      expect(cron.translateDateToCronSetting.bind(cron, "20160112")).to.throw(Error)
      expect(cron.translateDateToCronSetting.bind(cron, 20160112)).to.throw(Error)
      expect(cron.translateDateToCronSetting.bind(cron, null)).to.throw(Error)

  context "cron設定の日数をdecrementする", ->
    it "日付を減らす(日付が1日, 月が1月の場合についてもテスト)", ->
      expect(cron.decrementDayOfCronSetting("0 0 12 2 3 *")=="0 0 12 1 3 *").be.true
      expect(cron.decrementDayOfCronSetting("0 0 12 1 3 *")=="0 0 12 29 2 *").be.true
      expect(cron.decrementDayOfCronSetting("0 0 12 1 0 *")=="0 0 12 29 11 *").be.true

    it "不正な引数が与えられた場合には例外を発行する", ->
      expect(cron.decrementDayOfCronSetting.bind(cron, null)).to.throw(Error)
      expect(cron.decrementDayOfCronSetting.bind(cron, "0 12 * *")).to.throw(Error)

  context "定期的な cron job の実行テスト", (done) ->
    clock = null
    assignments = [
        { date: "2016-10-03" }
        { date: "2016-10-06" }
    ]
    getNotifyChannelStub = sinon.stub(cron, 'getNotifyChannel')

    beforeEach ->
      getNotifyChannelStub.returns(null)

    afterEach ->
      if clock?
        clock.restore()

    it "毎月一日に通知を行う", ->
      asMock = sinon.mock(as)
      clock = sinon.useFakeTimers(new Date(2016, 10, 1, 11, 59).getTime())
      asMock.expects("assign").once()

      cron.startJobs(null)
      clock.tick(60 * 1000)

      asMock.verify()
      asMock.restore()

    it "当番の前日にユーザに向けて通知を行う", ->
      crMock = sinon.mock(cron)
      clock = sinon.useFakeTimers(new Date(2016, 9, 2, 11, 59).getTime())
      crMock.expects("sendMessage").twice()
      cron.startAssignCronJobs(null, assignments)
      clock.tick(60 * 1000)
      clock.tick(2 * 3 * 24 * 60 * 60 * 1000)

      crMock.verify()
      crMock.restore()
