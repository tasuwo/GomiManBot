# gomi-man-bot

Google calendar に登録された掃除の日付を取得し，そこにユーザを自動で割り当て，当番前日になると通知をしてくれる Slack bot です．

# 使用方法
`help` コマンドで使用可能なコマンドの説明は閲覧可能だが，主な使用手順は以下．

1. Google カレンダーに掃除当番の日付を入力する．この時，名前の先頭に `clean:` を付加する
2. `save me as <B4|M1|M2>` により，ユーザ登録を行う
3. `channel set <name>` により，通知先のチャンネルを設定する
4. `assign users` により，掃除当番にユーザを割り当てる (この手順は，毎月1日に自動的に実行される)
5. その後，掃除当番前日の12時に，当番者に指定したチャンネルを通じて通知が飛ぶ

# 準備
## Google API 認証のための準備

1. [Google api console](https://console.developers.google.com)からプロジェクトを作成し，Google calendar API を有効にする．Client secret と client it が後の手順で必要．
2. 以下のような `auth.json` を作成し，scripts ディレクトリの直下に配置する

``` json
{
    "clientSecret": "your client secret",
    "clientId": "your client id"
}
```

> [Slackと連携させたHubotに毎朝今日の予定をお知らせしてもらう - Qiita](http://qiita.com/tk3fftk/items/6ae172abc57f72eabeb2)

## Heroku にデプロイする

1. [Heroku toolbelt](https://toolbelt.heroku.com/) をインストールする
2. `heroku login`
3. `heroku create [app-name]`
4. `heroku addons:create redistogo:nano`
5. [Slack において Hubot のインテグレーションを作成し](http://my.slack.com/services/new/hubot), slack token を取得する．その後，取得したトークンを `heroku config:set HUBOT_SLACK_TOKEN=[your token]` で設定する
6. `heroku config:set HUBOT_HEROKU_KEEPALIVE_URL=[your bot app url]` (`url` h `heroku apps:info` で表示される web_url でOK)
7. `git push heroku master`

> [Slack で Hubot を使えるようにする - Qiita](http://qiita.com/misopeso/items/1f418dd02e89234499b3)

## Slack からの認証

1. slack から bot に向けて `auth get url` すると，url が取得できる
2. 取得した url にアクセスするとリダイレクトするので，そのリダイレクト先の url から 認証コードを取得する(`https://www.google.co.jp/?code=<your authorization code>&gws_rd=ssl`)
3. `auth with <code>` でAPIへのアクセストークンを取得&保存する

