extends Node2D

var delivery_limit: float setget set_delivery_limit, get_delivery_limit
# deadline for delivering the package

var all_processes: Array

onready var processes = $ProcessesNode
# List of processes and helper to display processes colors
enum ProcessMode {
	PROCESS_FIRST,
	PROCESS_ANY
}
export(ProcessMode) var process_mode = ProcessMode.PROCESS_FIRST

var package_name : String
var location
	
func get_name() -> String:
	return package_name

func _ready():
	#generate a name 
	package_name = ExportManager.register_new_node(self, "package")
	
	ExportManager.add_export_static(self)
	ExportManager.add_export_dynamic(self)

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
func get_all_processes_ids_durations():
	#used for packages, to get list of id and durations of processes
	var id_duration_list = []
	for process in all_processes:
		id_duration_list.append(process.to_array())
	return id_duration_list
	
func export_static() -> Array:
	var export_data=[]
	export_data.append(["Package.instance", package_name, "package"])
	export_data.append(["Package.all_processes", package_name, get_all_processes_ids_durations()])
	return export_data
	
func export_dynamic() -> Array:
	var export_data=[]
	
	var location = get_parent()
	if location is Path2D:
		location = location.get_parent() #case of belt

	export_data.append(["Package.processes_list", package_name, processes.get_processes_ids_durations()])
	export_data.append(["Package.location", package_name, location.get_name()])
	
	return export_data
