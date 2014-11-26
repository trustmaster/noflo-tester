chai = require 'chai'
noflo = require 'noflo'
Tester = require '../lib/tester'

# A simple component
c = new noflo.Component
c.description = 'Multiplies its inputs'
c.inPorts = new noflo.InPorts
  x:
    datatype: 'int'
  y:
    datatype: 'int'
c.outPorts.add 'xy', datatype: 'int'
noflo.helpers.WirePattern c,
  in: ['x', 'y']
  out: 'xy'
  async: true
  forwardGroups: true
, (input, groups, out, done) ->
  setTimeout ->
    out.send input.x * input.y
    done()
  , 0


describe 'Simple component tester', ->
  t = new Tester c

  before (done) ->
    t.start ->
      done()

  it 'should send data to multiple ins and expect a result', (done) ->
    t.receive 'xy', (data) ->
      chai.expect(data).to.equal 30
      done()

    t.send
      x: 5
      y: 6

  it 'should provide direct access to ports and events', (done) ->
    t.outs.xy.on 'data', (data) ->
      chai.expect(data).to.equal 24
      done()

    t.ins.x.send 8
    t.ins.x.disconnect()
    t.ins.y.send 3
    t.ins.y.disconnect()

  it 'should provide direct access to a wrapped component', ->
    chai.expect(t.c.inPorts).to.include.keys ['x', 'y']
    chai.expect(t.c.outPorts).to.include.keys 'xy'
    chai.expect(t.c.description).to.equal c.description

  it 'should pass all data chunks, groups and counts on receive', (done) ->
    x = [1, 2, 3]
    y = [4, 5, 6]
    expectedData = [4, 10, 18]
    expectedGroups = ['foo', 'bar']

    t.receive 'xy', (data, groups, dataCount, groupCount) ->
      chai.expect(data).to.eql expectedData
      chai.expect(groups).to.eql expectedGroups
      chai.expect(dataCount).to.equal expectedData.length
      chai.expect(groupCount).to.equal expectedGroups.length
      done()

    # Sending groups
    t.ins.x.beginGroup 'foo'
    t.ins.x.beginGroup 'bar'
    t.ins.y.beginGroup 'foo'
    t.ins.y.beginGroup 'bar'

    for i in [0...3]
      t.ins.x.send x[i]
      t.ins.y.send y[i]

    # endGroup affects groupCount
    t.ins.x.endGroup()
    t.ins.x.endGroup()
    t.ins.y.endGroup()
    t.ins.y.endGroup()

    # receive is only triggered after disconnect
    t.ins.x.disconnect()
    t.ins.y.disconnect()
