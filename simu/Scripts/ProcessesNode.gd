extends Node2D

# WARNING: this node should only be manipulated after it has entered the tree.
# Example when instancing Package scene:
# | var new_package = load("path/to/Package").instance()
# | add_child(new_package)
# | new_package.processes.processes = ...

var processes: Array setget set_processes, get_processes


# Array containing all the processes
onready var processes_displays: Array = self.get_children()
# Array containing all the displays for processes.
# All the children of this node are considered to be displays

# Called when the node enters the scene tree for the first time.
func _ready():
	update_processes_display()

# Updates the processes displays to show available processes
func update_processes_display():
	# Skip function if the node has not entered the scene tree
	if !is_inside_tree():
		return
	
	for i in processes_displays.size():
		var display = processes_displays[i]
		if i < processes.size():
			display.show()
			display.modulate = processes[i].color
		else:
			display.hide()

func set_processes(new_processes: Array):
	processes = new_processes
	update_processes_display()
	
func get_processes():
	return processes #returns a reference so it will be editable
	
func get_processes_ids():
	#used for machines, to get list of id of processes
	var id_list = []
	for process in processes:
		id_list.append(process.get_id())
	return id_list
	
func get_processes_ids_durations():
	#used for packages, to get list of id and durations of processes
	var id_duration_list = []
	for process in processes:
		id_duration_list.append(process.to_array())
	return id_duration_list

# Removes the process in the processes array at the given index, 
# and returns the removed process
func remove_process(index: int)->Process:
	var old_process = processes[index]
	processes.remove(index)
	update_processes_display()
	return old_process

# Returns true if a process has the same id as cmp_process,
# or false otherwise
func has_process(cmp_process: Process)->bool:
	for process in processes:
		if process.id == cmp_process.id:
			return true
	return false

# Returns the index of the first process with the same id as cmp_process,
# or -1 if there is none
func find_process(cmp_process: Process)->int:
	var i: int = 0
	while i < processes.size():
		if processes[i].id == cmp_process.id:
			return i
		i += 1
	return -1
