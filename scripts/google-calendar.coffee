moment = require("moment")
fs = require('fs')
readline = require('readline')
google = require('googleapis')
googleAuth = require('google-auth-library')
calendar = google.calendar('v3')
SCOPES = [ 'https://www.googleapis.com/auth/calendar.readonly' ]
TOKEN_DIR = (process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE) + '/.credentials/'
TOKEN_PATH = TOKEN_DIR + 'calendar-api-quickstart.json'
auth = require("./auth.json")

exports.authorize = (robot) ->
  clientSecret = auth["clientSecret"]
  clientId = auth["clientId"]
  redirectUrl = "https://www.google.co.jp/"
  auth = new googleAuth
  oauth2Client = new (auth.OAuth2)(clientId, clientSecret, redirectUrl)
  # Check if we have previously stored a token.
  fs.readFile TOKEN_PATH, (err, token) ->
    if err
      return getNewToken oauth2Client, robot
    else
      oauth2Client.credentials = JSON.parse(token)
      return oauth2Client
    return null
  return null

getNewToken = (oauth2Client, robot) ->
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
      oauth2Client.credentials = token
      storeToken token
      return oauth2Client
    return null
  return null

storeToken = (token) ->
  try
    fs.mkdirSync TOKEN_DIR
  catch err
    if err.code != 'EEXIST'
      throw err
  fs.writeFile TOKEN_PATH, JSON.stringify(token)
  console.log 'Token stored to ' + TOKEN_PATH
  return

exports.getEvents = (auth, tags) ->
  moment.locale('ja')
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
    allEvents = response.items
    if allEvents.length == 0
      return null
    else
      events = []
      for i in [0..allEvents.length-1]
        event = allEvents[i]
        date = event.start.dateTime.split("T")[0]
        summary = event.summary
        if summary.split(":")[0] in tags
          if date of events
            events[date].push(summary)
          else
            events[date]=[summary]
      return events
    return null
  return null

