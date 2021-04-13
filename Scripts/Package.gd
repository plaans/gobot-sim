extends Node2D


# Declare member variables here. Examples:

var processes_list : Array
#Array of 2-elements arrays [process_id, process_duration]

var location #node currently carrying the package

func set_processes(processes : Array):
	processes_list = processes
	
func get_processes():
	return processes_list #returns a reference so it will be editable

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
