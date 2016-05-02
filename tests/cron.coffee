chai = require 'chai'
expect = chai.expect
chai.should()

cron = require('./../scripts/cron.coffee')

describe 'ユーザデータに対する操作', ->

  it "日時の文字列をcronの設定に変換する", ->
    expect(cron.translateDateToCronSetting("2016-10-02") == "0 12 2 10 * *").be.true
    expect(cron.translateDateToCronSetting("2016-01-12") == "0 12 12 1 * *").be.true

  it "不正な引数が与えられた場合には例外を発行する", ->
    expect(cron.translateDateToCronSetting.bind(cron, "20160112")).to.throw(Error)
    expect(cron.translateDateToCronSetting.bind(cron, 20160112)).to.throw(Error)
    expect(cron.translateDateToCronSetting.bind(cron, null)).to.throw(Error)
