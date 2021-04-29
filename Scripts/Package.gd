extends Node2D

onready var processes_displays := $Processes.get_children()
var processes: Array setget set_processes, get_processes
# Array of Processes
var delivery_limit: float setget set_delivery_limit, get_delivery_limit
# deadline for delivering the package

func _ready():
	pass 
		
func set_processes(new_processes: Array):
	processes = new_processes
	update_processes_display()
func get_processes():
	return processes #returns a reference so it will be editable

func set_delivery_limit(time : float):
	delivery_limit = time
func get_delivery_limit() -> float:
	return delivery_limit

func remove_process(index: int):
	processes.remove(index)
	update_processes_display()

func update_processes_display():
	if processes.size() == 0:
		return
	
	for i in processes_displays.size():
		var display = processes_displays[i]
		if i < processes.size():
			display.show()
			display.modulate = processes[i].color
		else:
			display.hide()
