class Message {
  int hopCount = 0;
  int group = 0;
  int hopLimit = 0;

  Message(int hopLimit){
    this.hopLimit = hopLimit;
  }

  Message(int hopLimit, int group){
    this.hopLimit = hopLimit;
    this.group = group;
  }

  Message(Message message){
    this.hopCount = message.hopCount;
  }

  Message relay(){  
   Message newMessage = new Message(this.hopLimit, this.group);
   newMessage.hopCount = this.hopCount+1;
   return newMessage;
  }

  boolean hopsLeft(){
    return this.hopCount<this.hopLimit;
  }
}

// Node is the basic communication unit of mesh
// No performs the routing alogrithm
class Node {
  float x, y;
  int r = 18;
  float proximityDistance = 80;
  int group=0; // default group
  ArrayList<Node> neighbours = new ArrayList<Node>();
  
  Message message = null;
  
  Node(float x, float y) {
    this.x = x;
    this.y = y;
  }
  void draw() {
    strokeWeight(2);
    stroke(0xee);
    fill(0xee);
    
    // blak if has message, grey if does not
    if(this.message!=null) {
      fill(0);
      stroke(0);
    } else {
      stroke(0xdd);
      fill(0xdd);
    }
    if(this==source) fill(0xff);
    
    // red if group is 1
    if (this.group>0) stroke(0xffff0000);
    
    ellipse(x,y,r,r);
  }
  
  // Call this function to send a message to this node
  void receive(Message message) {
    if(this.message==null) this.message = message;
  }

  void broadcast(Message message) {
    this.message = message;
    if(message.hopsLeft()){
      for(int i = 0; i<this.neighbours.size(); i++){
        this.neighbours.get(i).receive(message.relay());
      }
    }
  }
  void broadcastGroup(int hopLimit) {
    this.message = new Message(hopLimit, this.group);
    for(int i = 0; i<this.neighbours.size(); i++){
      this.neighbours.get(i).receive(message.relay());
    }
  }
  void clearMessages() {
    this.message=null;
  }
  // Will return true if message was relayed
  // This function will relay the message based on the group of the node:
  // If group 0, the message will relay based on basic hop count limit
  // If group 1, the message will be relayed based on group propagation algorithm 
  boolean relay() {
    if(this.message != null) { // check if there is a message to be relayed
      if ( this.message.group!=0 && this.message.group == this.group) { //only relay if in the same group
        for(int i = 0; i<this.neighbours.size(); i++){
            this.neighbours.get(i).receive(message.relay());
          }
          return true;
      } else if(this.message.group==0 && this.message.hopsLeft()){ // group 0, do only ho count limit
        for(int i = 0; i<this.neighbours.size(); i++){
          this.neighbours.get(i).receive(message.relay());
        }
        return true;
      }
    }
    return false;
  }
  
  int lineColor(){
    if (this.message==null) return 0xee;
    else return 0x00;
  }
  
  void addNeighbour(Node node) {
    if(!neighbours.contains(node)) neighbours.add(node);
  }
  void removeNeighbour(Node node) {
    neighbours.remove(node);
  }
  void clearNeighbours() {
    for(int i = 0; i<this.neighbours.size(); i++){
       this.neighbours.get(i).removeNeighbour(this);
     }
    neighbours.clear();
  }

  boolean isProximity(Node node) {
    if(node == this) return false; // not a neighbour of self
    return dist(this.x, this.y, node.x, node.y) < this.proximityDistance;
  }
  boolean isInside(float x, float y){
  return dist(this.x, this.y, x, y) < r;
  }
}


ArrayList<Node> nodes = new ArrayList<Node>();

Node source = null;
int groupHop = 0;

void drawConnections() {
  stroke(0x22);
  strokeWeight(1);
  for (int i = 0; i<nodes.size(); i++) {
    for (int j = i; j<nodes.size(); j++) {
      if (nodes.get(i).isProximity(nodes.get(j))) {
        stroke(max(nodes.get(i).lineColor(), nodes.get(j).lineColor()));
        line(nodes.get(i).x, nodes.get(i).y, nodes.get(j).x, nodes.get(j).y);
      }
    }
  }
}

// Perform message routing
void runMesh() {
  for(int i = 0; i<nodes.size(); i++) {
    nodes.get(i).clearMessages();
  }

  if(source == null) return;

  if(source.group==0) source.broadcast(new Message(3)); // group 0 broadcast with hop limit
  else source.broadcastGroup(groupHop); // group 1 broadcast with group limit

  for(int k = 0; k<=20; k++) { // Simulate relaying a bunch of times
    for(int i = 0; i<nodes.size(); i++) {
      nodes.get(i).relay();
    }
  }

}

// Create window
void setup() {
  size(1200, 800);
}

void draw(){
  background(255); // clear
  
  drawConnections();
  runMesh();
  
  // draw each node
  for(int i = 0; i<nodes.size(); i++) {
    nodes.get(i).draw();
  }
}



// Adds tye nodes within the distance to the neighbours of the node 
void addProximityNeighbours(Node node) {
  node.clearNeighbours();
  for(int i = 0; i<nodes.size(); i++) {
    if(node.isProximity(nodes.get(i))){
      node.addNeighbour(nodes.get(i));
      nodes.get(i).addNeighbour(node);
    }
  }
}


// User interface related commands

// User interfcace works as follows:
// the command mode is selected by pressing the key on the keyboard
// following mouse opeartion is determined by the mode selected

/* 
 * CONTROL MODES:
 * a: Add new node
 * s: Set the source of the broadcast, remove source by clicking outside of nodes
 * d: delete node when clicking
 * 0: set the clicked node to group 0 (no group) or add new node to group 0
 * 1: set the clicked node to group 1 or add new node to group 1
 * r: generate random nodes
 * c: clear all the nodes
 * m: move the node by dragging
*/

// Find if there is a node in given location
Node clickedNode(float x, float y){
  for(int i = 0; i<nodes.size(); i++) {
    if(nodes.get(i).isInside(x, y)){
      return nodes.get(i);
    }
  }
  return null;
}

Node movingNode = null; // node being dragged

// Generate number of random nodes
void createRandomNodes(int count) {
  nodes.clear();
  source = null;
  for(int i = 0; i<count; i++) {
    boolean ready = false;
    while(!ready) {
      float x = random(30, 1170);
      float y = random(30, 770);
      if(clickedNode(x, y) == null) { // do not generate nodes on top of eachoter
        nodes.add(new Node(x, y));
        ready=true;
      }
    }
  }
}

void mousePressed() {
  if(key == 'a') { //add node to mouse location
    Node clicked = clickedNode(mouseX, mouseY);
    if(clicked == null){
      Node addedNode = new Node(mouseX, mouseY);
      addProximityNeighbours(addedNode);
      nodes.add(addedNode); // do not allow for nodes on top of each other
    }
  } else if(key == 's'){ // set source for message propagation
    Node clicked = clickedNode(mouseX, mouseY);
    if(clicked != null){
      if(clicked == source) source = null;
      else source = clicked;
    }else source = null;
  } else if(key == 'd'){ // delete node
    Node clicked = clickedNode(mouseX, mouseY);
    if(clicked != null) nodes.remove(clicked);
  }else if(key == '0'){ // set or add group 0 node
    Node clicked = clickedNode(mouseX, mouseY);
    if(clicked != null) clicked.group=0;
  }else if(key == '1'){ // set or add group 1 node
    Node clicked = clickedNode(mouseX, mouseY);
    if(clicked != null) clicked.group=1;
    else{
      Node addedNode = new Node(mouseX, mouseY);
      addProximityNeighbours(addedNode);
      addedNode.group=1;
      nodes.add(addedNode); // do not allow for nodes on top of each other
    }
  } else if(key == 'r'){ // generate random nodes
    createRandomNodes(150);
    for(int i = 0; i<nodes.size(); i++) {
      addProximityNeighbours(nodes.get(i));
    }
  }else if(key == 'c'){ // clear all nodes
    nodes.clear();
  }else if(key == 'm'){ // move node
     Node clicked = clickedNode(mouseX, mouseY);
    if(clicked != null) {
      movingNode=clicked;
    }
  }
}


void mouseDragged() 
{
  if(key == 'm'){ // move node
    if(movingNode != null) {
      movingNode.x = mouseX;
      movingNode.y = mouseY;
      // recalculate neighbours
      addProximityNeighbours(movingNode);
    }
  }
}

// set cursor images
void keyPressed() {
  if(key == 'm') {
    cursor(MOVE);
  } else {
    cursor(ARROW);
  }
}
