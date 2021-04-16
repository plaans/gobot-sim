extends Node


onready var _Package = $Package
onready var _Navigation = $Navigation2D

onready var _Robot = get_node("Robot")
export (PackedScene) var PackageScene
export (PackedScene) var MachineScene


var packages_list

var machines_list
#each element of the array is a Machine node

var robots_list

var processes_list
#each element of the array is an array of integers 
#corresponding to the machines possible for the given process
#example : if process no.3 can be done by machines 4 or 5, 
#		   then the element at index 3 can be [4,5] (or [5,4])

var possible_tasks

export var ROBOT_SPEED = 96 #px/s
# Note:
# 1m ~ 32px
# so 3m/s = 96px/s

const Proto = preload("res://protobuf/proto.gd")
var tcp_server #TCP_Server
var client #StreamPeerTCP

var log_name #location to save logs to


func _ready():	
	#initialization
	initialization()

	for node in get_tree().get_nodes_in_group("stands"):
		var shape_transform: Transform2D = node.get_node("CollisionShape2D").get_global_transform()
		var shape: RectangleShape2D = node.get_node("CollisionShape2D").shape
		var shape_poly := PoolVector2Array([
			Vector2(-shape.extents.x, -shape.extents.y),
			Vector2(-shape.extents.x, shape.extents.y),
			Vector2(shape.extents.x, shape.extents.y),
			Vector2(shape.extents.x, -shape.extents.y)
		])
		shape_poly = Geometry.offset_polygon_2d(shape_poly, _Navigation.nav_margin)[0]
		
		_Navigation.get_node("NavigationPolygonInstance").navpoly = _Navigation.cut_poly(shape_transform.xform(shape_poly), true)

	
	#values of arguments
	
	var arguments : Array = Array(OS.get_cmdline_args ())

	var port = int(get_arg(arguments,"--port",10000 ))
		
	var pickup_radius = float(get_arg(arguments,"--pickup-radius",100 ))
	_Robot.get_node("Area2D/Pickup_Sphere").get_shape().set_radius(pickup_radius)
	
	var rng_seed = int(get_arg(arguments,"--seed",0 ))
	seed(rng_seed)

	var default_log_name = "res://logs/log"+str(OS.get_system_time_msecs())+".txt"
	log_name = get_arg(arguments,"--log", default_log_name)
	
	#launch TCP Server
	tcp_server = TCP_Server.new();	
	tcp_server.listen(port)
	
func get_arg(args, arg_name, default):
	var index = args.find(arg_name)
	if index !=-1:
		return args[index+1]
	else:
		return default
		
func log_text(text : String):
	var file = File.new()
	if file.file_exists(log_name):
		file.open(log_name, File.READ_WRITE) #to open while keeping existing content
	else:
		file.open(log_name, File.WRITE) 
	file.seek_end()
	file.store_line(text)
	file.close()
		
func add_package(package : Node):
	packages_list.append(package)
	
func remove_package(package : Node):
	packages_list.remove(packages_list.find(package))
		
func initialization():
	
	packages_list = []
	machines_list = []
	for k in range(3):
		var machine = MachineScene.instance()
		add_child(machine)
		machine.position = Vector2(700, 450 - 150*k)
		machine.set_id(k)
		machines_list.append(machine)
		
	
	processes_list=[]
	processes_list.append([0,2])
	processes_list.append([0,1])
	#for example the machines 0 or 2 can be used for the process 0 
	
	machines_list[0].set_possible_processes([0,1])  # the machine 0 can do processes 0 or 1
	machines_list[0].set_buffer_sizes(5,2)
	machines_list[1].set_possible_processes([1])
	machines_list[2].set_possible_processes([0])
	
	#for testing purposes we use only one package and initially place it at the first stand
	_Package = PackageScene.instance()
	_Robot.add_package(_Package)
	_Package.set_processes([[0,3],[1,7]])
	packages_list.append(processes_list)
	
	possible_tasks = [[[0,3],[1,7]]]
	
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
	#creates and serializes a protocol buffer containing the data about the current state of the simulation
	
	var state = Proto.State.new()
	
	#data about robots 
	for robot in robots_list:
		var new_robot = state.add_robots()
		new_robot.set_x(robot.position.x)
		new_robot.set_y(robot.position.y)
		new_robot.set_is_moving(robot.is_moving())
		
	#data about packages 
	for package in packages_list:
		var new_package = state.add_packages()
		
	
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
		

	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			BUTTON_LEFT:
				_Robot.goto_path(event.position)
			BUTTON_RIGHT:
				var temp_shape = PoolVector2Array([Vector2(-32,-32),Vector2(-32,32),Vector2(32,32),Vector2(32,-32)])
				var temp_transform = Transform2D(0, event.position)
				
				_Navigation.get_node("NavigationPolygonInstance").navpoly = _Navigation.cut_poly(temp_transform.xform(temp_shape))
			BUTTON_MIDDLE:
				_Navigation.get_node("NavigationPolygonInstance").navpoly = _Navigation.static_poly

	if event.is_action_pressed("ui_down"):
		#to simply generate a package (carried by the robot) with a simple key press for testing purposes
		_Package = PackageScene.instance()
		_Robot.add_package(_Package)
		_Package.set_processes([[0,3],[1,7]])



func _on_Parking_Area_body_entered(body):
	#body is necessarily a robot since only moving body
	body.set_in_station(true)


func _on_Parking_Area_body_exited(body):
	#body is necessarily a robot since only moving body
	body.set_in_station(false)

