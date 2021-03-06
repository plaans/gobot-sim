class_name RobotInterface extends Node


var registered_commands = {}

var args_count = {"do_move" : 3, "navigate_to" : 2, "navigate_to_cell" : 2, "navigate_to_area" : 1, "pick" : 0, "pick_package" : 1, "place" : 0, "go_charge" : 0, "do_rotation" : 2, "rotate_to" : 2, "face_belt" : 2}

var action_server

var robot : Node

var initial_position #used for feedback for navigation commands
var total_duration #used for feedback for do_move commands

func _init(robot_node : Node):
	robot = robot_node
	action_server = ActionServer.new()
	
func _process(_delta):
	
	if action_server.current_state == action_server.states.ACTIVE:
		#if command currently in progress check progress to send feedback / result
		var current_command = action_server.command_name
		
		if current_command == "do_move":
			#case of movement command
			if not(robot.is_moving()):
				#result
				action_server.send_result(true)
			else:
				#feedback
				if total_duration!=0:
					var remaining_duration = robot.move_time
					action_server.send_feedback(remaining_duration/total_duration)
				
		if ["navigate_to","navigate_to_cell","navigate_to_area", "go_charge"].has(current_command):
			#case of navigation command
			if not(robot.navigating):
				#result
				action_server.send_result(true)
			else:
				#feedback
				var current_pos = robot.position
				var destination = robot.nav_path[robot.nav_path.size()-1]
				var progress 
				if initial_position.distance_to(destination) == 0:
					progress = 0
				else:
					progress = current_pos.distance_to(destination) / initial_position.distance_to(destination)
				action_server.send_feedback(1 - progress)
				
		if ["do_rotation","rotate_to","face_belt"].has(current_command) :
			#case of rotation command
			
			#result
			if not(robot.is_rotating()):
				action_server.send_result(true)
				

func receive_command(command_name, parameters, temp_id):
		
	if verify_command(command_name, parameters):
		action_server.set_new_goal(command_name, temp_id)
		apply_command(command_name, parameters)
		initial_position = robot.position
	else:
		action_server.reject(temp_id)
		
func cancel_command(command_id):
	if action_server.action_id == command_id:
			
		var current_command = action_server.command_name
		if ["do_move", "navigate_to", "navigate_to_cell", "navigate_to_area", "go_charge"].has(current_command):
			#case of movement command
			robot.stop_navigate()
		elif ["do_rotation","rotate_to","face_belt"].has(current_command):
			robot.stop_rotation()
			
		action_server.cancel_action()
			
func verify_command(command_name : String, parameters : Array) :
	if not(args_count.has(command_name)):
		var error_message = "Command '%s' does not exist" % command_name
		Logger.log_warning(error_message)
		return false
	elif not args_count[command_name] == parameters.size():
		var error_message = "Wrong number of arguments for '%s' command, expected %s and got %s" % [command_name, args_count[command_name],parameters.size()]
		Logger.log_warning(error_message)
		return false
	else:
		return true
			
		
func apply_command(command_name : String, function_parameters : Array):
		if command_name == "pick":
			apply_pick()
			
		elif command_name == "pick_package":
			apply_pick_package(function_parameters)	
			
		elif command_name == "place":
			apply_place()	
			
		elif command_name == "do_move":
			apply_do_move(function_parameters)

		elif command_name == "navigate_to":
			apply_navigate_to(function_parameters)

		elif command_name == "navigate_to_cell":
			apply_navigate_to_cell(function_parameters)
				
		elif command_name == "navigate_to_area":
			apply_navigate_to_area(function_parameters)
			
		elif command_name == "go_charge":
			apply_go_charge(function_parameters)
				
		elif command_name == "do_rotation":
			apply_do_rotation(function_parameters)
				
		elif command_name == "rotate_to":
			apply_rotate_to(function_parameters)
			
		elif command_name == "face_belt":
			apply_face_belt(function_parameters)

	

func command_result(node_name, command_name, result):
	if registered_commands.has(node_name) and registered_commands[node_name].has(command_name):
		var command = registered_commands[node_name][command_name]
		var encoded_message = JSON.print({'type': 'action_result', 'id':command["id"], 'data':result})
		Communication.send_message(encoded_message)
		
func apply_pick():
	Logger.log_info("%-12s %8s" % ["pick", robot.robot_name])
	action_server.send_result(robot.pick())
	
func apply_pick_package(function_parameters):
	var package_name = function_parameters[0]
	var package = ExportManager.get_node_from_name(package_name)
	if package!=null:
		Logger.log_info("%-12s %8s;%8s" % ["pick_package", robot.robot_name, package_name])
		action_server.send_result(robot.pick_package(package))	
	else:
		action_server.send_result(false)	
	
	
func apply_place():
	Logger.log_info("%-12s %8s" % ["place", robot.robot_name])
	action_server.send_result(robot.place())
	
func apply_navigate_to(function_parameters):
	var dest_x = function_parameters[0]
	var dest_y = function_parameters[1]
	var destination = ExportManager.meters_to_pixels([dest_x, dest_y])

	Logger.log_info("%-12s %8s;%8.3f;%8.3f" % ["navigate_to", robot.robot_name, dest_x, dest_y])
	robot.navigate_to(Vector2(destination.x,destination.y))
			
func apply_do_move(function_parameters):
	var angle = function_parameters[0]
	var speed = function_parameters[1]
	var duration = function_parameters[2]
	
	var speed_pixel = ExportManager.meter_to_pixel(speed)

	total_duration = duration #will be used to send feedback

	Logger.log_info("%-12s %8s;%8.3f;%8.3f;%8.3f" % ["do_move", robot.robot_name, angle, speed_pixel, duration])
	robot.do_move(angle, speed_pixel, duration)
	
func apply_navigate_to_cell(function_parameters):
	var dest_cell_x = function_parameters[0]
	var dest_cell_y = function_parameters[1]
	Logger.log_info("%-12s %8s;%8.3f;%8.3f" % ["navigate_to_cell", robot.robot_name, dest_cell_x, dest_cell_y])
	robot.navigate_to_cell([dest_cell_x, dest_cell_y])

func apply_navigate_to_area(function_parameters):
	var area_name = function_parameters[0]
	var area = ExportManager.get_node_from_name(area_name)
	if area!=null and area is Area2D:
		Logger.log_info("%-12s %8s;%8s" % ["navigate_to_area", robot.robot_name, area_name])
		robot.navigate_to_area(area)
		
func apply_go_charge(function_parameters):
	Logger.log_info("%-12s %8s" % ["go_charge", robot.robot_name])
	robot.go_charge()
		
func apply_do_rotation(function_parameters):
	var angle = function_parameters[0]
	var speed = function_parameters[1]
	Logger.log_info("%-12s %8s;%8.3f;%8.3f" % ["do_rotation", robot.robot_name, angle, speed])
	robot.do_rotation(angle, speed)	
				
func apply_rotate_to(function_parameters):
	var angle = function_parameters[0]
	var speed = function_parameters[1]
	Logger.log_info("%-12s %8s;%8.3f;%8.3f" % ["rotate_to", robot.robot_name, angle, speed])
	robot.rotate_to(angle, speed)		
	
func apply_face_belt(function_parameters):
	var node_name = function_parameters[0]
	var speed = function_parameters[1]
	
	var node = ExportManager.get_node_from_name(node_name)
	if node!=null:
		Logger.log_info("%-12s %8s;%8s;%8.3f" % ["face_belt", robot.robot_name, node_name, speed])
		robot.face_belt(node, speed)					
