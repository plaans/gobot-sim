extends Node2D

export var progress_gradient: Gradient = preload("res://Assets/progress_gradient.tres")

# Declare member variables here. Examples:
var input_belt: Node = null setget set_input_belt
var output_belt: Node = null setget set_output_belt
# Input and Output are entirely managed by belts
var new_package : Node
var current_package : Node
var current_package_index : int = -1
var current_display_index : int = -1
# Package and Process id being currently done, with the index of the process in
# the package, and the display on the machine

var remaining_process_time: float = 0.0 # remaining time until process is finished, in s
var process_time: float = 0.0 # the duration of the current process, in s
onready var _Progress: TextureProgress = $MachineSprite/TextureProgress
# Progress bar to display the progress of the current process
onready var processes = $ProcessesNode
# List of processes and helper to display processes colors

var machine_name : String
var finished = false

func check_finished() -> bool:
	if finished:
		finished = false
		return true
	else:
		return false


# Called when the node enters the scene tree for the first time.
func _ready():
	#generate a name 
	machine_name = ExportManager.register_new_node(self, "machine")
	ExportManager.add_export_static(self)
	ExportManager.add_export_dynamic(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_processing():
		do_process(delta)
	elif finished_processing():
		#stop_process()
		var old_package = request_output()
		finished = true
	else:
		var new_package = request_input()
		if new_package:
			start_process()

	#elif current_package != null:
	#	start_process()
			
			
func process(package: Node) -> bool:
	var result = false
	if !input_belt.is_empty() and input_belt.packages[0] == package:
		new_package = input_belt.remove_package(0)
		add_child(new_package)
		new_package.position = Vector2.ZERO
		result = true
	return result
#	if is_package_present(package):
#		var index: int = input_belt.find_package_index(package)
#		new_package = input_belt.remove_package(index)
#		add_child(new_package)
#		new_package.position = Vector2.ZERO
#		current_package = new_package
#		start_process()

func is_package_present(package: Node) -> bool:

	var ok = false
	if input_belt and !input_belt.is_empty():
		if input_belt.packages.has(package):
			ok = true
		else:
			ok = false
	else:
		ok = false
	return ok

func get_name() -> String:
	return machine_name

func set_input_belt(belt: Node):
	input_belt = belt
	if belt:
		belt.machine = self
func set_output_belt(belt: Node):
	output_belt = belt
	if belt:
		belt.machine = self

# Given a package returns true if the package's processes 
# are compatible with the machine, else returns false.
# package's modes are:
# 0 = PROCESS_FIRST to check only if the first process of the package can be done by this machine.
# 1 = PROCESS_ANY to check if any process of the package can be done by this machine,
func match_process(package: Node)->bool:
	var package_processes = package.processes.get_processes()
	var valid_process: bool = false
	match package.process_mode:
		0: # PROCESS_FIRST
			if package_processes.size() > 0:
				valid_process = processes.has_process(package_processes[0])
		1: # PROCESS_ANY
			var i: int = 0
			while !valid_process and i < package_processes.size():
				valid_process = processes.has_process(package_processes[i])
	
	return valid_process

func start_process():
	current_package= new_package
	new_package = null
	var package_processes = current_package.processes.get_processes()
	current_display_index = -1
	current_package_index = -1
	match current_package.process_mode:
		0: # PROCESS_FIRST
			current_package_index = 0
			current_display_index = processes.find_process(package_processes[current_package_index])
		1: # PROCESS_ANY
			current_package_index = 0
			# Search the first process of the package that matches a process of the machine
			while current_display_index < 0 and current_package_index < package_processes.size():
				current_display_index = processes.find_process(package_processes[current_package_index])
				current_package_index += 1
	# If the process has not been found, don't process the package and skip it
	if current_display_index < 0 or current_package_index < 0:
		return
	else:
		process_time = package_processes[current_package_index].duration
		remaining_process_time = process_time
		if process_time!=0:
			$AnimationPlayer.play("process")
			set_process_blinking(true)

func do_process(delta: float):
	remaining_process_time -= delta
	_Progress.value = (process_time - remaining_process_time)/process_time*100
	_Progress.tint_progress = progress_gradient.interpolate((process_time - remaining_process_time)/process_time)
	if finished_processing():
		# Remove the current process from this package
		var package_processes = current_package.processes.get_processes()
		Logger.log_info("Process of id %s done for package %s" % [package_processes[current_package_index].id, current_package.package_name])
		current_package.processes.remove_process(current_package_index)
		stop_process()

func stop_process():
	_Progress.value = 0
	$AnimationPlayer.stop()
	set_process_blinking(false)

func set_process_blinking(blink: bool, speed: float = 4.0):
	var tween = $Tween
	var target_display = null
	var step_time: float = (1/speed)/2
	
	if current_display_index >= 0:
		target_display = processes.processes_displays[current_display_index]
	
	if blink:
		if target_display:
			tween.remove(target_display)
			tween.interpolate_property(target_display, "modulate:a", 1.0, 0.0, step_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 0)
			tween.interpolate_property(target_display, "modulate:a", 0.0, 1.0, step_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, step_time)
			tween.start()
	else:
		if target_display:
			tween.remove(target_display)
			target_display.modulate.a = 1.0
		else:
			tween.remove_all()

# Returns true if the machine is currently processing a package.
func is_processing()->bool:
	return remaining_process_time > 0.0
# Returns true if the machine finished the current process but still has a package.
func finished_processing()->bool:
	return !is_processing() and current_package
# Requests to send the current package to the output belt, and returns the package.
# If there is no output belt or the output belt is full, returns null.
func request_output()->Node:
	var old_package = null
	if output_belt and !output_belt.is_full():
		output_belt.add_package(current_package)
		old_package = current_package
		# Set current package
		current_package = null
	return old_package

# Requests a package to process from the input belt, and returns the package.
# if there is no input belt or the input belt is empty, returns null.
func request_input() -> Node:
	return new_package
	

	
func export_static() -> Array:
	var export_data = []
	export_data.append(["Machine.instance", machine_name, "machine"])
	
	export_data.append(["Machine.coordinates", machine_name, ExportManager.vector_pixels_to_meters(position)])
	export_data.append(["Machine.coordinates_tile", machine_name, ExportManager.vector_pixels_to_tiles(position)])
	
	if input_belt:
		export_data.append(["Machine.input_belt", machine_name, input_belt.get_name()])
	
	if output_belt:
		export_data.append(["Machine.output_belt", machine_name, output_belt.get_name()])

	if processes:
		export_data.append(["Machine.processes_list", machine_name, processes.get_processes_ids()])
		
	export_data.append(["Machine.type", machine_name, "standard_machine"])	

	return export_data
	
func export_dynamic() -> Array:
	var export_data=[]
	
	var progress_rate 
	if process_time !=0:
		progress_rate= min(1, (process_time - remaining_process_time)/process_time)
	else:
		progress_rate = 0
		
	export_data.append(["Machine.progress_rate", machine_name, progress_rate])
#	if current_package == null:
#		export_data.append(["Machine.package_processed", machine_name, []])
#	else:
#		export_data.append(["Machine.package_processed", machine_name, current_package.package_name])
	
	return export_data
 
