should = require('should')
request = require('supertest')
async = require('async')

#app = 'http://localhost:3000'
app = 'http://leanengine-unit-test.avosapps.com'

testUser1 = {
  id: '54fd6a03e4b06c41e00b1f40'
  username: 'admin'
  password: 'admin'
}

testUser2 = {
  id: '55d586f100b030964c681082'
  username: 'test1'
  password: 'test1'
}

profile = (testUser, done) ->
  request(app).get('/profile')
    .set('Cookie', testUser.cookie)
    .expect 200, (err, res) ->
      throw err if err?
      res.body.objectId.should.equal testUser.id
      done()

describe 'cookieSessionTest', ->
  
  it 'profile_testUser1', (done) ->
    request(app).post("/login")
      .send testUser1
      .expect 302, (err, res) ->
        throw err if err?
        cookies = res.headers['set-cookie']
        testUser1.cookie = cookies[0].split(' ')[0] + '; ' + cookies[1].split(' ')[0]
        profile testUser1, done

  it 'profile_testUser2', (done) ->
    request(app).post("/login")
      .send testUser2
      .expect 302, (err, res) ->
        throw err if err?
        cookies = res.headers['set-cookie']
        testUser2.cookie = cookies[0].split(' ')[0] + '; ' + cookies[1].split(' ')[0]
        profile testUser2, done

  it 'profile', (done) ->
    this.timeout 30000
    async.parallel [
      (cb) ->
        count = 0
        async.whilst(
          () ->
            return count < 1000
          (cb) ->
            count++
            console.log 1
            profile testUser1, cb
          (err) ->
            cb()
        )
      (cb) ->
        count = 0
        async.whilst(
          () ->
            return count < 1000
          (cb) ->
            count++
            console.log 2
            profile testUser2, cb
          (err) ->
            cb()
        )
    ], (err) ->
      throw err if err?
      done()
