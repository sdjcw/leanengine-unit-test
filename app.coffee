express = require('express')
path = require('path')
cookieParser = require('cookie-parser')
bodyParser = require('body-parser')
todos = require('./routes/todos')
cloud = require('./cloud')
app = express()
# 设置 view 引擎
app.set 'views', path.join(__dirname, 'views')
app.set 'view engine', 'ejs'
app.use express.static('public')
# 加载云代码方法
app.use cloud
app.use bodyParser.json()
app.use bodyParser.urlencoded(extended: false)
app.use cookieParser()
app.get '/', (req, res) ->
  res.render 'index', currentTime: new Date
  return
# 可以将一类的路由单独保存在一个文件中
app.use '/todos', todos
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
  return
module.exports = app

# ---
# generated by js2coffee 2.0.4
