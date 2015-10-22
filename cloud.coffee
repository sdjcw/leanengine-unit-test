AV = require('leanengine')
assert = require('assert')

###*
# 一个简单的云代码方法
###

AV.Cloud.define 'hello', (request, response) ->
  response.success 'Hello world!'

AV.Cloud.define 'login', (req, res) ->
  username = req.params.username
  password = req.params.password
  unless username? || password?
    err = new Error('username or password is null')
    err.code = 1234
    return res.error err
  AV.User.logIn username, password,
    success: (user) ->
      res.success user
    error: (user, err) ->
      res.error err

AV.Cloud.define 'testUser', (req, res) ->
  res.success req.user

AV.Cloud.define 'error', (req, res) ->
  noThisMethod()
  res.success()

AV.Cloud.beforeSave 'TestBiz', (req, res) ->
  console.log 'TestBiz beforeSave'
  biz = req.object
  biz.set 'beforeSaveUsername', req.user.get('username') if req.user
  biz.set 'beforeSave', true
  if req.user?.get('username') is 'unluckily'
    return res.error()
  res.success()

AV.Cloud.beforeSave 'TestObject', (req, res) ->
  console.log 'TestObject beforeSave'
  res.success()

AV.Cloud.afterSave 'TestBiz', (req) ->
  console.log 'TestBiz afterSave'
  biz = req.object
  console.log '>>', biz
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

AV.Cloud.onVerified 'sms', (request) ->
  console.log("onVerified: sms, user: " + request.object)

AV.Cloud.onLogin (request, response) ->
  console.log("on login:", request.object)
  if request.object.get('username') == 'noLogin'
    response.error('Forbidden')
  else
    response.success()

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

AV.Cloud.define 'status.topic', (request, response) ->
  response.success('Hello world!')

ComplexObject = AV.Object.extend('ComplexObject')

AV.Cloud.define 'complexObject', (request, response) ->
  query = new (AV.Query)(ComplexObject)
  query.include 'fileColumn'
  query.ascending 'createdAt'
  query.find success: (results) ->
    response.success
      foo: 'bar'
      i: 123
      obj:
        a: 'b'
        as: [ 1, 2, 3 ]
      t: new Date('2015-05-14T09:21:18.273Z')
      avObject: results[0]
      avObjects: results
    return
  return

AV.Cloud.define 'bareAVObject', (request, response) ->
  query = new (AV.Query)(ComplexObject)
  query.include 'fileColumn'
  query.ascending 'createdAt'
  query.find success: (results) ->
    response.success results[0]
    return
  return

AV.Cloud.define 'AVObjects', (request, response) ->
  query = new (AV.Query)(ComplexObject)
  query.include 'fileColumn'
  query.ascending 'createdAt'
  query.find success: (results) ->
    response.success results
    return
  return

AV.Cloud.define 'testAVObjectParams', (request, response) ->
  request.params.avObject.should.be.instanceof AV.Object
  request.params.avObject.get('name').should.be.equal 'avObject'
  request.params.avObject.get('pointerColumn').should.be.instanceof AV.User
  request.params.avFile.should.be.instanceof AV.File
  request.params.avObjects.forEach (object) ->
    object.should.be.instanceof AV.Object
    object.get('name').should.be.equal 'avObjects'
    return
  response.success()
  return

AV.Cloud.define 'testBareAVObjectParams', (request, response) ->
  request.params.should.be.instanceof AV.Object
  request.params.get('name').should.be.equal 'avObject'
  request.params.get('avFile').should.be.instanceof AV.File
  request.params.get('avFile').name().should.be.equal 'hello.txt'
  response.success()
  return

AV.Cloud.define 'testAVObjectsArrayParams', (request, response) ->
  request.params.forEach (object) ->
    object.get('name').should.be.equal 'avObject'
    object.get('avFile').should.be.instanceof AV.File
    object.get('avFile').name().should.be.equal 'hello.txt'
    return
  response.success()
  return
  
module.exports = AV.Cloud
