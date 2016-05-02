moment = require("moment")
fs = require('fs')
readline = require('readline')

google = require('googleapis')
OAuth2 = google.auth.OAuth2
auth_info = require("./auth.json")
CLIENT_SECRET = auth_info["clientSecret"]
CLIENT_ID     = auth_info["clientId"]
REDIRECT_URL  = "http://google.co.jp/"
oauth2Client = new OAuth2(CLIENT_ID, CLIENT_SECRET, REDIRECT_URL)
calendar = google.calendar({version: 'v3', auth: oauth2Client})
SCOPES = [ 'https://www.googleapis.com/auth/calendar.readonly' ]
TOKEN_DIR = (process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE) + '/.credentials/'
TOKEN_PATH = TOKEN_DIR + 'calendar-api-quickstart.json'

async = require("async")

exports.authorize = (robot, callback) ->
  fs.readFile TOKEN_PATH, (err, token) ->
    if err
      getNewToken oauth2Client, callback, robot
    else
      oauth2Client.setCredentials(JSON.parse(token))
      callback oauth2Client

getNewToken = (oauth2Client, callback, robot) ->
  authUrl = oauth2Client.generateAuthUrl(
    access_type: 'offline'
    scope: SCOPES)
  console.log 'Authorize this app by visiting this url: ', authUrl
  rl = readline.createInterface(
    input: process.stdin
    output: process.stdout
  )
  rl.question 'Enter the code from that page here: ', (code) ->
    rl.close()
    oauth2Client.getToken code, (err, token) ->
      if err
        console.log 'Error while trying to retrieve access token', err
        return
      oauth2Client.setCredentials(token)
      storeToken token
      callback oauth2Client

storeToken = (token) ->
  try
    fs.mkdirSync TOKEN_DIR
  catch err
    if err.code != 'EEXIST'
      throw err
  fs.writeFile TOKEN_PATH, JSON.stringify(token)
  console.log 'Token stored to ' + TOKEN_PATH
  return

exports.getEvents = (auth, tags, callback) ->
  moment.locale('ja')
  async.waterfall [
    (callback) ->
      calendar.events.list {
        auth: auth
        calendarId: 'primary'
        timeMin: moment().startOf('month').toDate().toISOString()
        timeMax: moment().endOf('month').toDate().toISOString()
        maxResults: 50
        singleEvents: true
        orderBy: 'startTime'
      }, (err, response) ->
        if err
          console.log 'There was an error contacting the Calendar service: ' + err
          return null
        callback null, response
    , (response, callback) ->
      allEvents = response.items
      if allEvents.length == 0
        return null
      events = []
      for i in [0..allEvents.length-1]
        event = allEvents[i]
        date = (event.start.dateTime or event.start.date).split("T")[0]
        summary = event.summary
        if summary.split(":")[0] in tags
          if date of events
            events[date].push(summary)
          else
            events[date]=[summary]
      callback null, events
    , (events, err, res) ->
      callback events
  ]
