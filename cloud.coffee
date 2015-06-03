AV = require('leanengine')
assert = require('assert')

###*
# 一个简单的云代码方法
###

AV.Cloud.define 'hello', (request, response) ->
  response.success 'Hello world!'

AV.Cloud.define 'testUser', (req, res) ->
  response.success req.user

AV.Cloud.beforeSave 'TestBiz', (req, res) ->
  console.log 'TestBiz beforeSave'
  biz = req.object
  biz.set 'beforeSaveUsername', req.user.get('username') if req.user
  biz.set 'beforeSave', true
  if req.user?.get('username') is 'unluckily'
    return res.error()
  res.success()

AV.Cloud.afterSave 'TestBiz', (req) ->
  console.log 'TestBiz afterSave'
  biz = req.object
  biz.set 'afterSaveUsername', req.user.get('username') if req.user
  biz.set 'afterSave', true
  currentUser = AV.User.current()
  console.log 'currentUser:', currentUser
  console.log 'req.user:', req.user
  biz.save
    error: (obj, err) ->
      console.log err
      assert.ifError err

AV.Cloud.afterUpdate 'TestBiz', (req) ->
  console.log 'TestBiz afterUpdate', req
  biz = req.object
  biz.set 'afterUpdateUsername', req.user.get('username') if req.user
  biz.set 'afterUpdate', true
  biz.save
    error: (obj, err) ->
      console.log err
      assert.ifError err

AV.Cloud.beforeDelete 'TestBiz', (req, res) ->
  console.log 'TestBiz beforeDelete'
  if req.user?.get('username') is 'unluckily'
    return res.error()
  res.success()

DeleteBiz = AV.Object.extend 'DeleteBiz'

AV.Cloud.afterDelete 'TestBiz', (req) ->
  console.log 'TestBiz afterDelete'
  deleteBiz = new DeleteBiz()
  deleteBiz.set 'oriId', req.object.id
  deleteBiz.set 'raw', JSON.stringify req.object
  deleteBiz.set 'afterDeleteUsername', req.user.get('username') if req.user
  deleteBiz.set 'afterDelete', true
  deleteBiz.save
    error: (obj, err) ->
      console.log err
      assert.ifError err
  
module.exports = AV.Cloud
