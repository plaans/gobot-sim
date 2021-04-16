extends Node2D


# Declare member variables here. Examples:



var processes_list : Array
#Array of 2-elements arrays [process_id, process_duration]

var delivery_limit : float 
#deadline for delivering the package

var location #node currently carrying the package


func set_processes(processes : Array):
	processes_list = processes
	
func get_processes():
	return processes_list #returns a reference so it will be editable
	
	
func set_delivery_limit(time : float):
	delivery_limit = time

func get_delivery_limit() -> float:
	return delivery_limit
	

func set_location(node : Node):
	location = node

func get_location() -> Node:
	return location
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
