var express = require('express')
  , app = express()
  , server = require('http').createServer(app)
// Serve static files
app.use(express.static(__dirname + '/public'));

// Create WS server
var io = require('socket.io').listen(server);

// Adding support for Socket.IO on Heroku
io.configure(function () { 
  io.set("transports", ["xhr-polling"]); 
  io.set("polling duration", 10); 
});

// When a new client connects
io.sockets.on('connection', function (socket) {
  // Pass on the piano key as a broadcast
  socket.on('note', function (data) {
    socket.broadcast.emit('note', data);
  });
});

// Start server and listen on port 8080 if not env defined.
server.listen(process.env.PORT || 8080);