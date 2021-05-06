extends "res://Scripts/Machines/Machine.gd"

# A type of machine that get packages out of the scene.
# delete_time is used to determine the time it take the machine to create a package,
# but process_time is used internally. 

export var delete_time: float = 20.0 setget set_delete_time

func _ready():
	pass

func set_delete_time(new_delete_time: float):
	delete_time = new_delete_time
	process_time = new_delete_time

func start_process():
	remaining_process_time = process_time
	$AnimationPlayer.play("process")

func set_process_blinking(blink: bool, speed: float = 4.0):
	pass

# Deletes the processed package
func request_output()->Node:
	var old_package = current_package
	current_package.queue_free()
	current_package = null
	return old_package
