extends Node2D


# Declare member variables here. Examples:
var input_belt: Node = null setget set_input_belt
var output_belt: Node = null setget set_output_belt
# Input and Output are entirely managed by belts

var current_package : Node
var current_process_id : int
var current_process_id_index : int
# Package and Process id being currently done, with the index of the id 
# in the processes_ids array

var remaining_process_time: float = 0.0 # remaining time until process is finished, in s
var process_time: float = 0.0 # the duration of the current process, in s
onready var _Progress: TextureProgress = $MachineSprite/TextureProgress
# Progress bar to display the progress of the current process
onready var _Processes = $ProcessesNode
# List of processes and helper to display processes colors

enum {
	PROCESS_ANY,
	PROCESS_FIRST
}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_processing():
		do_process(delta)
	elif finished_processing():
		pass
	else:
		pass

func set_input_belt(belt: Node):
	input_belt = belt
	belt.machine = self
func set_output_belt(belt: Node):
	output_belt = belt
	belt.machine = self

# Given a package and a search mode, returns true if the package's processes 
# are compatible with the machine, else returns false.
# modes are:
# PROCESS_ANY to check if any process of the package can be done by this machine,
# PROCESS_FIRST to check only if the first process of the package can be done by this machine.
func match_process(package: Node, mode: int = PROCESS_ANY)->bool:
	var package_processes = package.get_processes()
	var valid_process: bool = false
	match mode:
		PROCESS_ANY:
			var i: int = 0
			while !valid_process and i < package_processes.size():
				valid_process = _Processes.has_process(package_processes[i])
		PROCESS_FIRST:
			if package_processes.size() > 0:
				valid_process = _Processes.has_process(package_processes[0])
	
	return valid_process

func start_process():
	pass
	# TODO: set current_package and the id and index of the current process
	# TODO: set process_time and remaining_process_time
	# TODO: make process display blink

func do_process(delta: float):
	remaining_process_time -= delta
	_Progress.value = (remaining_process_time/process_time)*100
	if !is_processing():
		stop_process()

func stop_process():
	pass
	# TODO: stop process display blinking

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
	return old_package

# Requests a package to process from the input belt, and returns the package.
# if there is no input belt or the input belt is empty, returns null.
# Note: processing and adding the new package must be done outside of this function
func request_input()->Node:
	var new_package = null
	if input_belt and !input_belt.is_empty():
		new_package = input_belt.remove_package(0)
	return new_package
	
 
