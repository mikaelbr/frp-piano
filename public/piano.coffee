# An example of Functional Reactive Programming, by implementing a 
# simple collaborative piano.

# By Mikael Brevik <@mikaelbr>

socket = io.connect()
scale = [
    'A2', 'Bb2', 'B2', 'C3', 'Db3', 'D3', 'Eb3', 'E3', 'F3', 'Gb3', 'G3', 'Ab3',
    'A3', 'Bb3', 'B3', 'C4', 'Db4', 'D4', 'Eb4', 'E4', 'F4', 'Gb4', 'G4', 'Ab4',
    'A4', 'Bb4', 'B4', 'C5'
  ]

mapping =
  113: 'A2'
  49: 'Bb2'
  119: 'B2'
  101: 'C3'
  52: 'Db3'
  53: 'Eb3'
  114: 'D3'
  116: 'E3'
  55: 'Gb3'
  56: 'Ab3'
  57: 'Bb3'
  121: 'F3'
  117: 'G3'
  105: 'A3'
  111: 'B3'
  112: 'C4'
  
# Create event streams for clicks on the piano tuts.
clicks = $("#piano")
  .asEventStream("click", ".clickable") # Attach to click event as stream
  .doAction(".preventDefault") # Prevent default on click
  .map (e) -> # Map events and retrieve the data-note
    $(e.currentTarget).attr "data-note"

# Add support for using the keyboard (one scale)
keypress = $(document)
  .asEventStream("keypress") # Attach to keypress event as stream
  .map(".keyCode") # Extract keyCode
  .map (code) -> # translate to piano keys
    mapping[code]
  .filter (key) ->  # Remove all signals that's not mapped to keys
    key isnt undefined
  

# Add collaborative support
server = Bacon
  .fromEventTarget(socket, 'note') # Attach to WS event 'note'
  .filter (note) -> # Filter out non-keys
    $.inArray note, scale

# Merge and play sound
notes = clicks
  .merge(keypress) # Merge clicks and key presses
  .doAction (data) -> # Broadcast what key is playing
    socket.emit "note", data 
  .merge(server) # Concat notes from other clients
  .doAction(player) # play all notes from all events
  .onValue (data) -> 
    console.log "Playing:", data

# Indicate tangent click on keypress/server
keypress # Use old event
  .merge(server) # merge server event
  .map (key) -> # Convert keys to jQuery objects of tangent
    $("[data-note='" + key + "']")
  .doAction (el) -> 
    el.addClass "active"
  .delay(200)  # wait for 200 ms before moving on
  .onValue (el) -> 
    el.removeClass "active"