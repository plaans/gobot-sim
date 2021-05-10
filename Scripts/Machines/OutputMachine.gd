extends "res://Scripts/Machines/Machine.gd"

# A type of machine that get packages out of the scene.
# delete_time is used to determine the time it take the machine to create a package,
# but process_time is used internally. 

export var delete_time: float = 20.0 setget set_delete_time

func _ready():
	process_time = delete_time

func set_delete_time(new_delete_time: float):
	delete_time = new_delete_time
	process_time = new_delete_time

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

func match_process(package: Node)->bool:
	var package_processes = package.processes.get_processes()
	var valid_process: bool = (package_processes.size() == 0)
	return valid_process

# Deletes the processed package
func request_output()->Node:
	var old_package = current_package
	current_package.queue_free()
	current_package = null
	return old_package
