should = require('should')
request = require('supertest')

appId = '4h2h4okwiyn8b6cle0oig00vitayum8ephrlsvg7xo8o19ne'
appKey = '3xjj1qw91cr3ygjq9lt0g8c3qpet38rrxtwmmp0yffyoy2t4'

request = request 'https://api.leancloud.cn'

describe 'cloud', ->
  describe 'hook', ->

    objectId = null

    it 'beforeSave afterSave afterUpdate', (done) ->
      request.post '/1.1/classes/TestBiz'
      .set 'X-AVOSCloud-Application-Id', appId
      .set 'X-AVOSCloud-Application-Key', appKey
      .set 'Content-Type', 'application/json'
      .send
        foo: 'bar'
      .expect 201, (err, res) ->
        location = res.header.location
        should.exist location
        objectId = location.substring location.lastIndexOf('/') + 1
        request.get "/1.1/classes/TestBiz/#{objectId}"
        .set 'X-AVOSCloud-Application-Id', appId
        .set 'X-AVOSCloud-Application-Key', appKey
        .expect 200, (err, res) ->
          res.body.should.have.properties
            beforeSave: true
            afterSave: true
            afterUpdate: true
            foo: 'bar'
          done()

    it 'afterDelete', (done) ->
      request.delete "/1.1/classes/TestBiz/#{objectId}"
      .set 'X-AVOSCloud-Application-Id', appId
      .set 'X-AVOSCloud-Application-Key', appKey
      .expect 200, (err, res) ->
        request.get "/1.1/classes/DeleteBiz?#{encodeURI('where={"oriId":"' + objectId + '"}')}"
        .set 'X-AVOSCloud-Application-Id', appId
        .set 'X-AVOSCloud-Application-Key', appKey
        .expect 200, (err, res) ->
          res.body.results[0].should.have.properties
            afterDelete: true
            oriId: objectId
          done()

  describe 'hook user', ->

    sessionToken = '3267fscy0q4g3i4yc9uq9rqqv'
    objectId = null

    it 'beforeSave afterSave afterUpdate', (done) ->
      request.post '/1.1/classes/TestBiz'
      .set 'X-AVOSCloud-Application-Id', appId
      .set 'X-AVOSCloud-Application-Key', appKey
      .set 'X-AVOSCloud-Session-Token', sessionToken
      .set 'X-AVOSCloud-Application-Production', 0
      .set 'Content-Type', 'application/json'
      .send
        foo: 'bar'
      .expect 201, (err, res) ->
        location = res.header.location
        should.exist location
        objectId = location.substring location.lastIndexOf('/') + 1
        request.get "/1.1/classes/TestBiz/#{objectId}"
        .set 'X-AVOSCloud-Application-Id', appId
        .set 'X-AVOSCloud-Application-Key', appKey
        .set 'X-AVOSCloud-Session-Token', sessionToken
        .set 'X-AVOSCloud-Application-Production', 0
        .expect 200, (err, res) ->
          res.body.should.have.properties
            beforeSave: true
            beforeSaveUsername: 'zhangsan'
            afterSave: true
            afterSaveUsername: 'zhangsan'
            afterUpdate: true
            afterUpdateUsername: 'zhangsan'
            foo: 'bar'
          done()

    it 'afterDelete', (done) ->
      request.delete "/1.1/classes/TestBiz/#{objectId}"
      .set 'X-AVOSCloud-Application-Id', appId
      .set 'X-AVOSCloud-Application-Key', appKey
      .set 'X-AVOSCloud-Session-Token', sessionToken
      .expect 200, (err, res) ->
        request.get "/1.1/classes/DeleteBiz?#{encodeURI('where={"oriId":"' + objectId + '"}')}"
        .set 'X-AVOSCloud-Application-Id', appId
        .set 'X-AVOSCloud-Application-Key', appKey
        .expect 200, (err, res) ->
          res.body.results[0].should.have.properties
            afterDelete: true
            afterDeleteUsername: 'zhangsan'
            oriId: objectId
          done()
