# Making a Collaborative Piano Using Functional Reactive Programming (FRP)

To learn more about functional reactive programming, I started
making a simple collaborative piano using JavaScript/CoffeeScript. 
This blog post shows how Functional Reactive Programming can make the 
task of taking multiple event inputs and merging them into one discrete 
sequence of interactions really easy – a task that could otherwise be 
potentially complex and very unstructured and hard to read.

## Background

Functional Reactive Programming (FRP) is a programming paradigm combining
functional and reactive programming. By using FRP one can use functional
programming _reacting_ on either continuous or discrete signals in 
sequence. This enables us to be declarative rather than imperative. FRP is not 
a new concept, and as far as I can tell, it stems from a system developed by 
Conal Elliot and Paul Hudak in 1997 called FRAN. FRAN was a collection of 
functions and data types for composing interactive animations [1].

In FRP we operate with two different terms; _behaviours_ and _events_.
A behaviour represent a value that varies over continuous time, like a 
mouse movement or seconds over time. [Juha Paananen](https://twitter.com/raimohanska) (of 
[bacon.js](https://github.com/baconjs/bacon.js)) described FRP using an 
analogy to spreadsheets: In traditional programming if we define 
```a = b + c```, ```a``` will always be the sum of ```b``` 
and ```c``` in that given time, but in spreadsheets, if we have 
```a = b + c``` and either ```b``` or ```c``` changes, ```a``` will 
change accordingly. In this example, ```b```, ```c``` and the ```a``` 
would be behaviours. A behaviour, or signal, will always have a value, 
unlike its counterpart events.

Events are sequences of discrete values over time such as clicks, keystrokes or 
web socket emits. The concept of events is most often represented as a stream. 
In between the discrete values, the event has no value set. When an event occurs, 
a given time and value is set. An event can be transformed to a behaviour by 
holding on to the most recent value. This way, the event would have a value at 
every given time, as with a behaviour. We'll see some examples of events when 
implementing the collaborative piano.

FRP enables us to use map and filter on events and behaviours, 
just like we could do with regular sequences. Using functional programming techniques
we can generate results derived from immutable behaviours, events or a set of either
behaviours or events. One can merge and transform behaviours and events 
in a declarative manner. This opens up the possibility of creating complex transformations 
on one or more merged behaviours or events by composing several simpler transformations, 
in the same way one composes functions in functional programming.

The reactive nature of FRP is perfect for doing UI interaction and/or 
animation, be it input from form fields, clicks, key presses,
scrolling or what have you. We'll see examples of this when implementing the
collaborative piano.

## Implementing the Piano

![Screenshot of the Piano](https://github.com/mikaelbr/frp-piano/raw/master/screenshot.png "Piano Screenshot")

The goal is to make a piano. The piano should make sound on mouse clicks and 
when the keyboard keys ```1``` through ```8``` is pressed. In addition, we 
will broadcast to other piano players what key we played. To keep it simple 
we won't have multiple channels, and no limitations of the number of players. 

We will be implementing a piano using CoffeeScript on the client side, and
a short server side implementation for handling WebSockets in Node.JS. 

For this example we will use [bacon.js](https://github.com/baconjs/bacon.js). 
We could just as easily have used something like [RxJS](https://github.com/Reactive-Extensions/RxJS), 
which is a set of reactive extensions for javascript. Almost like having LINQ. But we will go for
 Bacon.js, as it is more aimed at FRP, having a distinction between
behaviours and events, whereas RxJS only has the concept of _Observables_.

In Bacon the behaviours are called Properties and events are called EventStreams.
Bacon has implementations for doing map, filter, merge, triggering actions, 
transforming events to behaviours (properties) and much more. For this example
we will only be using events; clicks, key press, web sockets.

For the actual piano-key to sound, a modified version of a open source library 
called [js-piano](https://github.com/michaelmp/js-piano) is used. The code is 
available as a gist here: https://gist.github.com/mikaelbr/6569804. The usage
looks like this ```player(key)``` where the key can be A2, E3, etc.

The markup is simple enough: an un-ordered list setting the piano keys as
data-note attributes. Full markup of the piano is shown in [this gist](https://gist.github.com/mikaelbr/6661872).

I like reading code as a learning tool, so for this blog post, we'll just see the
code with annotations describing the action taken. We'll take
each event at the time and gradually build our piano, starting with clicks, 
then moving on to key press and the web socket.

### Play sounds on click

```coffeescript
# Create event streams for clicks on the piano tuts.

# Fetch the piano-element
clicks = $("#piano")
  # Attach to click event as stream
  .asEventStream("click", ".clickable")
  # Perform an action on the event signal
  .doAction(".preventDefault")
  # Map events and retrieve the data-note
  .map (e) ->
    $(e.currentTarget).attr "data-note"
```

As a result, we now have the event stream ```clicks```, which now contains a stream
of click events mapped to piano keys. We need to use this information somehow. We can either add
subscribers, as with promises, or we can set an action to be executed on a value. For
our purpose, executing an action on a new value will suffice.

```coffeescript
# where player is as defined player(key)
clicks.onValue player 
```

### Adding ```keypress``` Support

Let's create another event stream, for key presses.

```coffeescript
# Listen for keypress on the document
keypress = $(document)
  # Attach to keypress event as stream
  .asEventStream("keypress")
  # Extract keyCode
  .map(".keyCode")
  # Remove all signals that's not the keys 1 through 8
  .filter (code) ->
    code >= 49 && code <= 56
  # translate to piano keys
  .map (code) ->
    scale[code - 47]
```

The result, will as with the ```clicks``` event stream, is a stream of keypress events mapped piano keys.

We can now ```merge``` these two streams in order to execute the same action on both click 
and key press. We remove the previous onValue, merge clicks and keypress streams 
to form a single event stream and add onValue again.

```coffeescript
notes = clicks
  # merge keypress creating a new event stream
  .merge(keypress)
  # play sound
  .onValue(player)
```

Since all event streams are immutable they generate a new stream called ```notes``` when merged.

### Appending Collaborative Functionality

We need a server side component to handle the web sockets. We'll do a quick implementation
using Node.js, ExpressJS and Socket.io:

```javascript
var express = require('express')
  , app = express()
  , server = require('http').createServer(app)
// Serve static files
app.use(express.static(__dirname + '/public'));

// Create WS server
var io = require('socket.io').listen(server);
// When a new client connects
io.sockets.on('connection', function (socket) {
  // Pass on the piano key as a broadcast
  socket.on('note', function (data) {
    socket.broadcast.emit('note', data);
  });
});

// Start server and listen on port 8080 if not env defined.
server.listen(process.env.PORT || 8080);
```

Now we know we can emit a piano key to the other clients, and receive piano keys.

Lets start by creating the event stream:

```coffeescript
# Create event stream from target socket.
server = Bacon
  # Attach to WS event 'note'
  .fromEventTarget(socket, 'note')
  # Filter out non-keys
  .filter (note) ->
    $.inArray note, scale
```

We now have an additional event stream which can trigger a note to be played. Let's rewrite 
the ```notes``` event stream to merge with the ```server``` event stream.

```coffeescript
notes = clicks
  .merge(keypress)
  # Merge the new server event
  .merge(server)
  # play all notes from all events
  .onValue(player)
```

We can now listen to what other people are playing, but we can not yet broadcast what we 
are playing. We need to emit piano keys from clicks and key presses, but not the piano keys 
we received from the server. To achieve this we can tap into the composition and call 
```doAction``` before merging with the server event stream.

```coffeescript
notes = clicks
  # Merge keypress
  .merge(keypress)
  # Broadcast what key is playing
  .doAction (data) ->
    socket.emit "note", data
  # Merge server
  .merge(server)
  # play all notes from all events
  .onValue(player)
```

Now we have a fully functional collaborative piano. We can click on it,
use the keys ```1``` through ```8```, and we can play the tunes received from other players. 

One thing is missing, though. We cannot see which piano key a key press corresponds to,
or what piano keys other users are pressing. To achieve this we need to set a piano key as active.

### Setting Piano Keys As Active

One big advantage with FRP is immutability. This means that each map, filter, or 
other transformations always returns a new event stream or behaviour. This means that we can 
use ```keypress``` and ```server``` again, without causing side effects in other parts of the 
program. Lets add the active state:

```coffeescript
# Indicate tangent click on keypress/server
# reuse event stream
keypress 
  # merge server event
  .merge(server)
  # Convert keys to jQuery objects of piano key
  .map (key) ->
    $("[data-note='" + key + "']")
  .doAction (el) -> 
    el.addClass "active"
  # delay for 200 ms before continuing
  .delay(200)
  .onValue (el) -> 
    el.removeClass "active"
```

# Final Result

The final CoffeeScript source code can be viewed as a gist: https://gist.github.com/mikaelbr/6570293

A demo appliation is hosted on heroku http://frppiano.herokuapp.com/

The full source code is available as a Github repo: https://github.com/mikaelbr/frp-piano

---

## Further Reading

1. A tutorial in FRAN by Conel Elliot: http://conal.net/fran/tutorial.htm
2. Readme of Bacon.js: https://github.com/baconjs/bacon.js
3. FrTime: Funtional Reative Programming in PLT Sheme: [ftp://ftp.cs.brown.edu/pub/techreports/03/cs03-20.pdf](ftp://ftp.cs.brown.edu/pub/techreports/03/cs03-20.pdf)


[1]: http://conal.net/papers/icfp97/icfp97.pdf


## Thanks

Thanks to Stian Veum Møllersen and Øyvind Selmer for reviewing and giving invaluable tips.
