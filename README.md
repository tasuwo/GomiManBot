# gomi-man-bot

Gomi-man-bot retrieve duties from google calendar, assign users to them, and notify about it.

[日本語ドキュメントはこちら](./README_JA.md)

# Usage
Send `help` to gomi-man-bot and you'll get discriptions about enable commands.
The example procedure is following.

1. Create duty on google calendar. That time, Please add prefix `clean:` to dutie's name.
2. Save user to the app: `save me as <B4|M1|M2>`
3. Set channel for notification: `channel set <name>`
3. Assign users to duties: `assign users` (this procedure is automatically execute in the first day in the month)
4. You'll get notification in the day before the assigned day through the specified channel!

# Preparation
## Prepare for Google API Authorization

First you need to get client secret and client id for google api authorization on slack bot.

1. Through [Google api console](https://console.developers.google.com), create project, enable google calendar api, and get authorization information (client secret, client id)
2. Create `auth.json` under a scripts directory

``` json
{
    "clientSecret": "your client secret",
    "clientId": "your client id"
}
```

> [Slackと連携させたHubotに毎朝今日の予定をお知らせしてもらう - Qiita](http://qiita.com/tk3fftk/items/6ae172abc57f72eabeb2)

## Deploy to Heroku

1. Install [Heroku toolbelt](https://toolbelt.heroku.com/)
2. `heroku login`
3. `heroku create [app-name]`
4. `heroku addons:create redistogo:nano`
5. [Create slack integration](http://my.slack.com/services/new/hubot), retrieve hubot slack token, and set it to app by `heroku config:set HUBOT_SLACK_TOKEN=[your token]`
6. `heroku config:set HUBOT_HEROKU_KEEPALIVE_URL=[your bot app url]` (`url` is web_url in the result of `heroku apps:info`)
7. `git push heroku master`

> [Slack で Hubot を使えるようにする - Qiita](http://qiita.com/misopeso/items/1f418dd02e89234499b3)

## Authorize through slack

1. Throgh slack, send `auth get url` to gomi-man-bot and get url
2. Access the url and retrieve authorization code (`https://www.google.co.jp/?code=<your authorization code>&gws_rd=ssl`)
3. Get and store access token by `auth with <code>`

