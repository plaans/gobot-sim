extends Area2D

var belt: Node = null
var interact_area_name : String

func _ready():
	add_to_group("export_static")
	
	#generate a name 
	interact_area_name = ExportManager.new_name("interact_area")
	
func get_name() -> String:
	return interact_area_name

func _on_InteractArea_body_entered(body):
	if body.is_in_group("robots"):
		print("belt: "+str(belt))
		body.in_interact.append(self)

func _on_InteractArea_body_exited(body):
	if body.is_in_group("robots"):
		body.in_interact.erase(self)

func export_static() -> Array:
	var export_data = []
	export_data.append(["interact_area", interact_area_name])
	
	if get_children().size()>0:
		var collision_polygon = get_child(0)
		export_data.append(["polygon", interact_area_name, ExportManager.convert_array_pixels_to_meters(collision_polygon.get_polygon())])

	return export_data
