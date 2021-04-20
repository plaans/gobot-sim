extends Node


onready var _Package = $Package
onready var _Navigation = $Navigation2D

var _Robot 
export (PackedScene) var RobotScene
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

var pickup_radius 

export var ROBOT_SPEED = 96 #px/s
# Note:
# 1m ~ 32px
# so 3m/s = 96px/s

const Proto = preload("res://protobuf/proto.gd")
var tcp_server #TCP_Server
var client #StreamPeerTCP

var env_sent : bool

var log_name #location to save logs to
var text_to_log : String

func _ready():	
	
	
	#values of arguments
	
	var arguments : Array = Array(OS.get_cmdline_args ())

	var port = int(get_arg(arguments,"--port",10000 ))
		
	pickup_radius = float(get_arg(arguments,"--pickup-radius",100 ))
	
	var rng_seed = int(get_arg(arguments,"--seed",0 ))
	seed(rng_seed)

	var default_log_name = "res://logs/log"+str(OS.get_system_time_msecs())+".txt"
	log_name = get_arg(arguments,"--log", "")
	if log_name == "":
		log_name = default_log_name
		var dir = Directory.new()
		if not(dir.dir_exists("logs")):
			dir.make_dir("logs")
	
	
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
#	var file = File.new()
#	if file.file_exists(log_name):
#		file.open(log_name, File.READ_WRITE) #to open while keeping existing content
#	else:
#		file.open(log_name, File.WRITE) 
#	file.seek_end()
#	file.store_line(text)
#	file.close()
	text_to_log += text 
	text_to_log += "\n"
	
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		var file = File.new()
		if file.file_exists(log_name):
			file.open(log_name, File.READ_WRITE) #to open while keeping existing content
		else:
			file.open(log_name, File.WRITE) 
		file.seek_end()
		file.store_line(text_to_log)
		file.close()
		
func add_package(package : Node):
	packages_list.append(package)
	
func remove_package(package : Node):
	packages_list.remove(packages_list.find(package))
		
func initialization():
	
	packages_list = []
	robots_list = []
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
	
	for k in range(2):
		var robot = RobotScene.instance()
		add_child(robot)
		robot.position = Vector2(100*k+200, 500)
		robot.set_id(k)
		robot.get_node("Area2D/Pickup_Sphere").get_shape().set_radius(pickup_radius)
		
		robots_list.append(robot)
		
	_Robot = robots_list[0]	
	
	for k in range(2):
		var package = PackageScene.instance()
		package.set_id(k)	
		packages_list.append(package)
		
	_Package = packages_list[0]
	_Robot.add_package(_Package)
	_Package.set_processes([[0,3],[1,7]])
	
	robots_list[1].add_child(packages_list[1])
	packages_list[1].set_processes([[1,7],[0,3]])
	
	_Robot.set_id(0)
	
	encode_environment_description()
	
	possible_tasks = [[[0,3],[1,7]]]
	
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
			var bytes_to_send = encode_environment_description()
			var size_bytes = bytes_to_send.size()
			
			client.put_32(size_bytes)
			client.put_data(bytes_to_send)
			env_sent = true
		else:
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
			
func set_area_parameters(area, stand : Node):
	#used in the encode_environment_description  to set the area parameters to the area correspondign to the stand Node
	var rectangle = stand.get_area_rectangle()
	var position=rectangle[0]
	var size=rectangle[1]
	area.set_x(position.x)
	area.set_y(position.y)
	area.set_width(size.x)
	area.set_height(size.y)
			
func encode_environment_description() -> PoolByteArray:
	#creates and serializes a protocol buffer containing the description of the environment of the simulation
	
	var env = Proto.Environment_Description.new()
	
	#info about arrival and delivery areas
	var arrival_area = env.new_arrival_area()
	set_area_parameters(arrival_area, $Arrival_Zone/Output_Belt)
	
	var delivery_area = env.new_delivery_area()
	set_area_parameters(delivery_area, $Delivery_Zone/Input_Belt)
	
	#info about machines
	for machine in machines_list:
		var new_machine = env.add_machines()
		
		var input_area = new_machine.new_input_area()
		set_area_parameters(input_area, machine.get_node("Input_Belt"))
		
		var output_area = new_machine.new_output_area()
		set_area_parameters(output_area, machine.get_node("Output_Belt"))
		
		var buffer_sizes = machine.get_buffer_sizes()
		new_machine.set_input_size(buffer_sizes[0])
		new_machine.set_output_size(buffer_sizes[1])
		
		var list = machine.get_possible_processes()
		 
		for process_id in list:
			new_machine.add_processes_list(process_id)
	
	return env.to_bytes()

func encode_current_state() -> PoolByteArray:
	#creates and serializes a protocol buffer containing the data about the current state of the simulation
	
	var state = Proto.State.new()
	
	#data about robots 
	for robot in robots_list:
		var new_robot = state.add_robots()
		new_robot.set_x(robot.position.x)
		new_robot.set_y(robot.position.y)
		new_robot.set_battery(robot.get_battery_proportion())
		new_robot.set_is_moving(robot.is_moving())
		
		
	#data about packages 
	for package in packages_list:
		var new_package = state.add_packages()
		
		var package_parent = package.get_parent()
		
		var package_location = new_package.new_location()
		if package_parent is KinematicBody2D:
			#case where this package is currently carried by a robot
			package_location.set_location_type(Proto.State.Location.Location_Type.ROBOT)
			package_location.set_parent_id(package_parent.get_id())
		elif package_parent.has_node("Input_Belt"):
			#case where this package is currently in a machine
			if package_parent.is_in_group("input"):
				package_location.set_location_type(Proto.State.Location.Location_Type.MACHINE_INPUT)
			elif package_parent.is_in_group("output"):
				package_location.set_location_type(Proto.State.Location.Location_Type.MACHINE_OUTPUT)
			else:
				package_location.set_location_type(Proto.State.Location.Location_Type.MACHINE_INSIDE)
			package_location.set_parent_id(package_parent.get_id())
			
		else: 
			#case where this package is currently in the arrival zone
			package_location.set_location_type(Proto.State.Location.Location_Type.ARRIVAL)
			package_location.set_parent_id(-1)#no id for arrival zone so set to -1

		var list = package.get_processes()
		for process in list:
			var id = process[0]
			var duration = process[1]
			
			var new_process = new_package.add_processes_list()
			new_process.set_process_id(id)
			new_process.set_process_duration(duration)
		
		
	return state.to_bytes()


func _unhandled_input(event):
	# From GDQuest - Navigation 2D and Tilemaps
	if event.is_action_pressed("ui_accept"):
		_Robot.pickup()
		

	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			BUTTON_LEFT:
				robots_list[0].goto_path(event.position)
			BUTTON_RIGHT:
				robots_list[1].goto_path(event.position)	
				
#			BUTTON_RIGHT:
#				var temp_shape = PoolVector2Array([Vector2(-32,-32),Vector2(-32,32),Vector2(32,32),Vector2(32,-32)])
#				var temp_transform = Transform2D(0, event.position)
#
#				_Navigation.get_node("NavigationPolygonInstance").navpoly = _Navigation.cut_poly(temp_transform.xform(temp_shape))
#			BUTTON_MIDDLE:
#				_Navigation.get_node("NavigationPolygonInstance").navpoly = _Navigation.static_poly

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

