NoFlo component/graph testing wrapper
============

Tester wraps a component to provide a convenient interface compatible with any testing paradigm: TDD/BDD/whatever.

## Benefits

* Reduces boilerplate to set up a component testbed.
* Provides common high-level methods.
* Provides low-level access to the component, ports and events.
* Compatible with different testing frameworks and complex test cases.

## Getting started

Install `noflo-tester` and add it to your project's dev dependecies:

```
npm install --save-dev noflo-tester
```

Require it in your specs/tests:

```coffeescript
Tester = require 'noflo-tester'
```

Use methods described below and run the tests just as you do it normally with your favorite testing framework.

## API

Explanations below contain examples in CoffeeScript using Mocha and Chai in BDD style. You can also write your tests in JavaScript, using any other framework or style.

### Loading a component

First you need to create a new Tester object to wrap your component or graph:

```coffeescript
t = new Tester 'my-noflo-app/Multiplier'
```

The constructor accepts either a full component name (including namespace prefix), or an already instantiated component object, or a function returning such an object.

In general, components are loaded and wired up asynchronously, so you need to start the tester like this before running any tests:

```coffeescript
before (done) ->
  t.start (err, instance) ->
    return done err if err # Error handling, optional
    # instance contains a ready to use component
    done()
```

**Advanced options**

If the component to be tested is a NoFlo graph, you can pass custom event handlers to the Tester constructor:

```coffeescript
t = new Tester 'my-noflo-app/Multiplier',
  load: (err, instance) ->
    # This is call after loading the graph
  ready: (err, instance) ->
    # This is called when the network is ready to be attached
```

### Sending inputs and expecting output

A high-level `receive` method listens on output ports for data and groups until a `disconnect` event.

A high-level `send` methods sends data followed by a disconnect to one or more input ports.

Here is an example that tests a simple multiplier component:

```coffeescript
t.receive 'xy', (data) ->
  chai.expect(data).to.equal 30
  done()

t.send
  x: 5
  y: 6
```

Note that `receive` is called before `send`, because it binds event handlers asynchronously, while `send` is almost an instant operation.

Short syntax for `send` method to send data and disconnect to just one inport looks like this:

```coffeescript
t.send 'x', 123
```

### Direct access to component, ports and events

In more complex test cases you might want to send IPs and handle particular events manually:

```coffeescript
t.outs.xy.on 'data', (data) ->
  chai.expect(data).to.equal 24
  done()

t.ins.x.send 8
t.ins.x.disconnect()
t.ins.y.send 3
t.ins.y.disconnect()
```

Tester object provides `ins` and `outs` hashmaps of sockets attached to the component.

You can also access the component directly via `c` property:

```coffeescript
if t.c.outPorts.error.isAttached()
  # Do something
```

### Receiving multiple data chunks and groups

As `receive` is triggered by a `disconnect` event, there might be multiple `data` packets in the transmission and also some `group` bracket IPs. In such case they are available as arrays and counts in the callback arguments:

```coffeescript
t.receive 'xy', (data, groups, dataCount, groupCount) ->
  chai.expect(data).to.eql [4, 10, 18]
  chai.expect(dataCount).to.equal 3
  chai.expect(groups).to.eql ['foo', 'bar']
  chai.expect(groupCount).to.equal 2
  done()
```

Note that `groupCount` counts only closed groups via `endGroup` events, while `groups` contains unique groups sent to the output.

### Receiving from multiple output ports

If a component sends output to multiple ports at the same time and you need to test results from all of them at once, that may require some syncrhonization spaghetti in your specs. But `receive` simplifies it by accepting a hashmap and returning a Promise that is resolved when results from all outputs in the map have been received:

```coffeescript
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
```

### Using promises to chain subsequent receives

The `receive` method returns a Promise resolved when a transmission is received, so you can chain subsequent transmissions in a thenable way, e.g.:

```coffeescript
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
```

### Examples

See complete BDD-style examples in `spec` folder.

## Development

The first thing to start developing this package is:

```
npm install
```

Then run bundled Mocha specs:

```
npm test
```

Then feel free to hack on the `lib` and `specs`.
