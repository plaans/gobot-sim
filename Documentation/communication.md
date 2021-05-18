# Communication interface

The messages sent between the server (run by the simulation) and the client which connects use JSON format.

From the client to the server, the command to send are formatted as a list which first element contains the name of the command and the elements coming afterwards are the arguments. This is encapsulated to contain information about the type of data sent. For example if sending a command to navigate 'robot1' to position (50,100), the message format would be :

	{'type':'robot_command',
	'data':['navigate_to','robot1',50,100]}

From the server to the client, the data about the state of the simulation is sent as a concatenation of facts with a format such as `['coordinates','robot1',[300,350]]` for example in the case of the coordinates. The message format is the same as presented before, with 'type' = 'static' or 'dynamic' and 'data' containing the concatenation of all data to sent.

Below are listed the attributes and commands that can be sent.

# List of attributes 

## Robot 

Field | Exemple of format | Description
--- | --- | --- 
***Static*** |  |
Declaration of instance | `['Robot.instance', robot_name]`
***Dynamic*** |  |
Coordinates | `['Robot.coordinates', robot_name, [x,y]]` | The coordinates (floats) are given in meters, with a conversion automatically done in the simulator so that one tile of the tilemap is always 1m x 1m in size.
Tiles Coordinates | `['Robot.coordinates_tile', robot_name, [x,y]]` | Coordinates in tiles (indexes of tile the robot is currently in)
Battery  | `['Robot.battery', robot_name, battery_proportion]` |  The value is a float between 0 and 1.
Movement speed  | `['Robot.velocity', robot_name, [velocity_x, velocity_y]]` |  floats in meters/s
Rotation speed  | `['Robot.rotation_speed', robot_name, rotation_speed]` |  float in rads/s
In station  | `['Robot.in_station', robot_name, in_station]` |  Bool indicating if the robot is currently in a charging station
In interact areas  | `['Robot.in_interact_areas', robot_name, [interact_area0, interact_area1, ...]]` | Liste of names of interact areas the robot is currently in
 
## Machine 


Field | Exemple of format | Description
--- | --- | --- 
***Static*** |  |
Declaration of instance | `['Machine.instance', machine_name]`
Coordinates | `['Machine.coordinates', machine_name, [x,y]]` | Coordinates in meters (floats)
Tiles Coordinates | `['Machine.coordinates_tile', machine_name, [x,y]]` | Coordinates in tiles (indexes of tile the machine is located at)
Input belt | `['Machine.input_belt', machine_name, input_belt_name]` | Name of the input belt connected to this machine (string)
Output belt | `['Machine.output_belt', machine_name, output_belt_name]` | Name of the output belt connected to this machine (string)
Processes | `['Machine.processes_list', machine_name, [id0, id1, ...]]` | List of the ids (ints) of each process the machine can do
***Dynamic*** |  |
Progress rate  | `['Machine.progress_rate', machine_name, progress_rate]` | Progress of current task between 0 and 1 


## Package

Field | Exemple of format | Description
--- | --- | --- 
***Static*** |  |
Declaration of instance | `['Package.instance', package_name]`
***Dynamic*** |  |
Location | `['Package.location', package_name, location_name]` | String corresponding to the name of the location (robot, belt, ...)
Processes  | `['Package.processes_list', package_name, [[id0, duration0], [id1, duration1], ...]]` |  List of `[process_id, process_duration]` (int and float) for each process remaining to be done


## Belt


Field | Exemple of format | Description
--- | --- | --- 
***Static*** |  |
Declaration of instance | `['Belt.instance', belt_name]`
Belt type | `['Belt.belt_type', belt_name, 'input' / 'output']` | Value is either 'input' or 'output'
Polygons | `['Belt.polygons', belt_name, [polygon0, polygon1, ...]]` | List of the polygons that compose the belt (each polygon is itself a list a points, which coordinates are given in meters)
Cells  | `['Belt.cells', belt_name, [[x0, y0], [x1, y1], ...]]` | List of indexes of cells that compose this Belt
Interact areas  | `['Belt.interact_areas', belt_name, [interact_area0, interact_area1, ...]]` | List of names of interact areas associated with this Belt

***Dynamic*** |  |
List of packages  | `['Belt.packages_list', belt_name, [package0, package1, ...]]` | List of the names of the packages currently on the belt
 
## Parking area : 
Field | Exemple of format | Description
--- | --- | --- 
***Static*** |  |
Declaration of instance | `['Parking_area.instance', parking_area_name]`
Polygon | `['Parking_area.polygons', parking_area_name, [[x0, y0], [x1, y1], ...]` | List of the polygons that compose the belt (each polygon is itself a list a points, which coordinates are given in meters)
Cells  | `['Parking_area.cells', parking_area_name, [[x0, y0], [x1, y1], ...]]` | List of indexes of cells that compose this Parking area
	 
## Interact area : 
Field | Exemple of format | Description
--- | --- | --- 
***Static*** |  |
Declaration of instance | `['Interact_area.instance', robot_name]`
Polygon | `['Interact_area.polygons', interact_area_name, [[x0, y0], [x1, y1], ...]]` | List of the polygons that compose the belt (each polygon is itself a list a points, which coordinates are given in meters)
Cells  | `['Interact_area.cells', interact_area_name, [[x0, y0], [x1, y1], ...]]` | List of indexes of cells that compose this Interact area
Belt  | `['Interact_area.Belt', interact_area_name, belt_name]` | Name of Belt this Interact area is associated with
	 
# List of commands

Command name | Exemple of format | Description
--- | --- | --- 
Navigate to | `['navigate_to', robot_name, destination_x, destination_y] ` | Moves the robot to the destination (with coordinates given in meters), automatically finding a path that avoids obstacles
Pick  | `['pick', robot_name] ` |  Picks the next package from an output belt if the robot is facing the belt and is in the associated interact area
Place  | `['place', robot_name]` |  Place the carried package in an input belt if the robot is carrying a package, is facing the belt and is in the associated interact area
Rotation  | `['do_rotation', robot_name, angle, speed]` |  Rotates the robot of the given angle (in rads) at the given speed (in rads/s)