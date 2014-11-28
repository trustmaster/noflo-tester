chai = require 'chai'
noflo = require 'noflo'
Tester = require '../lib/tester'

# A simple component
c = new noflo.Component
c.description = 'Echoes its input to the output'
c.inPorts.add 'in',
c.outPorts.add 'out'
noflo.helpers.WirePattern c,
  forwardGroups: true
, (input, groups, out) ->
  out.send input


describe 'Simple component tester', ->
  t = new Tester c

  before (done) ->
    t.start ->
      done()

  it 'should send data to a single input and expect the result', (done) ->
    t.receive 'out', (data) ->
      chai.expect(data).to.equal 'foobar'
      done()

    t.send 'in', 'foobar'
