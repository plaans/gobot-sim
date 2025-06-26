extends "res://Scripts/Machines/Machine.gd"

# A type of machine that get packages out of the scene.
# time_step is used to determine the time it take the machine to create a package,
# but process_time is used internally. 

export var time_step: float = 10.0 setget set_time_step

func _ready():
	process_time = time_step
	
	add_to_group("export_static")
	
	#generate a name 
	machine_name = ExportManager.register_new_node(self, "output_machine")

func set_time_step(new_time_step: float):
	time_step = new_time_step
	process_time = new_time_step

func start_process():
	remaining_process_time = process_time
	if process_time!=0:
		$AnimationPlayer.play("process")

func do_process(delta: float):
	remaining_process_time -= delta
	_Progress.value = (process_time - remaining_process_time)/process_time*100
	_Progress.tint_progress = progress_gradient.interpolate((process_time - remaining_process_time)/process_time)
	if finished_processing():
		Logger.log_info("Package %s delivered" % [current_package.package_name])
		stop_process()

func set_process_blinking(blink: bool, speed: float = 4.0):
	pass

func match_process(package: Node)->bool:
	var package_processes = package.processes.get_processes()
	var valid_process: bool = (package_processes.size() == 0)
	return valid_process

func request_input()->Node:
	var new_package = null
	if input_belt and !input_belt.is_empty():
		new_package = input_belt.remove_package(0)
		add_child(new_package)
		new_package.position = Vector2.ZERO
		# Set current package
		current_package = new_package
	return new_package
# Deletes the processed package
func request_output()->Node:
	var old_package = current_package
	current_package.queue_free()
	current_package = null
	return old_package
	
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
		
	export_data.append(["Machine.type", machine_name, "output_machine"])	

	return export_data
