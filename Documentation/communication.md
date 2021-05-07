# Communication interface

The messages sent between the server (run by the simulation) and the client which connects use JSON format.

From the client to the server, the command to send are formatted as a list which first element contains the name of the command and the elements coming afterwards are the arguments. This is encapsulated to contain information about the type of data sent. For example if sending a command to navigate 'robot1' to position (50,100), the message format would be :

{'type':'robot\_command',
'data':['navigate_to','robot1',50,100]}

From the server to the client, the data about the state of the simulation is sent as a concatenation of facts with a format such as ['coordinates','robot1',[300,350]] for example in the case of the coordinates.

Below are listed the attributes and commands that can be sent.

## List of attributes 

### Robot 

 - Coordinates (floats) : ['coordinates', robot\_name, [x,y]]
 - Battery (float) : ['battery', robot\_name, battery_proportion]
 - Rotation (float) : ['rotation', robot\_name, rotation\_value]
 - Is\_moving (bool) : ['is\_moving', robot\_name, is\_moving]
 - Is\_rotating (bool) : ['is\_rotating', robot\_name, is\_rotating]
 - In\_station (bool) : ['in\_station', robot\_name, in\_station]
 
### Machine 

 - Coordinates (floats) : ['coordinates', machine\_name, [x,y]]
 - Input area (floats) : ['input\_area', machine\_name, [x,y]]
 - Output area (floats) : ['Output\_area', machine\_name, [x,y]]
 - Buffers sizes (ints) ['buffers\_sizes', machine\_name, [input\_size,output\_size]]
 - Processes (list of ints) : ['processes\_list', machine\_name, processes_list]

### Package

 - Location (string) : ['location', package\_name, parent\_name]
 - Processes (list of ints) : ['processes\_list', package\_name, processes_list]
 
## List of commands

- Navigate to : ['navigate\_to', robot\_name, destination\_x, destination\_y] 
- Pickup : ['pickup', robot\_name, destination\_x, destination\_y] 
- Rotation : ['do\_rotation', robot\_name, angle, speed] 