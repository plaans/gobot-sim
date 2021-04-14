extends Node

onready var _Robot = get_node("Robots/Robot")
export (PackedScene) var PackageScene
export (PackedScene) var MachineScene
#onready var _Package = $Package
var _Package

var machines_list
#each element of the array is a Machine node

var processes_list
#each element of the array is an array of integers 
#corresponding to the machines possible for the given process
#example : if process no.3 can be done by machines 4 or 5, 
#		   then the element at index 3 can be [4,5] (or [5,4])

export var ROBOT_SPEED = 96 #px/s
# Note:
# 1m ~ 32px
# so 3m/s = 96px/s

const Proto = preload("res://protobuf/proto.gd")
var tcp_server #TCP_Server
var client #StreamPeerTCP


func _ready():	
	#initialization
	initialization()
	
	#values of arguments
	
	var arguments : Array = Array(OS.get_cmdline_args ())

	
	var port = int(get_arg(arguments,"--port",10000 ))
		
	var pickup_radius = float(get_arg(arguments,"--pickup-radius",100 ))
	
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
		
func initialization():
	machines_list = []
	for k in range(3):
		var machine = MachineScene.instance()
		add_child(machine)
		machine.position = Vector2(150*k +300, 150*k+100)
		machines_list.append(machine)
	
	processes_list=[]
	processes_list.append([0,2])
	processes_list.append([0,1])
	#for example the machines 0 or 2 can be used for the process 0 
	
	machines_list[0].set_possible_processes([0,1])  # the machine 0 can do processes 0 or 1
	machines_list[1].set_possible_processes([1])
	machines_list[2].set_possible_processes([0])
	
	#for testing purposes we use only one package and initially place it at the first stand
	_Package = PackageScene.instance()
	#var stand = get_node("Stands/Stand")
	 #remove_child(_Package)
	_Robot.add_package(_Package)
	_Package.set_processes([[0,3],[1,7]])
	
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
		var bytes_to_send = encode_current_state()
		var size_bytes = bytes_to_send.size()
		
		client.put_32(size_bytes)
		client.put_data(bytes_to_send)
			

func encode_current_state():
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
	if event.is_action_pressed("ui_accept"):
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
	
