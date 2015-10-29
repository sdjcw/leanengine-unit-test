express = require('express')
path = require('path')
domain = require('domain')
cookieParser = require('cookie-parser')
bodyParser = require('body-parser')
url = require('url')
redis = require('redis')
async = require('async')
todos = require('./routes/todos')
cloud = require('./cloud')
AV = require('leanengine')

if process.env.NODE_ENV is 'production'
  client = require('redis').createClient(process.env.REDIS_URL_DeDp8JUq8)
  
  client.on 'error', (err) ->
    console.log 'redis err: %s', err

app = express()
# 设置 view 引擎
app.set 'views', path.join(__dirname, 'views')
app.set 'view engine', 'ejs'

app.use (req, res, next) ->
  d = domain.create()
  d.add(req)
  d.add(res)
  d.on 'error', (err) ->
    console.error('uncaughtException url=%s, msg=%s',
    req.url, err.stack || err.message || err)
    unless res.finished
      res.statusCode = 500
      res.setHeader('content-type', 'application/json; charset=UTF-8')
      res.end 'uncaughtException'
  d.run(next)

app.use express.static('public', {maxAge: 1000 * 3600 * 24})
# 加载云代码方法
app.use cloud
app.use bodyParser.json()
app.use bodyParser.urlencoded(extended: false)
app.use cookieParser()

app.use(AV.Cloud.CookieSession({ secret: 'my secret', maxAge: 3600000, fetchUser: false }))

app.get '/', (req, res) ->
  res.render 'index', currentTime: new Date
  return
# 可以将一类的路由单独保存在一个文件r
app.use '/todos', todos

app.get '/hello', (req, res) ->
  res.render 'hello', message: 'Congrats, you just set up your app!'
  return

app.post '/login', (req, res) ->
  AV.User.logIn(req.body.username, req.body.password).then (->
    res.redirect '/profile'
    return
  ), (error) ->
    res.status = 500
    res.send error
    return
  return

app.get '/logout', (req, res) ->
  AV.User.logOut()
  res.redirect '/profile'
  return

app.get '/profile', (req, res) ->
  if req.AV.user
    res.send req.AV.user
  else
    res.send {}
  return

app.get '/userMatching', (req, res) ->
  setTimeout (->
    # 为了更加靠谱的验证串号问题，走一次网络 IO
    query = new (AV.Query)(TestObject)
    query.get '54b625b7e4b020bb5129fe04',
      success: (obj) ->
        assert.equal obj.get('foo'), 'bar'
        res.send
          reqUser: req.AV.user
          currentUser: AV.User.current()
        return
      error: (err) ->
        res.success
          reqUser: req.user
          currentUser: AV.User.current()
        return
    return
  ), Math.floor(Math.random() * 2000 + 1)
  return

app.get '/runCool', (req, res) ->
  AV.Cloud.run 'cool', { name: 'dennis' },
    success: (result) ->
      res.send result
      return
    error: (err) ->
      res.send err
      return
  return

app.post '/hello', (req, res) ->
  res.render 'hello', message: 'hello,' + req.body.name
  return

app.post '/isCool', (req, res) ->
  cool = name.isACoolName(req.body.name)
  res.render 'hello', message: cool
  return

app.get '/time', (req, res) ->
  res.send new Date
  return

app.get '/sources', (req, res) ->
  fs.readdir '.', (err, data) ->
    res.send data
    return
  return

app.get '/path', (req, res) ->
  res.send
    '__filename': __filename
    '__dirname': __dirname
  return

app.get '/throwError', (req, res) ->
  setTimeout ->
    noThisMethod()
    return
  res.send 'ok'
  noThisMethod()
  return

app.get '/staticMiddlewareTest.html', (req, res) ->
  res.send 'dynamic resource'
  return

app.get '/session', (req, res, next) ->
  n = req.session.views or 0
  req.session.views = ++n
  res.end n + ' views'
  return

Test1 = AV.Object.extend 'Test1'
app.get '/createData', (req, res, next) ->
  count = req.query.count || 20
  result = []
  for i in [0..count]
    t = new Test1()
    t.set 'v', i
    result.push t
  AV.Object.saveAll result,
    success: ->
      res.send 'ok'
    error: (err) ->
      res.send err

app.get '/removeData', (req, res, next) ->
  query = new AV.Query(Test1)
  queryRemove(query).then ->
    res.send 'ok'
  , (err) ->
    res.send err

queryRemove = (query) ->
  promise = new AV.Promise()
  query.select()
  query.limit(1000)
  console.log 'delete start'

  count = 0
  async.doWhilst (callback) ->
    console.log 'delete'
    query.find().then (iterms) ->
      count = iterms.length
      console.log 'delete, count:', count
      return AV.Object.destroyAll(iterms)
    .then ->
      callback()
    , (err) ->
      console.log 'err:', err
      callback err
  , ->
    return count is 1000
  , (err) ->
    console.log 'all err:', err
    return promise.reject(err) if err?
    promise.resolve()
  return promise

app.get '/redis/info', (req, res, next) ->
  client.info (err, data) ->
    res.send data

app.get '/redis/:instance/info', (req, res, next) ->
  instance = req.params.instance
  host = req.query.host
  port = req.query.port
  require_pass = req.query.require_pass
  client = redis.createClient(port, host)
  client.auth(require_pass)
  client.info (err, data) ->
    client.quit()
    res.send data

app.get '/error', (req, res) ->
  setTimeout () ->
    noThisMethod()
  , 2000
  res.send 'ok'

# 如果任何路由都没匹配到，则认为 404
# 生成一个异常让后面的 err handler 捕获
app.use (req, res, next) ->
  err = new Error('Not Found')
  err.status = 404
  next err
  return
# error handlers
# 如果是开发环境，则将异常堆栈输出到页面，方便开发调试
if app.get('env') == 'development'
  app.use (err, req, res, next) ->
    res.status err.status or 500
    res.render 'error',
      message: err.message
      error: err
    return
# 如果是非开发环境，则页面只输出简单的错误信息
app.use (err, req, res, next) ->
  res.status err.status or 500
  res.render 'error',
    message: err.message
    error: {}

module.exports = app
