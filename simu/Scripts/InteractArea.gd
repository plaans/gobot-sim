extends Area2D

var belt: Node = null
var interact_area_name : String
var cells : Array #contains the cells of the interact_area
var polys : Array

func _ready():
	ExportManager.add_export_static(self)
	
	#generate a name 
	interact_area_name = ExportManager.new_name("interact_area")
	
func get_name() -> String:
	return interact_area_name

func _on_InteractArea_body_entered(body):
	if body.is_in_group("robots"):
		body.in_interact.append(self)

func _on_InteractArea_body_exited(body):
	if body.is_in_group("robots"):
		body.in_interact.erase(self)

func export_static() -> Array:
	var export_data = []
	export_data.append(["Interact_area.instance", interact_area_name, "interact_area"])
	
	export_data.append(["Interact_area.cells", interact_area_name, cells])
	export_data.append(["Interact_area.polygons", interact_area_name, ExportManager.convert_polys_list_to_meters(polys)])
	export_data.append(["Interact_area.belt", interact_area_name, belt.get_name()])

	return export_data
