# An example of Functional Reactive Programming, by implementing a 
# simple collaborative piano.

# By Mikael Brevik <@mikaelbr>

socket = io.connect()
scale = [
    'A2', 'B2', 'C3', 'D3', 'E3', 'F3', 'G3',
    'A3', 'B3', 'C4', 'D4', 'E4', 'F4', 'G4',
    'A4', 'B4', 'C5'
  ]

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
  .filter (code) ->  # Remove all signals that's not the keys 1 thorugh 8
    code >= 49 && code <= 56
  .map (code) -> # translate to piano keys
    scale[code - 47]

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