# Simple collaborative piano made using Functional Reactive Programming

To learn more about functional reactive programming, I started
making a simple collaborative piano using JavaScript/CoffeeScript. 
I wrote a blog post to show how Functional Reactive Programming can make the 
task of taking multiple event inputs and merging them into one discrete 
sequence of interactions really easy – a task that could otherwise be 
potentially complex and very unstructured/hard to read.

[See full blog post](blogpost.md) 

## Installation and startup

### Clone repo and change directory
```
git clone https://github.com/mikaelbr/frp-piano
cd frp-piano
```

### Install dependencies
```
npm install
```

### Install coffee-script if you don't have it
```
sudo npm install -g coffee-script
```

### Compile the client side script
```
coffee -c public/*.coffee
```

### Run the project by doing
```
npm start
```