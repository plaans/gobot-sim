extends Node2D


onready var _Navigation = $Navigation2D
onready var _WorldMap = $WorldMap

var _Robot
export (PackedScene) var RobotScene = preload("res://Scenes/Robot.tscn")
var is_jobshop = false
var jobshop_path

var robot_controller

var has_started = false #to prevent from checking for end of simulation from before it has started


func _ready():	

	#values of arguments
	var arguments : Array = Array(OS.get_cmdline_args ())
	
	var rng_seed = int(get_arg(arguments,"--seed",0 ))
	seed(rng_seed)
	
	var time_scale = get_arg(arguments,"--time_scale",null )
	if time_scale!=null:
		Engine.time_scale = float(time_scale)
		
	robot_controller = get_arg(arguments,"--robot_controller","PF" ) #the variable will be used when robots are initialized
	if not (robot_controller in ["none", "PF", "teleport"]):
		Logger.log_warning("Invalid value for robot_controller, ignoring it")
		robot_controller = null
	
		
		
	# Uses the tilemap defined in-engine if no environment is provided
	# Note: current environment is also defined in res://environments/new_environment.json for test purposes
	var environment_file = get_arg(arguments,"--environment","")
	if environment_file != "":
		load_environment(environment_file)
	
	jobshop_path = get_arg(arguments,"--jobshop","" )
	if jobshop_path != "" :
		is_jobshop = true
	
	var scenario_file = get_arg(arguments,"--scenario","res://scenarios/new_scenario_with_environment.json" )
	load_scenario(scenario_file)

	
#	if scenario_file!="" and jobshop_path!="":
#		Logger.log_error("Arguments --scenario and --jobshop have both been specified")
#	elif scenario_file=="" and jobshop_path=="":
#		Logger.log_warning("Neither scenario or jobshop have been passed as argument, using a default scenario")
#		var default_scenario="res://scenarios/new_scenario_with_jobshop.json"
#		load_scenario(default_scenario)
#	elif scenario_file!="":
#		load_scenario(scenario_file)
#	else:
#		load_jobshop(jobshop_path)
	
	
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

func _process(delta):
	if has_started:
		check_end()		
		
func check_end():
	#check if all packages have been processed and if so ends the simulation
	
	#first check that there are no more packages to be generated
	
	var input_machines = get_tree().get_nodes_in_group("input_machines")
	for machine in input_machines:
		if machine.packages_templates!=[]:
			return
	
	#then check there are no packages currently in the simulation
	
	var packages_list = get_tree().get_nodes_in_group("packages")
	#Logger.log_info(packages_list)
	if packages_list.size() == 0:
		Logger.log_info("Exit")
		get_tree().quit()

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
		print( absolute_path)
	
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

# - object is the Object to apply the optional parameters to
# - optional params is an array of parameters names (e.g: ["infinite", "create_time", "create_order", "time_step"])
# which should be valid properties of the given object
# - parameters is the dictionnary of parameters given by the scenario file
# This function is safe and very flexible, invalid values will be ignored but won't output errors or warnings
func set_optional_params(object: Object, optional_params: Array, scenario_object: Dictionary):
	for param in optional_params:
		if scenario_object.has(param):
			object.set(param, scenario_object[param])

func find_closest_machine(target_pos: Vector2, machines: Array, max_distance: float = 1.5)->Node:
	for machine in machines:
		var machine_pos: Vector2 = ExportManager.vector_pixels_to_vector_meters(machine.position)
		# using a distance of 1.5 works even in diagonals
		if machine_pos.distance_to(target_pos) <= max_distance:
			return machine
	return null

func setup_machines_of_type(machine_type: String, machines: Array, scenario: Dictionary):
	if scenario[machine_type].size() != machines.size():
		Logger.log_error("Wrong number of %s : processes specified for %s machines but %s are present in the simulation" 
			% [machine_type, scenario[machine_type].size(), machines.size()])
	else:	
		for i in scenario[machine_type].size():
			#find if there is a machine close enough to the position specified (1.5 meters from the original position)
			var target_pos: Vector2 = Vector2(scenario[machine_type][i].position[0], scenario[machine_type][i].position[1])
			var machine = find_closest_machine(target_pos, machines)
			# If no machine was found
			if machine == null:
				Logger.log_error("Cannot identify the %s for position specified %s" % [machine_type, target_pos])
				continue # skip iteration
			# If the position wasn't exact
			elif ExportManager.vector_pixels_to_vector_meters(machine.position) != target_pos:
				Logger.log_warning("No %s found at position specified %s, so used instead the closest one at position %s" 
					% [machine_type, target_pos, ExportManager.vector_pixels_to_vector_meters(machine.position)])
			
			# Specific parameters and optional ones
			match machine_type:
				"machines":
					# Specify the machine's processes from the scenario
					var new_processes = []
					if scenario.machines[i].has("possible_processes"):
						for process_id in scenario.machines[i].possible_processes:
							new_processes.append(Process.new(process_id))
					machine.processes.processes = new_processes
					# Set optional parameters
					set_optional_params(machine, [], scenario.machines[i])
					
				"input_machines":
					# Specify what packages the InputMachine will create
					var new_packages = []
					if scenario.input_machines[i].has("packages"):
						new_packages = scenario.input_machines[i].packages
					# If no packages have been defined for this inputmachine, use the default ones
					elif scenario.has("packages"):
						new_packages = scenario.packages
					machine.packages_templates = new_packages
					# Set optional parameters
					set_optional_params(machine, ["infinite", "create_order", "create_time", "time_step"], scenario.input_machines[i])
				
				"output_machines":
					# Set optional parameters
					set_optional_params(machine, ["time_step"], scenario.output_machines[i])
			
			# All machines have belts, optional belt parameters are specified here
			if machine.input_belt and scenario[machine_type][i].has("input_belt_size"):
				machine.input_belt.set("size", scenario[machine_type][i]["input_belt_size"])
			if machine.output_belt and scenario[machine_type][i].has("output_belt_size"):
				machine.output_belt.set("size", scenario[machine_type][i]["output_belt_size"])

func load_scenario(file_path : String):
	var scenario_path = get_absolute_path(file_path)
	var scenario = get_file_content(scenario_path)
	
	# Loading environment before everything else
	if scenario!= null:
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
		
		# Setting up the machines
		var all_machines = get_tree().get_nodes_in_group("machines")
		
		var input_machines = []
		var output_machines = []
		var machines = []
		
		for machine in all_machines:
			if machine.is_in_group("input_machines"):
				input_machines.append(machine)
			elif machine.is_in_group("output_machines"):
				output_machines.append(machine)
			else:
				machines.append(machine)
				
		if !is_jobshop && scenario.has("jobshop"):
			jobshop_path = scenario["jobshop"]
			if jobshop_path != "":
				is_jobshop = true
		
		if is_jobshop:
			#in that case load from the jobshop file specified
			load_jobshop(machines, input_machines)

		else:
					
			# Machines
			setup_machines_of_type("machines", machines, scenario)
			# InputMachines
			if scenario.has("output_machines"):
				setup_machines_of_type("output_machines", output_machines, scenario)
			# OutputMachines
			if scenario.has("input_machines"):
				setup_machines_of_type("input_machines", input_machines, scenario)
				
			else:
				# Can happen if:
				# - it's an older scenario
				# - the default parameters are enough
				# - there is only one InputMachine
				for machine in input_machines:
					machine.packages_templates = scenario.packages
				
		# Robots
		for i in range(scenario.robots.size()):
			var new_robot = RobotScene.instance()
			#new_robot.position = Vector2(scenario.robots[i].position[0], scenario.robots[i].position[1])
			new_robot.position = ExportManager.meters_to_pixels(scenario.robots[i].position)
			# Set optional parameters
			set_optional_params(new_robot, ["max_battery", "battery_drain_rate", "battery_charge_rate"], scenario.robots[i])
			
			new_robot.set_controller(robot_controller)
			
			add_child(new_robot)
			
			
			if i==0:
				_Robot = new_robot #to control the first robot with mouse / keyboard
				
		has_started = true
				

func load_jobshop(machines, input_machines):
	#each machine has only one corresponding process
		for k in range(len(machines)):
			var machine = machines[k]
			machine.processes.processes = [Process.new(k+1)]
			
		#load the file and parse it
		var jobshop_absolute_path = get_absolute_path(jobshop_path)
		var file = File.new()
		var open_error = file.open(jobshop_absolute_path, File.READ) 
		if open_error:
			Logger.log_error("Error opening file %s (Error code %s)" % [jobshop_absolute_path, open_error])
			return
		var jobshop_content = file.get_as_text()
		var lines = jobshop_content.split("\n")
		var lines_split=[]
		for line in lines:
			lines_split.append(line.split(" "))
			
		var nb_jobs=int(lines_split[1][0])
		var nb_machines=int(lines_split[1][1])
		if nb_machines!=machines.size():
			Logger.log_error("Wrong number of machines : the jobshop file has %s machines but %s are present in the simulation" 
				% [nb_machines, machines.size()])
		else:
			
			var times = []
			for k in range(3, 3 + nb_jobs):
				var new_array = []
				for value in lines_split[k]:
					if value!="":
						new_array.append(float(value))
				times.append(new_array)
				
			var jobs_list = []
			for k in range(4 + nb_jobs, 4 + 2*nb_jobs):
				var new_array = []
				for value in lines_split[k]:
					if value!="":
						new_array.append(int(value))
				jobs_list.append(new_array)
			
			#combine the list of tasks in each job from two lists (times of tasks and corresponding machines) to one list 
			#of (process_id, duration) which corresponds to the format used in the simulation (here each process_id corresponds to a particular machine)
			var packages_processes_list = []
			for k in range(nb_jobs):
				var durations = times[k]
				var processes = jobs_list[k]
				
				var combined_list = []
				for l in range(durations.size()):
					combined_list.append([processes[l], durations[l]])
					
				packages_processes_list.append(combined_list)	
			
			
			for machine in input_machines:
				machine.packages_templates = packages_processes_list
				set_optional_params(machine, ["time_step"], {"time_step" : 0})
				#set the time_step to 0 for all packages to be generated at the same time

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
				_Robot.navigate_to(get_global_mouse_position(), 96)
			BUTTON_RIGHT:
				_Robot.rotate_to((get_global_mouse_position() - _Robot.position).angle(), 2.0)
