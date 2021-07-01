extends "res://Scripts/Machines/Machine.gd"

# A type of machine that creates packages in the scene.
# create_time is used to determine the time it take the machine to create a package,
# but process_time is used internally. 

enum Order {
	NORMAL,
	REVERSE,
	RANDOM
}
enum Time {
	FIXED,
	RANDOMIZED
}
export(Order) var create_order = Order.NORMAL
export(Time) var create_time = Time.FIXED
export var time_step: float = 15.0 setget set_time_step
export var infinite: bool = false
export(PackedScene) var package_scene = preload("res://Scenes/Package.tscn")

# Templates are in the form of an array containing all the processes to do for this package 
# [[process_id, process_duration],...]
var packages_templates: Array = []

func _ready():
	process_time = time_step
	
	add_to_group("export_static")
	
	#generate a name 
	machine_name = ExportManager.register_new_node(self, "input_machine")

func set_time_step(new_time_step: float):
	time_step = new_time_step
	process_time = new_time_step

func start_process():
	remaining_process_time = process_time
	$AnimationPlayer.play("process")

func do_process(delta: float):
	remaining_process_time -= delta
	_Progress.value = (process_time - remaining_process_time)/process_time*100
	_Progress.tint_progress = progress_gradient.interpolate((process_time - remaining_process_time)/process_time)
	if finished_processing():
		stop_process()

func set_process_blinking(blink: bool, speed: float = 4.0):
	pass

# Creates a random package from the packages_templates, and returns the package.
# 
func request_input()->Node:
	var new_package = null
	if packages_templates.size() > 0:
		# Which package to output
		var templates_index: int = 0
		match create_order:
			Order.RANDOM:
				templates_index = randi() % packages_templates.size()
			Order.REVERSE:
				templates_index = -1
			_:
				templates_index = 0
		
		var template = packages_templates[templates_index]
		if !infinite:
			packages_templates.remove(templates_index)
		
		# Create processes from the template
		var new_processes := []
		for process_array in template:
			new_processes.append(Process.new(process_array[0], process_array[1]))
		# Create actual package
		new_package = package_scene.instance()
		add_child(new_package)
		new_package.position = Vector2.ZERO
		new_package.processes.processes = new_processes
		
		# Time to create the package
		match create_time:
			Time.RANDOM:
				process_time = -log(randf())/(1/time_step)
			_:
				process_time = time_step
		
		current_package = new_package
	return new_package
