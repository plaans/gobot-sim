extends Node


onready var _Package = $Package
onready var _Navigation = $Navigation2D

onready var _Robot = get_node("Robot")
export (PackedScene) var RobotScene
export (PackedScene) var PackageScene
export (PackedScene) var MachineScene

var packages_list

var machines_list
#each element of the array is a Machine node

var robots_list

var packages_nb : int = 0

#var processes_list
#each element of the array is an array of integers 
#corresponding to the machines possible for the given process
#example : if process no.3 can be done by machines 4 or 5, 
#		   then the element at index 3 can be [4,5] (or [5,4])

var possible_tasks

func _ready():	
	#initialization
	var test_templates = [ [[0,10],[1,5]], [[0,1],[1,8],[2,6]], [[2,3],[1,9]], [[2,7],[0,12],[5,4]] ]
	var test_processes = [[Process.new(0,0), Process.new(1,0), Process.new(2,0)], [Process.new(2,0), Process.new(3,0), Process.new(4,0), Process.new(5,0)]]
	var machine_nb := 0
	for machine in get_tree().get_nodes_in_group("machines"):
		if machine.is_in_group("input_machines"):
			machine.packages_templates = test_templates
			machine.create_time = 5.0
		elif machine.is_in_group("output_machines"):
			pass
		else:
			machine.processes.processes = test_processes[machine_nb]
			machine_nb += 1

	#values of arguments
	
	var arguments : Array = Array(OS.get_cmdline_args ())
	
	var pickup_radius = float(get_arg(arguments,"--pickup-radius",100 ))
	_Robot.get_node("RayCast2D").set_cast_to(Vector2.RIGHT*pickup_radius)
	
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
	for k in range(4):
		var machine = MachineScene.instance()
		add_child(machine)
		machine.position = Vector2(350 + 350*(k%2), 450 - 150*(k/2))
		machines_list.append(machine)
	
	load_scenario("res://scenarios/test_scenario.json")
	
	_Robot = robots_list[0]
	
func load_scenario(file_path : String):
	var file = File.new()
	var open_error = file.open(file_path, File.READ) 
	if open_error:
		Logger.log_error("Error opening the scenario file (Error code %s)" % open_error)
		return
		
	var content = JSON.parse(file.get_as_text())
	file.close()
	
	if content.get_error():
		Logger.log_error("Error parsing the scenario file (Error code %s)" % content.get_error())
		return	
		
	var scenario = content.get_result()
	
	if scenario.machines.size()!=machines_list.size():
		Logger.log_error("Wrong number of machines : processes specified for %s machines but there are %s machines in the simulation" 
						% [scenario.machines.size(),machines_list.size()])
	
	for k in range(machines_list.size()):
		var processes = scenario.machines[k].possible_processes
		for i in range (processes.size()):
			processes[i] = int(processes[i])
			
		var position = scenario.machines[k].position
		var x = position[0]
		var y = position[1]

	#find if there is a machine close enough to the position specified (for now search for distance <50)
		var closest_machine = null
		var dist_min = 100
		for machine in machines_list:
			var dist = machine.position.distance_to(Vector2(x,y))
			if dist <=50 and dist<dist_min:
				closest_machine = machine
				dist_min = dist
		if closest_machine == null:
			Logger.log_error("Cannot identify the machine for position specified (%s %s)" % [x,y])
		else:
			#a machine was found close enough but if position was not exact still register a warning
			if dist_min>0:
				Logger.log_warning("No machine found at position specified (%s %s), so used instead the closest one at position (%s %s) " 
				% [x,y,closest_machine.position.x,closest_machine.position.y])
			
			#closest_machine.set_possible_processes(processes)
			
	for k in range(scenario.robots.size()):
		var new_robot = RobotScene.instance()
		add_child(new_robot)
		var new_position = scenario.robots[k].position
		new_robot.position.x = new_position[0]
		new_robot.position.y = new_position[1]
		robots_list.append(new_robot)
		
	#$Arrival_Zone.set_next_packages(scenario.packages)
	print( scenario)

func _unhandled_input(event):
	# From GDQuest - Navigation 2D and Tilemaps
	if event.is_action_pressed("ui_accept"):
		_Robot.pickup()
		print( ExportManager.pixels_to_meters(_Robot.position))
		
	if event.is_action_pressed("ui_left"):
		_Robot.do_rotation(-PI/2, 2.0)
	if event.is_action_pressed("ui_right"):
		_Robot.do_rotation(PI/2, 2.0)

	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			BUTTON_LEFT:
				_Robot.navigate_to(event.position)
			BUTTON_RIGHT:
#				var temp_shape = PoolVector2Array([Vector2(-32,-32),Vector2(-32,32),Vector2(32,32),Vector2(32,-32)])
#				var temp_transform = Transform2D(0, event.position)
#				_Navigation.get_node("NavigationPolygonInstance").navpoly = _Navigation.cut_poly(temp_transform.xform(temp_shape))
				var angle = _Robot.get_angle_to(event.position)
				_Robot.do_rotation(angle, 2.0)
			BUTTON_MIDDLE:
#				_Navigation.get_node("NavigationPolygonInstance").navpoly = _Navigation.static_poly
				pass
