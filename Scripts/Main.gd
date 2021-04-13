extends Node

onready var _Robot = get_node("Robots/Robot")
onready var _Package = $Package

export var ROBOT_SPEED = 96 #px/s
# Note:
# 1m ~ 32px
# so 3m/s = 96px/s

const Proto = preload("res://protobuf/proto.gd")
var tcp_server #TCP_Server
var client #StreamPeerTCP


func _ready():
	#for testing purposes we use only one package and initially place it at the first stand
	self.remove_child(_Package)
	var stand = get_node("Stands/Stand")
	stand.add_child(_Package)
	_Package.set_owner(stand)
	
	#values of arguments
	
	var arguments : Array = Array(OS.get_cmdline_args ())
	print( arguments)
	
	var port = int(get_arg(arguments,"--port",10000 ))
		
	var pickup_radius = float(get_arg(arguments,"--pickup-radius",100 ))
	
	print( port)
	print( pickup_radius)
	
	_Robot.get_node("Area2D/Pickup_Sphere").get_shape().set_radius(pickup_radius)
	
	#launch TCP Server
	tcp_server = TCP_Server.new();	
	tcp_server.listen(port)
	
func get_arg(args, arg_name, default):
	var index = args.find(arg_name)
	if index !=-1:
		return args[index+1]
	else:
		return default
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if client!=null and !client.is_connected_to_host():
		#if client was disconnected set variable to null again
		client=null
	
	if client==null and tcp_server.is_connection_available():
		client = tcp_server.take_connection() 

	
	if client != null and client.is_connected_to_host():

		
		#then read if commands were received (read one at most)
		if client.get_available_bytes() > 0:
			var size= client.get_u32 ()
			if size>0:
				var response= client.get_data(size);
				var error = response[0]
				var msg = response[1]
				if error != 0:
					print( "Error : %s" % error)
				else:
					var Command = Proto.Command.new()
					Command.from_bytes(msg)
					
					var command_type = Command.get_command()
					if command_type == Proto.Command.Command_types.GOTO:
						_Robot.goto(Command.get_dir(), Command.get_speed(), Command.get_time()) 
					elif command_type == Proto.Command.Command_types.PICKUP :
						_Robot.pickup()
						
		#first send data about state of world
		var bytes_to_send = _encode_current_state()
		var size_bytes = bytes_to_send.size()
		
		print( size_bytes)
		
		client.put_32(size_bytes)
		client.put_data(bytes_to_send)
			

func _encode_current_state():
	var state = Proto.State.new()
		
	#data about robots (only one for now)
	state.set_nb_robots(1)
	state.add_robots_x(_Robot.position.x)
	state.add_robots_y(_Robot.position.y)
	state.add_is_moving(_Robot.is_moving())
	
	#data about packages (only one for now)
	state.set_nb_packages(1)
	var package_location = state.add_packages_locations()
	if _Package.get_parent() is KinematicBody2D:
		package_location.set_location_type(Proto.State.Location.Type.ROBOT)
	else:
		package_location.set_location_type(Proto.State.Location.Type.STAND)
	package_location.set_location_id(_Package.get_parent().get_index())

	
	
	#data about stands
	var list_stands=$Stands.get_children()
	state.set_nb_stands(list_stands.size())
	for stand in list_stands:		
		state.add_stands_x(stand.position.x)
		state.add_stands_y(stand.position.y)
		
	return state.to_bytes()

func _unhandled_input(event):
	# From GDQuest - Navigation 2D and Tilemaps
	if Input.is_action_pressed("ui_accept"):
		_Robot.pickup()
		
	if not event is InputEventMouseButton:
		return
		
	if event.button_index != BUTTON_LEFT or not event.pressed:
		return
	# -> then, has to be a click from the RMB
	
	var dir_vec: Vector2 = (event.position - _Robot.position)
	var speed = ROBOT_SPEED
	var time = dir_vec.length()/speed
	_Robot.goto(dir_vec.angle(), speed, time)
	
