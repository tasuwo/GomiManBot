sinon = require 'sinon'
chai = require 'chai'
expect = chai.expect
chai.should()

Converter = require('./../scripts/cron.coffee').CronSettingConverter
CronJobManager = require('./../scripts/cron.coffee').CronJobManager
Assignment = require('./../scripts/assignment.coffee')

describe 'Cronに関するテスト', ->
  context "Cron設定の変換に関するテスト", ->
    it "日時の文字列をcronの設定に変換する", ->
      expect(Converter.convertDateToCronSetting("2016-10-02") == "0 0 12 2 9 *").be.true
      expect(Converter.convertDateToCronSetting("2016-01-12") == "0 0 12 12 0 *").be.true

    it "日付を減らす(日付が1日, 月が1月の場合についてもテスト)", ->
      expect(Converter.convertCronSettingToDayBefore("0 0 12 2 3 *")=="0 0 12 1 3 *").be.true
      expect(Converter.convertCronSettingToDayBefore("0 0 12 1 3 *")=="0 0 12 29 2 *").be.true
      expect(Converter.convertCronSettingToDayBefore("0 0 12 1 0 *")=="0 0 12 29 11 *").be.true

    it "不正な引数が与えられた場合には例外を発行する", ->
      expect(Converter.convertCronSettingToDayBefore.bind(Converter, null)).to.throw(Error)
      expect(Converter.convertCronSettingToDayBefore.bind(Converter, "0 12 * *")).to.throw(Error)
      expect(Converter.convertDateToCronSetting.bind(Converter, "20160112")).to.throw(Error)
      expect(Converter.convertDateToCronSetting.bind(Converter, 20160112)).to.throw(Error)
      expect(Converter.convertDateToCronSetting.bind(Converter, null)).to.throw(Error)

  context "定期的なCronJobの実行テスト", (done) ->
    clock = null
    manager = null
    assignmentList = [ { date: "2016-10-03" }, { date: "2016-10-06" } ]

    before ->
      manager = new CronJobManager null

    afterEach ->
      if clock?
        clock.restore()

    it "毎月一日に通知を行う", ->
      assignmentMock = sinon.mock(manager.assignment)
      clock = sinon.useFakeTimers(new Date(2016, 10, 1, 11, 59).getTime())
      assignmentMock.expects("assign").once()

      manager.startMonthlyJobTo(null)
      clock.tick(60 * 1000)

      assignmentMock.verify()
      assignmentMock.restore()

    it "当番の前日にユーザに向けて通知を行う", ->
      cronMock = sinon.mock(manager)
      clock = sinon.useFakeTimers(new Date(2016, 9, 2, 11, 59).getTime())
      cronMock.expects("_sendMessage").twice()

      manager.startJobsBasedOn(assignmentList, null)
      clock.tick(60 * 1000)
      clock.tick(2 * 3 * 24 * 60 * 60 * 1000)

      cronMock.verify()
      cronMock.restore()
