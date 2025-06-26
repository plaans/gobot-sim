class_name MachineInterface extends Node

var registered_commands = {}

var args_count = {"process" : 1}

var action_server

var machine : Node

func _init(machine_node : Node):
	machine = machine_node
	action_server = ActionServer.new()
	
func _process(_delta):
	
	if action_server.current_state == action_server.states.ACTIVE:
		#if command currently in progress check progress to send feedback / result
		var current_command = action_server.command_name
		
		if current_command == "process":
			if machine.check_finished():
				action_server.send_result(true)
			else:
				#feedback
				var remaining_duration = machine.remaining_process_time
				var total_duration = machine.process_time
				action_server.send_feedback(remaining_duration/total_duration)
				

func receive_command(command_name, parameters, temp_id):
	
	if !machine.is_processing() and verify_command(command_name, parameters):
		action_server.set_new_goal(command_name, temp_id)
		apply_command(command_name, parameters)
	else:
		action_server.reject(temp_id)
		
func cancel_command(command_id):
	if action_server.action_id == command_id:
			
		var current_command = action_server.command_name
			
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
	if command_name == "process":
		apply_process(function_parameters)


func command_result(node_name, command_name, result):
	if registered_commands.has(node_name) and registered_commands[node_name].has(command_name):
		var command = registered_commands[node_name][command_name]
		var encoded_message = JSON.print({'type': 'action_result', 'id':command["id"], 'data':result})
		Communication.send_message(encoded_message)
	
func apply_process(function_parameters):
	var package_name = function_parameters[0]
	var package = ExportManager.get_node_from_name(package_name)
	if package!=null:
		Logger.log_info("%-12s %8s;%8s" % ["process", machine.machine_name, package_name])
		if !machine.process(package):
			action_server.send_result(false)	
