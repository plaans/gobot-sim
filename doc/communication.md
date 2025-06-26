# Communication interface

This file describes how the communication is done between the server inside the simulation and the clients which connect to this server. Messages are encoded using JSON format and sent through TCP protocol. Below is a more detailed description of the messages sent for both aspects of the communication (sending the state of the simulation and sending commands).

# State of the simulation


From the server to the client, the data about the state of the simulation is sent as a concatenation of facts with a format such as `['coordinates','robot1',[300,350]]` for example in the case of the coordinates. The message format is the same as presented before, with 'type' = 'static' or 'dynamic' and 'data' containing the concatenation of all data to sent.

Below are listed the attributes and commands that can be sent.

## List of attributes

### Globals

Field | Exemple of format | Description
--- | --- | --- 
***Static*** |  |
Robot default battery capacity | `['Globals.robot_default_battery_capacity', float]`
Robot battery charge rate | `['Globals.robot_battery_charge_rate', float]`
Robot battery drain rate | `['Globals.robot_battery_drain_rate', float]`
Robot battery idle drain rate | `['Globals.robot_battery_drain_rate_idle', float]`
Robot battery standard speed (in m/s) | `['Globals.robot_standard_speed', float]`


### Robot 

Field | Exemple of format | Description
--- | --- | --- 
***Static*** |  |
Declaration of instance | `['Robot.instance', robot_name, 'robot]`
Recharge rate | `['Robot.recharge_rate', robot_name, float]` | Rate of recharge of the robot's battery 
Drain rate | `['Robot.drain_rate', robot_name, float]` | Rate of discharge of the robot's battery 
Default speed | `['Robot.standard_speed', robot_name, float]` | Default speed normalized in m/s.
***Dynamic*** |  |
Coordinates | `['Robot.coordinates', robot_name, [x,y]]` | The coordinates (floats) are given in meters, with a conversion automatically done in the simulator so that one tile of the tilemap is always 1m x 1m in size.
Tiles Coordinates | `['Robot.coordinates_tile', robot_name, [x,y]]` | Coordinates in tiles (indexes of tile the robot is currently in)
Battery  | `['Robot.battery', robot_name, battery_proportion]` |  The value is a float between 0 and 1.
Movement speed  | `['Robot.velocity', robot_name, [velocity_x, velocity_y]]` |  floats in meters/s
Rotation speed  | `['Robot.rotation_speed', robot_name, rotation_speed]` |  float in rads/s
In station  | `['Robot.in_station', robot_name, in_station]` |  Boolean indicating if the robot is currently in a charging station
In interact areas  | `['Robot.in_interact_areas', robot_name, [interact_area0, interact_area1, ...]]` | List of names of interact areas the robot is currently in
Closest Area to a robot | `['Robot.closest_area', robot_name, closest_area_name]` | Name of the closest are to the robot, either parking area or interact area
Location of the robot | `['Robot.location', robot_name, location]` | High level view of the position of the robot: parking area or interact area.
 
### Machine 


Field | Exemple of format | Description
--- | --- | --- 
***Static*** |  |
Declaration of instance | `['Machine.instance', machine_name, 'machine']`
Coordinates | `['Machine.coordinates', machine_name, [x,y]]` | Coordinates in meters (floats)
Tiles Coordinates | `['Machine.coordinates_tile', machine_name, [x,y]]` | Coordinates in tiles (indexes of tile the machine is located at)
Input belt | `['Machine.input_belt', machine_name, input_belt_name]` | Name of the input belt connected to this machine (string)
Output belt | `['Machine.output_belt', machine_name, output_belt_name]` | Name of the output belt connected to this machine (string)
Processes | `['Machine.processes_list', machine_name, [id0, id1, ...]]` | List of the ids (ints) of each process the machine can do
Machine type | `['Machine.type', machine_name, type]` | Can be either 'input_machine', 'output_machine' or 'standard_machine'
***Dynamic*** |  |
Progress rate  | `['Machine.progress_rate', machine_name, progress_rate]` | Progress of current task between 0 and 1 


### Package

Field | Exemple of format | Description
--- | --- | --- 
***Static*** |  |
Declaration of instance | `['Package.instance', package_name, 'package']`
Ordered list of all processes | `[Package.all_processes, package_name, [[id0, duration0]], [id1, duration1], ...]]`
***Dynamic*** |  |
Location | `['Package.location', package_name, location_name]` | String corresponding to the name of the location (robot, belt, ...)
Processes  | `['Package.processes_list', package_name, [[id0, duration0], [id1, duration1], ...]]` |  List of `[process_id, process_duration]` (int and float) for each process remaining to be done



### Belt


Field | Exemple of format | Description
--- | --- | --- 
***Static*** |  |
Declaration of instance | `['Belt.instance', belt_name, 'belt']`
Belt type | `['Belt.belt_type', belt_name, 'input' / 'output']` | Value is either 'input' or 'output'
Polygons | `['Belt.polygons', belt_name, [polygon0, polygon1, ...]]` | List of the polygons that compose the belt (each polygon is itself a list a points, which coordinates are given in meters)
Cells  | `['Belt.cells', belt_name, [[x0, y0], [x1, y1], ...]]` | List of indexes of cells that compose this Belt
Interact areas  | `['Belt.interact_areas', belt_name, [interact_area0, interact_area1, ...]]` | List of names of interact areas associated with this Belt
***Dynamic*** |  |
List of packages  | `['Belt.packages_list', belt_name, [package0, package1, ...]]` | List of the names of the packages currently on the belt
 
### Parking area : 
Field | Exemple of format | Description
--- | --- | --- 
***Static*** |  |
Declaration of instance | `['Parking_area.instance', parking_area_name, 'parking_area']`
Polygon | `['Parking_area.polygons', parking_area_name, [[x0, y0], [x1, y1], ...]` | List of the polygons that compose the belt (each polygon is itself a list a points, which coordinates are given in meters)
Cells  | `['Parking_area.cells', parking_area_name, [[x0, y0], [x1, y1], ...]]` | List of indexes of cells that compose this Parking area
	 
### Interact area : 
Field | Exemple of format | Description
--- | --- | --- 
***Static*** |  |
Declaration of instance | `['Interact_area.instance', interact_area_name, 'interact_area]`
Polygon | `['Interact_area.polygons', interact_area_name, [[x0, y0], [x1, y1], ...]]` | List of the polygons that compose the belt (each polygon is itself a list a points, which coordinates are given in meters)
Cells  | `['Interact_area.cells', interact_area_name, [[x0, y0], [x1, y1], ...]]` | List of indexes of cells that compose this Interact area
Belt  | `['Interact_area.belt', interact_area_name, belt_name]` | Name of Belt this Interact area is associated with


# Commands of the platform
## Commands to control the robots 

For commands to apply to the robot, the command to send are formatted as a list which first element contains the name of the command and the elements coming afterwards are the arguments. The JSON message must also specify that the type is 'robot_command' and have a field 'temp_id'. This field contains the ID attributed to the action temporarily by the client, and the first response from the server will contain the permanent ID attributed to the action. After that, other types of message are exchanged, from the server to give information about the state of the action and from the client to cancel an action. Here is a list of the messages types concerning actions :


### Examples of possible message types 

- Sending a new command to the server

		{'type':'robot_command', 
		 'data': 
		 	{'command_info : ['navigate_to','robot1',50,100], 
			 'temp_id':0
			}
		}

	'temp_id' corresponds to the temporary id attributed by the client until the first response from the server which attributes an id to the action
- Response from the server when a new command is received

		{'type':'action_response',
		 'data': 
		 	{'temp_id':0, 
			 'action_id':10
			}
		}

	If the command was not accepted (wrong syntax, wrong number of arguments, ...), the 'command_id' will be -1
	
- Server sending feedback about the action progress 

		{'type':'action_feedback',
		 'data': 
		 	{'action_id':10,
			 'feedback':0.5
			}
		}

- Server sending result of an action (completed or failed)

		{'type':'action_result',
		 'data': 
		 	{'action_id':10,
			 'result': True
			}
		}

- Server sending information that an action was preempted

		{'type':'action_preempt',
		 'data': 
		 	{'action_id':10
			}
		}

- Client sending request to cancel an action

		{'type':'cancel_request',
		 'data': 
		 	{'action_id':10
			}
		}

- Server sending confirmation that an action was cancelled (or not)

		{'type':'action_cancel',
		'action_id':10],
		'cancelled': True}



## List of commands

Command name | Exemple of format | Description
--- | --- | --- 
**Manipulation commands** |  |
Pick  | `['pick', robot_name] ` |  Picks the next package from an output belt if the robot is facing the belt and is in the associated interact area
pick_package  | `['pick_package', robot_name, package_name] ` |  Picks the package specified from an output belt if the robot is facing the belt and is in the associated interact area (same as 'pick' with the possibility to chose which package to pick)
Place  | `['place', robot_name]` |  Place the carried package in an input belt if the robot is carrying a package, is facing the belt and is in the associated interact area
**Navigation commands** |  |
Move the robot| `['do_move', robot_name, angle, speed, duration] ` | Moves the robot for the given duration and speed, in the direction determined by the angle (indendepent of the rotation of the robot itself)
Navigate to | `['navigate_to', robot_name, destination_x, destination_y] ` | Moves the robot to the destination (with coordinates given in meters), automatically finding a path that avoids obstacles
Navigate to a cell | `['navigate_to_cell', robot_name, cell_x_index, cell_y_index] ` | Same behavior as navigate_to with the destination being a cell
Navigate to an area | `['navigate_to_area', robot_name, area_name] ` | Navigate the robot to the closest cell in the given area (area_name must be the name of a parking_area or a interact_area)
Go to closest charging area | `['go_charge', robot_name] ` | Navigate the robot to the closest cell in the closest parking_area
**Rotation commands** |  |
Do a rotation (of the given angle)  | `['do_rotation', robot_name, angle, speed]` |  Rotates the robot of the given angle (in rads) from the current rotation, at the given speed (in rads/s)
Rotate to an angle  | `['rotate_to', robot_name, angle, speed]` |  Rotates the robot to the given angle (in rads) at the given speed (in rads/s)
Rotate to face a belt  | `['face_belt', belt_name, speed]` |  Rotates the robot to face a given belt

## Command to process a package on a machine
To process a package on a machine, a command request must be sent to the platform. The success of the command requires that the package is on the input belt of the machine, and the machine is not processing another package.
Here is the format of the JSON message that should be sent to process a package `package_name` on the machine `machine_name`:

	{'type':'machine_command', 
		 'data': 
		 	{'command_info : ['process','machine_name','package_name'], 
			 'temp_id':0
			}
	}

