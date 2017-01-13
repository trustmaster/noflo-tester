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
c.forwardBrackets =
  x: ['xy']
  y: ['xy']
c.process (input, output) ->
  return unless input.has 'x', 'y', (ip) -> ip.type is 'data'
  [x, y] = input.getData 'x', 'y'
  setTimeout ->
    output.sendDone x * y
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

    t.ins.x.post new noflo.IP 'data', 8
    t.ins.y.post new noflo.IP 'data', 3

  it 'should provide direct access to a wrapped component', ->
    chai.expect(t.c.inPorts).to.include.keys ['x', 'y']
    chai.expect(t.c.outPorts).to.include.keys 'xy'
    chai.expect(t.c.description).to.equal c.description

  it 'should pass all data chunks, brackets and counts on receive', (done) ->
    x = [1, 2, 3]
    y = [4, 5, 6]
    expectedData = [4, 10, 18]
    expectedBrackets = ['foo', 'bar']

    t.receive 'xy', (data, brackets, dataCount, bracketCount) ->
      chai.expect(data).to.eql expectedData
      chai.expect(brackets).to.eql expectedBrackets
      chai.expect(dataCount).to.equal expectedData.length
      chai.expect(bracketCount).to.equal expectedBrackets.length
      done()

    # Opening brackets
    t.ins.x.post new noflo.IP 'openBracket', 'foo'
    t.ins.x.post new noflo.IP 'openBracket', 'bar'
    t.ins.y.post new noflo.IP 'openBracket', 'foo'
    t.ins.y.post new noflo.IP 'openBracket', 'bar'

    for i in [0...3]
      t.ins.x.send x[i]
      t.ins.y.send y[i]

    # Closing brackets
    t.ins.x.post new noflo.IP 'closeBracket'
    t.ins.x.post new noflo.IP 'closeBracket'
    t.ins.y.post new noflo.IP 'closeBracket'
    t.ins.y.post new noflo.IP 'closeBracket'
