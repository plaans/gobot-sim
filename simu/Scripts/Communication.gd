extends Node



var tcp_server #TCP_Server
var client #StreamPeerTCP

var client_counter = 0

var env_sent : bool
var command_applied : bool = false

var registered_commands = {}

var counter =0

func start_server(port : int):	
	#initialization
	
	#launch TCP Server
	tcp_server = TCP_Server.new();	
	var listen_error = tcp_server.listen(port)
	if listen_error:
		Logger.log_error("Error trying to listen at port %s (Error code %s)" % [port,listen_error])
	else:
		print( "Server started")
		
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if tcp_server!=null:
			
		if client!=null and !client.is_connected_to_host():
			#if client was disconnected set variable to null again
			client=null
		
		if client==null and tcp_server.is_connection_available():
			env_sent = false #new connection so has not yet received information about environment
			client = tcp_server.take_connection() 
			client_counter +=1
		
		if client != null and client.is_connected_to_host():

			if not(env_sent):
				#if info about the environment not yet sent to client first sent this before other transmissions
				#response with a message containing description of the enviroment for test
				var env_message = encode_static()
				
				client.put_string(env_message)
				env_sent = true
			else:
				
				#then read if commands were received (read one at most)
				if client.get_available_bytes() > 0:
						
					var response= client.get_string(-1);
					var json = JSON.parse(response)
					var content = json.get_result()
					
					#apply_command(content['data'],content['id'])
					
					var error_message = ""
					
					if content["type"] == "robot_command":
						var command_info = content["data"]
						if command_info[0] == "pick":
							if command_info.size() != 2:
								error_message = "Wrong number of arguments for pick Command, expected 1 and got %s" % (command_info.size() -1)
							else:
								var robot_name = command_info[1]
								var robot = ExportManager.get_node_from_name(robot_name)
								if robot==null or not(robot.has_method("place")):#way to check if the instance is a Robot
									error_message = "Instance specified for pick command is not a robot (name : %s)" % (robot_name)
								else:
									Logger.log_info("%-12s %8s" % ["pick", robot_name])
									robot.pick()
									if not registered_commands.has(robot_name):
										registered_commands[robot_name]={}
									registered_commands[robot_name]["pick"] = content["id"]
						
						elif command_info[0] == "place":
							if command_info.size() != 2:
								error_message = "Wrong number of arguments for place Command, expected 1 and got %s" % (command_info.size() -1)
							else:
								var robot_name = command_info[1]
								var robot = ExportManager.get_node_from_name(robot_name)
								if robot==null or not(robot.has_method("place")):#way to check if the instance is a Robot
									error_message = "Instance specified for place command is not a robot (name : %s)" % (robot_name)
								else:
									Logger.log_info("%-12s %8s" % ["place", robot_name])
									robot.place()
									if not registered_commands.has(robot_name):
										registered_commands[robot_name]={}
									registered_commands[robot_name]["place"] = content["id"]
									
						elif command_info[0] == "navigate_to":
							#apply_command(content['data'],content['id'])
							if command_info.size() != 4:
								error_message = "Wrong number of arguments for navigate_to Command, expected 3 and got %s" % (command_info.size() -1)
							else:
								var robot_name = command_info[1]
								var robot = ExportManager.get_node_from_name(robot_name)
								var dest_x = command_info[2]
								var dest_y = command_info[3]
								var destination = ExportManager.meters_to_pixels([dest_x, dest_y])

								if robot==null or not(robot.has_method("place")):#way to check if the instance is a Robot
									error_message = "Instance specified for navigate_to command is not a robot (name : %s)" % (robot_name)
								else:
									Logger.log_info("%-12s %8s;%8.3f;%8.3f" % ["navigate_to", robot_name, dest_x, dest_y])
									robot.navigate_to(Vector2(destination.x,destination.y))
									if not registered_commands.has(robot_name):
										registered_commands[robot_name]={}
									registered_commands[robot_name]["movement"] = content["id"]
									
						elif command_info[0] == "navigate_to_cell":
							#apply_command(content['data'],content['id'])
							if command_info.size() != 4:
								error_message = "Wrong number of arguments for navigate_to Command, expected 3 and got %s" % (command_info.size() -1)
							else:
								var robot_name = command_info[1]
								var robot = ExportManager.get_node_from_name(robot_name)
								var dest_cell_x = command_info[2]
								var dest_cell_y = command_info[3]

								if robot==null or not(robot.has_method("place")):#way to check if the instance is a Robot
									error_message = "Instance specified for navigate_to_cell command is not a robot (name : %s)" % (robot_name)
								else:
									Logger.log_info("%-12s %8s;%8.3f;%8.3f" % ["navigate_to_cell", robot_name, dest_cell_x, dest_cell_y])
									robot.navigate_to_cell([dest_cell_x, dest_cell_y])
									if not registered_commands.has(robot_name):
										registered_commands[robot_name]={}
									registered_commands[robot_name]["movement"] = content["id"]
									
						elif command_info[0] == "navigate_to_area":
							if command_info.size() != 3:
								error_message = "Wrong number of arguments for navigate_to Command, expected 2 and got %s" % (command_info.size() -1)
							else:
								var robot_name = command_info[1]
								var robot = ExportManager.get_node_from_name(robot_name)
								var area_name = command_info[2]
								
								if robot==null or not(robot.has_method("place")):#way to check if the instance is a Robot
									error_message = "Instance specified for navigate_to_area command is not a robot (name : %s)" % (robot_name)
								else:
									Logger.log_info("%-12s %8s;%8s" % ["navigate_to_area", robot_name, area_name])
									robot.navigate_to_area(area_name)
									if not registered_commands.has(robot_name):
										registered_commands[robot_name]={}
									registered_commands[robot_name]["movement"] = content["id"]
									
						elif command_info[0] == "do_rotation":
							if command_info.size() != 4:
								Logger.log_warning("Wrong number of arguments for do_rotation Command, expected 3 and got %s" % (command_info.size() -1))
							else:
								var robot_name = command_info[1]
								var robot = ExportManager.get_node_from_name(robot_name)
								var angle = command_info[2]
								var speed = command_info[3]
								
								if robot==null or not(robot.has_method("place")):#way to check if the instance is a Robot
									error_message = "Instance specified for do_rotation command is not a robot (name : %s)" % (robot_name)
								else:
									Logger.log_info("%-12s %8s;%8.3f;%8.3f" % ["do_rotation", robot_name, angle, speed])
									robot.do_rotation(angle, speed)
									if not registered_commands.has(robot_name):
										registered_commands[robot_name]={}
									registered_commands[robot_name]["do_rotation"] = content["id"]
									
						var response_message = ""
						if error_message != "":
							Logger.log_warning(error_message)
							response_message = error_message
						else:
							response_message = "Command applied succesfully"
						var encoded = JSON.print({'type': 'response', 'id':content["id"], 'data':response_message})
						client.put_string(encoded)
				
				counter +=1
				if counter>=0:
					counter =0
					#then send state
					var state_message = encode_dynamic()
					
					client.put_string(state_message)

func apply_command(parameters_list : Array, command_id : int):
	var command_info = parameters_list
	var error_message
	
	var command_name = command_info[0]
	var robot_name = command_info[1]
	var robot = ExportManager.get_node_from_name(robot_name)
	var function_parameters = command_info
	function_parameters.remove(1)
	function_parameters.remove(0)
	
	if robot==null:
		error_message = "No instance found corresponding to name specified (%s)" % (robot_name)
		Logger.log_warning(error_message)

	elif not(robot.has_method(command_name)):
		error_message = "Instance specified has no %s command" % (command_name)
		Logger.log_warning(error_message)
	else:
		#Logger.log_info("%-12s %8s;%8.3f;%8.3f" % [command_name, robot_name, angle, speed])
		print( "test_command")
		error_message = robot.call(command_name,function_parameters)
		if not registered_commands.has(robot_name):
			registered_commands[robot_name]={}
		var command_category = ""
		if ["navigate_to","navigate_to_cell","navigate_to_area"].has(command_name):
			command_category = "movement"
		else :
			command_category = command_name
		registered_commands[command_category]["do_rotation"] = command_id
			

	var encoded = JSON.print({'type': 'response', 'id':command_id, 'data':error_message})
	client.put_string(encoded)
		
func send_command_completed(result, command_id):
	var encoded = JSON.print({'type': 'result', 'id':command_id, 'data':result})
	if client!=null and client.is_connected_to_host():
		client.put_string(encoded)
	
func command_result(node_name, command_name, result):
	if registered_commands.has(node_name) and registered_commands[node_name].has(command_name):
		var command_id = registered_commands[node_name][command_name]
		send_command_completed(result, command_id)

			
func set_area_parameters(area, stand : Node):
	#used in the encode_environment_description  to set the area parameters to the area correspondign to the stand Node
	var rectangle = stand.get_area_rectangle()
	var position=rectangle[0]
	var size=rectangle[1]
	area.center = [position.x, position.y]
	area.size = [size.x, size.y]
	area.id = stand.get_instance_id()
			
func encode_static() -> String:
	var env = []
	
	var static_nodes = get_tree().get_nodes_in_group("export_static")
	for node in static_nodes:
	  var static_data = node.call("export_static")
	  env = env + static_data
	
	return JSON.print({'type' : 'static', 'data' :env})

func encode_dynamic() -> String:
	
	var state = []
	
	var dynamic_nodes = get_tree().get_nodes_in_group("export_dynamic")
	for node in dynamic_nodes:
	  var dynamic_data = node.call("export_dynamic")
	  state = state + dynamic_data
		
	return JSON.print({'type' : 'dynamic', 'data' :state})

func disconnect_client():
	if client !=null:
		client.disconnect_from_host()
		client = null
	
func polygon_center(points_list : PoolVector2Array):
	var size = points_list.size()
	var points_sum = Vector2(0,0)
	if size>0:
		for point in points_list:
			points_sum += point
		return points_sum / size
