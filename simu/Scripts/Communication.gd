extends Node



var tcp_server #TCP_Server
var client #StreamPeerTCP

var client_counter = 0

var env_sent : bool
var command_applied : bool = false

var registered_commands = {}
var clients_list = []


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
func _process(_delta):
	
	if tcp_server!=null:
			
		#first check if new client is available
		if tcp_server.is_connection_available():
			var new_client = tcp_server.take_connection() 
			clients_list.append(new_client)
			
			#at time of connection, send all static information about static nodes already instanciated before the client connected
			new_client.put_string(encode_static())
			
			
		#then process for every client currently connected
		
		for client in clients_list:
				
			if client==null or !client.is_connected_to_host():
				#if client was disconnected remove from map
				clients_list.erase(client)
			else:
				read_data(client)
				#then send state
				var state_message = encode_dynamic()
				
				client.put_string(state_message)
				
func read_data(client):
	#read if commands were received (read one at most)
	if client.get_available_bytes() > 0:
			
		var response= client.get_string(-1);
		var json = JSON.parse(response)
		var content = json.get_result()
		
		if content["type"] == "robot_command":
			var command_info = content["data"]["command_info"] 
			var command_name = command_info[0]
			var robot_name = command_info[1]
			var function_parameters = command_info
			function_parameters.remove(1)
			function_parameters.remove(0)
			
			var robot_interface = ExportManager.get_robot_interface(robot_name)
			if robot_interface != null:
				robot_interface.receive_command(command_name, function_parameters, content["data"]['temp_id'])
		elif content["type"] == "machine_command":
			#Logger.log_info("new machine command")
			var command_info = content["data"]["command_info"] 
			var command_name = command_info[0]
			var machine_name = command_info[1]
			var function_parameters = command_info
			function_parameters.remove(1)
			function_parameters.remove(0)

			var machine_interface = ExportManager.get_machine_interface(machine_name)
			if machine_interface != null:
				machine_interface.receive_command(command_name, function_parameters, content["data"]['temp_id'])
		elif content["type"] == "cancel_request":
			for robot_interface in ExportManager.get_all_robot_interfaces() :
				robot_interface.cancel_command(content["data"]["action_id"])
			for machine_interface in ExportManager.get_all_machine_interfaces():
				machine_interface.cancel_command(content["data"]["action_id"])
	
					

func send_message(message):
	for client in clients_list:
		if client!=null and client.is_connected_to_host():
			client.put_string(message)

			
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
