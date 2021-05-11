extends Node2D

var delivery_limit: float setget set_delivery_limit, get_delivery_limit
# deadline for delivering the package
onready var processes = $ProcessesNode
# List of processes and helper to display processes colors
enum ProcessMode {
	PROCESS_FIRST,
	PROCESS_ANY
}
export(ProcessMode) var process_mode = ProcessMode.PROCESS_FIRST

var package_name
var location

func set_name(name : String):
	package_name = name
	
func get_name() -> String:
	return package_name

func _ready():
	pass

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

func export_static():
	return [["package", package_name]]
	
func export_dynamic():
	var export_data=[]
	export_data.append(["location", package_name, get_parent().get_name()])
	export_data.append(["processes", package_name, processes])
	
	return export_data

