chai = require 'chai'
noflo = require 'noflo'
Tester = require '../lib/tester'

# Async divider
c = new noflo.Component
c.description = 'Divides integers into integers'
c.inPorts = new noflo.InPorts
  dividend:
    datatype: 'int'
  divisor:
    datatype: 'int'
c.outPorts = new noflo.OutPorts
  quotient:
    datatype: 'int'
  remainder:
    datatype: 'int'
  error:
    datatype: 'object'

noflo.helpers.WirePattern c,
  in: ['dividend', 'divisor']
  out: ['quotient', 'remainder']
  async: true
  forwardGroups: true
, (input, groups, outs, done) ->
  setTimeout ->
    return done new Error 'Division by 0' if input.divisor == 0
    if outs.quotient.isAttached()
      outs.quotient.send parseInt input.dividend / input.divisor, 10
    if outs.remainder.isAttached()
      outs.remainder.send parseInt input.dividend % input.divisor, 10
    done()
  , 0


describe 'Synchronization of received packets', ->
  t = new Tester c

  before (done) ->
    t.start ->
      done()

  it 'should wait for result from multiple outputs', (done) ->
    div = null
    mod = null

    t.receive
      quotient: (data) ->
        div = data
      remainder: (data) ->
        mod = data
    .then ->
      chai.expect(div).to.equal 3
      chai.expect(mod).to.equal 2
      done()

    t.send
      dividend: 11
      divisor: 3

  it 'should chain subsequent receives via promises', (done) ->
    t.receive 'quotient', (data) ->
      chai.expect(data).to.equal 5
    .then ->
      t.receive 'quotient', (data) ->
        chai.expect(data).to.equal 8
        done()
      t.send
        dividend: 56
        divisor: 7
    t.send
      dividend: 30
      divisor: 6
