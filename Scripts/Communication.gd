extends Node



const Proto = preload("res://protobuf/proto.gd")
var tcp_server #TCP_Server
var client #StreamPeerTCP

var env_sent : bool
var command_applied : bool = false

func start_server(port : int):	
	#initialization
	
	#launch TCP Server
	tcp_server = TCP_Server.new();	
	var listen_error = tcp_server.listen(port)
	if listen_error:
		Logger.log_error("Error trying to listen at port %s (Error code %s)" % [port,listen_error])
		
	
	#for tests
	print( encode_environment_description())

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if client!=null and !client.is_connected_to_host():
		#if client was disconnected set variable to null again
		client=null
	
	if client==null and tcp_server.is_connection_available():
		env_sent = false #new connection so has not yet received information about environment
		client = tcp_server.take_connection() 
		
	
	if client != null and client.is_connected_to_host():

		if not(env_sent):
			#if info about the environment not yet sent to client first sent this before other transmissions
			#response with a message containing description of the enviroment for test
			var env_message = encode_environment_description()
			
			client.put_string(env_message)
			env_sent = true
		else:
			
			#then read if commands were received (read one at most)
			if client.get_available_bytes() > 0:
				var response= client.get_string(-1);
				var json = JSON.parse(response)
				var content = json.get_result()
				print( content)
				
				if content.has("robot_command"):
					var command_info = content["robot_command"]
					if command_info[0] == "pickup":
						if command_info.size() != 2:
							Logger.log_warning("Wrong number of arguments for pickup Command, expected 1 and got %s" % (command_info.size() -1))
						else:
							var robot_id = command_info[1]
							var robot = instance_from_id(robot_id)
							if not(robot.has_method("pickup")):#way to check if the instance is a Robot
								Logger.log_warning("Instance specified for pickup command is not a robot (instance id %s)" % (robot_id))
							else:
								Logger.log_info("%-12s %8s" % ["pickup", robot_id])
								robot.pickup()
					elif command_info[0] == "navigate_to":
						if command_info.size() != 4:
							Logger.log_warning("Wrong number of arguments for navigate_to Command, expected 3 and got %s" % (command_info.size() -1))
						else:
							var robot_id = command_info[1]
							var robot = instance_from_id(robot_id)
							var dest_x = command_info[2]
							var dest_y = command_info[3]
							
							if not(robot.has_method("pickup")):#way to check if the instance is a Robot
								Logger.log_warning("Instance specified for pickup command is not a robot (instance id %s)" % (robot_id))
							else:
								Logger.log_info("%-12s %8s;%8.3f;%8.3f" % ["navigate_to", robot_id, dest_x, dest_y])
								robot.navigate_to(Vector2(dest_x,dest_y))
					elif command_info[0] == "do_rotation":
						if command_info.size() != 4:
							Logger.log_warning("Wrong number of arguments for do_rotation Command, expected 3 and got %s" % (command_info.size() -1))
						else:
							var robot_id = command_info[1]
							var robot = instance_from_id(robot_id)
							var angle = command_info[2]
							var speed = command_info[3]
							
							if not(robot.has_method("pickup")):#way to check if the instance is a Robot
								Logger.log_warning("Instance specified for pickup command is not a robot (instance id %s)" % (robot_id))
							else:
								Logger.log_info("%-12s %8s;%8.3f;%8.3f" % ["do_rotation", robot_id, angle, speed])
								robot.do_rotation(angle, speed)
			
			#then send state
			var state_message = encode_current_state()
			
			client.put_string(state_message)

#						var command_type = Command.get_command()
#						if command_type == Proto.Command.Command_types.GOTO:
#							_Robot.goto(Command.get_dir(), Command.get_speed(), Command.get_time()) 
#						elif command_type == Proto.Command.Command_types.PICKUP :
#							_Robot.pickup()
#
#			#first send data about state of world
#			var bytes_to_send = encode_current_state()
#			var size_bytes = bytes_to_send.size()

#		#first send data about state of world
#		var bytes_to_send = encode_current_state()
#		var size_bytes = bytes_to_send.size()
#
#		client.put_32(size_bytes)
#		client.put_data(bytes_to_send)
		
	

			
func set_area_parameters(area, stand : Node):
	#used in the encode_environment_description  to set the area parameters to the area correspondign to the stand Node
	var rectangle = stand.get_area_rectangle()
	var position=rectangle[0]
	var size=rectangle[1]
	area.center = [position.x, position.y]
	area.size = [size.x, size.y]
	area.id = stand.get_instance_id()
			
func encode_environment_description() -> String:
	#creates and serializes a protocol buffer containing the description of the environment of the simulation
	
	var env = {}
	
	#info about arrival and delivery areas
	
	env.arrival_area = {}
	var arrival = get_tree().get_nodes_in_group("arrival")[0]
	env.arrival_area.id = arrival.get_instance_id()
	set_area_parameters(env.arrival_area, arrival.get_node("Output_Belt"))
	
	env.delivery_area = {}
	var delivery = get_tree().get_nodes_in_group("delivery")[0]
	env.delivery_area.id = delivery.get_instance_id()
	set_area_parameters(env.delivery_area, delivery.get_node("Input_Belt"))

	#info about machines
	env.machines = []
	var machines_list = get_tree().get_nodes_in_group("machines")
	for machine in machines_list:
		var new_machine = {}
		env.machines.append(new_machine)

		new_machine.id = machine.get_instance_id()

		new_machine.input_area = {}
		set_area_parameters(new_machine.input_area, machine.get_node("Input_Belt"))

		new_machine.output_area = {}
		set_area_parameters(new_machine.output_area, machine.get_node("Output_Belt"))

		var buffer_sizes = machine.get_buffer_sizes()
		new_machine.input_size = buffer_sizes[0]
		new_machine.output_size = buffer_sizes[1]

		new_machine.processes_list = machine.get_possible_processes()
		
	#info about charging area
	env.parking_areas = []
	var parking_area_zones = get_tree().get_nodes_in_group("parking_area_poly")
	for zone in parking_area_zones:
		var new_zone = {}
		env.parking_areas.append(new_zone)
		new_zone.id = zone.get_instance_id()
		
		var new_polygon = {}
		new_zone.polygon = new_polygon
		
		var polygon = zone.get_polygon()
		var center_vector = polygon_center(polygon)
		new_polygon.center = [center_vector.x,center_vector.y]
		new_polygon.points = polygon
	
	return JSON.print(env)

func encode_current_state() -> String:
	#creates and serializes a protocol buffer containing the data about the current state of the simulation
	
	var state = {}
	
	#data about robots 
	state.robots = []
	var robots_list = get_tree().get_nodes_in_group("robots")
	for robot in robots_list:
		var new_robot = {}
		state.robots.append(new_robot)
		
		new_robot.id = robot.get_instance_id()
		
		new_robot.position = [robot.position.x, robot.position.y]
		
		new_robot.rotation = robot.rotation
		
		new_robot.battery = robot.get_battery_proportion()
		new_robot.is_moving = robot.is_moving()
		new_robot.is_rotating = robot.is_rotating()
		new_robot.in_station = robot.get_in_station()
		
		#info about if the robot is carrying a package, -1 if not 
		new_robot.carried = -1
		for child in robot.get_children():
			if child.is_in_group("packages"):
				new_robot.carried = child.get_instance_id()
		

	#data about packages 
	state.packages = []
	var packages_list = get_tree().get_nodes_in_group("packages")
	for package in packages_list:

		var new_package = {}
		state.packages.append(new_package)

		new_package.id = package.get_instance_id()
	
		var package_parent = package.get_parent()
		if package_parent is KinematicBody2D:
			#case where this package is currently carried by a robot
			new_package.location_type = "robot"
		elif package_parent.has_node("Input_Belt"):
			#case where this package is currently in a machine
			new_package.location_type = package_parent.package_location(package)

		else: 
			#case where this package is currently in the arrival zone
			new_package.location_type = "arrival"
		new_package.location_id = package_parent.get_instance_id()

		new_package.processes = []

		var list = package.get_processes()
		for process in list:
			var id = process[0]
			var duration = process[1]

			new_package.processes.append({"id":id, "duration":duration})

		
	state.command_processed = command_applied
	command_applied = false
		
	return JSON.print(state)

	
func polygon_center(points_list : PoolVector2Array):
	var size = points_list.size()
	var points_sum = Vector2(0,0)
	if size>0:
		for point in points_list:
			points_sum += point
		return points_sum / size
