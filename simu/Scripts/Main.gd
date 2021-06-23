extends Node


onready var _Navigation = $Navigation2D
onready var _WorldMap = $WorldMap

var _Robot
export (PackedScene) var RobotScene = preload("res://Scenes/Robot.tscn")


func _ready():	

	#values of arguments
	var arguments : Array = Array(OS.get_cmdline_args ())
	
	var rng_seed = int(get_arg(arguments,"--seed",0 ))
	seed(rng_seed)
	
	# Uses the tilemap defined in-engine if no environment is provided
	# Note: current environment is also defined in res://environments/new_environment.json for test purposes
	var environment_file = get_arg(arguments,"--environment","")
	if environment_file != "":
		load_environment(environment_file)
	
	var scenario_file = get_arg(arguments,"--scenario","res://scenarios/new_scenario_with_environment.json" )
	load_scenario(scenario_file)
	
	var pickup_radius = float(get_arg(arguments,"--pickup-radius",500 ))
	var robots_list = get_tree().get_nodes_in_group("robots")
	for robot in robots_list:
		robot.get_node("RayCast2D").set_cast_to(Vector2.RIGHT*pickup_radius)
	
	
	var log_name = get_arg(arguments,"--log", "")
	if log_name == "":
		var default_dir = OS.get_executable_path().get_base_dir()
		var default_log_name = "log"+str(OS.get_system_time_msecs())+".log"
		
		var dir = Directory.new()
		dir.open(default_dir)
		if not(dir.dir_exists("simu_logs")):
			dir.make_dir("simu_logs")
		log_name = default_dir + "/simu_logs/" + default_log_name
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

func get_absolute_path(file_path: String)->String:
	var absolute_path: String
	
	if "res://" in file_path:
		#in that case no need to convert path to absolute path
		absolute_path = file_path
	else:
		#convert path to absolute path
		var separated_path
		if '/' in file_path:
			separated_path = file_path.split('/')
		else:
			separated_path = file_path.split('\\')
		var file_name = separated_path[-1]
		separated_path.remove(separated_path.size()-1)
		var directory_path = separated_path.join("/")
		
		var dir = Directory.new()
		dir.open(OS.get_executable_path().get_base_dir())
		dir.change_dir(directory_path)
		
		absolute_path = dir.get_current_dir() + "/" + file_name
	
	return absolute_path

func get_file_content(file_path: String):
	# Load file
	var file = File.new()
	var open_error = file.open(file_path, File.READ) 
	if open_error:
		Logger.log_error("Error opening file %s (Error code %s)" % [file_path, open_error])
		return
		
	var content = JSON.parse(file.get_as_text())
	file.close()
	
	if content.get_error():
		Logger.log_error("Error parsing file %s (Error code %s)" % [file_path, content.get_error()])
		return	
		
	return content.get_result()

func load_scenario(file_path : String):
	var scenario_path = get_absolute_path(file_path)
	var scenario = get_file_content(scenario_path)
	
	# Loading environment before everything else
	if scenario.has("environment"):
		if _WorldMap.world != null:
			Logger.log_warning("Environment in scenario has been overridden by command-line argument")
		else:
			load_environment(scenario["environment"])
	else:
		if _WorldMap.world != null:
			Logger.log_warning("No environment field in scenario, but environment has been overridden by command-line argument")
		else:
			Logger.log_error("No environment field in scenario")
			return
	
	#machines
	var all_machines_list = get_tree().get_nodes_in_group("machines")
	#filter to exclude intput and output machines
	
	var machines_list = []
	for machine in all_machines_list:
		if not(machine.is_in_group("input_machines")) and not(machine.is_in_group("output_machines")):
			machines_list.append(machine)
			
	if scenario.machines.size()!=machines_list.size():
		Logger.log_error("Wrong number of machines : processes specified for %s machines but there are %s machines in the simulation" 
						% [scenario.machines.size(),machines_list.size()])
	else:	
		for k in range(scenario.machines.size()):	
			var position = scenario.machines[k].position
			var x = position[0]
			var y = position[1]

		#find if there is a machine close enough to the position specified (for now search for distance <50)
			var closest_machine = null
			var closest_machine_x = 0
			var closest_machine_y = 0
			for machine in machines_list:
				var position_machine_pixels = ExportManager.vector_pixels_to_meters(machine.position)
				var machine_x = floor(position_machine_pixels[0])
				var machine_y = floor(position_machine_pixels[1])
				if abs(machine_x-x)<=1 and abs(machine_y-y)<=1:
					closest_machine = machine
					closest_machine_x = machine_x
					closest_machine_y = machine_y
			if closest_machine == null:
				Logger.log_error("Cannot identify the machine for position specified (%s %s)" % [x,y])
			else:
				#a machine was found close enough but if position was not exact still register a warning
				if closest_machine_x != x or closest_machine_y != y:
					Logger.log_warning("No machine found at position specified (%s %s), so used instead the closest one at position (%s %s) " 
					% [x,y,closest_machine_x,closest_machine_y])
				
				var new_processes_list = []
				for process_id in scenario.machines[k].possible_processes:
					new_processes_list.append(Process.new(process_id))
					
				closest_machine.processes.processes = new_processes_list
			
	
	#robots		
	for k in range(scenario.robots.size()):
		var new_robot = RobotScene.instance()
		add_child(new_robot)
		var new_position = scenario.robots[k].position
		new_robot.position.x = new_position[0]
		new_robot.position.y = new_position[1]
		
		if k==0:
			_Robot = new_robot
		
	#packages
	for machine in get_tree().get_nodes_in_group("input_machines"):
			machine.packages_templates = scenario.packages
			machine.create_time = 5.0
		

func load_environment(file_path : String):
	if file_path != "":
		var environment_path = get_absolute_path(file_path)
		var environment = get_file_content(environment_path)

		if typeof(environment) != TYPE_DICTIONARY:
			Logger.log_error("Environment is not a dictionnary")
		var fields = ["data", "offset"]
		for field in fields:
			# Check if the environment contains the fields needed
			if !(field in environment):
				Logger.log_error("No field %s found in environment file" % [field])
			# Check if the field's type is correct 
			elif typeof(environment[field]) != TYPE_ARRAY:
				Logger.log_error("Field %s of environment is not an array" % [field])
			# The data is supposed to be an array of arrays
			if field == fields[0]:
				for i in environment[field].size():
					if typeof(environment[field][i]) != TYPE_ARRAY:
						Logger.log_error("Row %s in %s field is not an array" % [i, field])
		
		# Sets the tilemap's TileWorld from the environment
		_WorldMap.world = TileWorld.new(environment)
		_WorldMap.update_tiles_from_world()
		
		_WorldMap.make_environment()
		_Navigation.make_navigation()
	else:
		Logger.log_error("No path to environment given")

func _unhandled_input(event):
	if event.is_action_pressed("ui_up"):
		_Robot.pick()
	if event.is_action_pressed("ui_down"):
		_Robot.place()
		
	if event.is_action_pressed("ui_left"):
		_Robot.rotate_to(_Robot.rotation-PI/2, 2.0)
	if event.is_action_pressed("ui_right"):
		_Robot.rotate_to(_Robot.rotation+PI/2, 2.0)

	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			BUTTON_LEFT:
				_Robot.navigate_to(event.position, 96)
			BUTTON_RIGHT:
#				var temp_shape = PoolVector2Array([Vector2(-32,-32),Vector2(-32,32),Vector2(32,32),Vector2(32,-32)])
#				var temp_transform = Transform2D(0, event.position)
#				_Navigation.get_node("NavigationPolygonInstance").navpoly = _Navigation.cut_poly(temp_transform.xform(temp_shape))
				_Robot.rotate_to((event.position - _Robot.position).angle(), 2.0)
			BUTTON_MIDDLE:
#				_Navigation.get_node("NavigationPolygonInstance").navpoly = _Navigation.static_poly
				pass
