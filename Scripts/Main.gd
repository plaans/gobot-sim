extends Node


onready var _Package = $Package
onready var _Navigation = $Navigation2D

var _Robot 
export (PackedScene) var RobotScene
export (PackedScene) var PackageScene
export (PackedScene) var MachineScene

const color_palette : Array = ["cornflower", "crimson ", "yellow", "seagreen", "sandybrown", "skyblue ", "lightpink ", "palegreen ", "aquamarine", "saddlebrown"] #list of colorsto be used to represent processes

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
		shape_poly = shape_transform.xform(shape_poly);
		shape_poly = Geometry.offset_polygon_2d(shape_poly, _Navigation.nav_margin)[0]

		_Navigation.set_navpoly(_Navigation.cut_poly(shape_poly, true))

	

	#values of arguments
	
	var arguments : Array = Array(OS.get_cmdline_args ())

	
	
	var rng_seed = int(get_arg(arguments,"--seed",0 ))
	seed(rng_seed)

	var default_log_name = "res://logs/log"+str(OS.get_system_time_msecs())+".log"
	var log_name = get_arg(arguments,"--log", "")
	if log_name == "":
		log_name = default_log_name
		var dir = Directory.new()
		if not(dir.dir_exists("logs")):
			dir.make_dir("logs")
	Logger.set_log_location(log_name)

	
	#launch Communication Server
	var port = int(get_arg(arguments,"--port",10000 ))
	Communication.start_server(port)
	

	
	
func get_arg(args, arg_name, default):
	var index = args.find(arg_name)
	if index !=-1:
		return args[index+1]
	else:
		return default
		
func get_color_palette():
	return color_palette 		

	
func add_package(package : Node):
	packages_list.append(package)
	
func remove_package(package : Node):
	var package_index = packages_list.find(package)
	if package_index >= 0 :
		packages_list.remove(package_index)
		
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
#
#	for k in range(2):
#		var robot = RobotScene.instance()
#		add_child(robot)
#		robot.position = Vector2(100*k+200, 500)
#		robot.set_id(k)
#
#		robots_list.append(robot)
		
	_Robot = $Robot
	
#	var _Package = PackageScene.instance()
#	packages_list.append(_Package)
#	_Robot.add_package(_Package)
#	_Package.set_processes([[0,3],[1,7]])
	
	#robots_list[1].add_child(packages_list[1])
	#packages_list[1].set_processes([[1,7],[0,3]])
	
	#_Robot.set_id(0)

func _unhandled_input(event):
	# From GDQuest - Navigation 2D and Tilemaps
	if event.is_action_pressed("ui_accept"):
		_Robot.pickup()
		
	if event.is_action_pressed("ui_left"):
		_Robot.do_rotation(-1,0.5)
	if event.is_action_pressed("ui_right"):
		_Robot.do_rotation(1,1.5)

	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			BUTTON_LEFT:
				_Robot.navigate_to(event.position)
				
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
		packages_list.append(_Package)
