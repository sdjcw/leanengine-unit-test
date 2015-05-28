router = require('express').Router()
AV = require('leanengine')
# `AV.Object.extend` 方法一定要放在全局变量，否则会造成堆栈溢出。
# 详见： https://leancloud.cn/docs/js_guide.html#对象
Todo = AV.Object.extend('Todo')
# 查询 Todo 列表
router.get '/', (req, res, next) ->
  query = new (AV.Query)(Todo)
  query.find
    success: (results) ->
      res.render 'todos',
        title: 'TODO 列表'
        todos: results
      return
    error: (err) ->
      if err.code == 101
        # 该错误的信息为：{ code: 101, message: 'Class or object doesn\'t exists.' }，说明 Todo 数据表还未创建，所以返回空的 Todo 列表。
        # 具体的错误代码详见：https://leancloud.cn/docs/error_code.html
        res.render 'todos',
          title: 'TODO 列表'
          todos: []
      else
        next err
      return
  return
# 新增 Todo 项目
router.post '/', (req, res, next) ->
  content = req.body.content
  todo = new Todo
  todo.set 'content', content
  todo.save null,
    success: (todo) ->
      res.redirect '/todos'
      return
    error: (err) ->
      next err
      return
  return
module.exports = router

# ---
# generated by js2coffee 2.0.4