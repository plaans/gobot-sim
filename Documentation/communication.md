# Communication interface

The messages sent between the server (run by the simulation) and the client which connects use JSON format.

From the client to the server, the command to send are formatted as a list which first element contains the name of the command and the elements coming afterwards are the arguments. This is encapsulated to contain information about the type of data sent. For example if sending a command to navigate 'robot1' to position (50,100), the message format would be :

	{'type':'robot_command',
	'data':['navigate_to','robot1',50,100]}

From the server to the client, the data about the state of the simulation is sent as a concatenation of facts with a format such as ['coordinates','robot1',[300,350]] for example in the case of the coordinates. The message format is the same as presented before, with 'type' = 'static' or 'dynamic' and 'data' containing the concatenation of all data to sent.

Below are listed the attributes and commands that can be sent.

## List of attributes 

### Robot 

*Static*

	 - Declaration of element : ['robot', robot_name]

*Dynamic*

	 - Coordinates (floats) : ['coordinates', robot_name, [x,y]]
	 - Battery (float) : ['battery', robot_name, battery_proportion]
	 - Rotation (float) : ['rotation', robot_name, rotation_value]
	 - Movement speed (2 floats) : ['velocity', robot_name, [velocity_x,velocity_y]]
	 - Rotation speed (float) : ['rotation_speed', robot_name, rotation_speed_]
	 - In_station (bool) : ['in_station', robot_name, in_station]
	 - In_interact (bool) : ['in_interact', robot_name, in_interact]
 
### Machine 
*Static*

	 - Declaration of element : ['machine', machine_name]
	 - Coordinates (floats) : ['coordinates', machine_name, [x,y]]
	 - Input belt (string) : ['input_belt', machine_name, input_belt_name]
	 - Output belt (string) : ['output_belt', machine_name, output_belt_name]
	 - Processes (list of ids for each process) : ['processes_list', machine_name, [id0, id1, ...]]

*Dynamic*

	 - Progress of current task between 0 and 1 (0 if no task in progress) :['progress_rate', machine_name, progress_rate]


### Package
*Static*

	 - Declaration of element : ['package', package_name]

*Dynamic*

	 - Location (string) : ['location', package_name, parent_name]
	 - Processes (list of [process_id, process_duration] for each process) : ['processes_list', package_name, [[id0, duration0], [id1, duration1], ...]]
	 
### Belt

*Static*

	 - Declaration of element : ['belt', belt_name]
	 - Coordinates (floats) : ['coordinates', belt_name, [x,y]]
	 - Belt type ('input' or 'output') : ['belt_type', belt_name, 'input' / 'output']
	 - Polygons (list of polygons) : ['polygon', belt_name, [polygon0, polygon1, ...]]


*Dynamic*

	 - List of names of packages on belt: ['packages_list', belt_name, [package0, package1, ...]]
 
### Parking area : 

*Static*

	 - Declaration of element : ['parking_area', parking_area_name]
	 - Polygon (floats) : ['polygon', parking_area_name, [[x0, y0], [x1, y1], ...]]
	 
### Interact area : 

*Static*

	 - Declaration of element : ['interact_area', interact_area_name]
	 - Polygon (floats) : ['polygon', interact_area_name, [[x0, y0], [x1, y1], ...]]
	 
## List of commands
	
*Static*

	 - Declaration of element : ['robot', robot_name]

*Dynamic*

	- Navigate to : ['navigate_to', robot_name, destination_x, destination_y] 
	- Pickup : ['pickup', robot_name] 
	- Rotation : ['do_rotation', robot_name, angle, speed] 