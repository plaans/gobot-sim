extends Area2D

var parking_area_name : String
var cells : Array #contains the cells of the parking_area
var polys : Array

func _ready():
	#generate a name 
	parking_area_name = ExportManager.register_new_node(self, "parking_area")
	
	ExportManager.add_export_static(self)
	
func get_name() -> String:
	return parking_area_name

func _on_ParkingArea_body_entered(body):
	if body.is_in_group("robots"):
		body.set_in_station(true)
		body.in_parking_area.append(self)

func _on_ParkingArea_body_exited(body):
	if body.is_in_group("robots"):
		body.set_in_station(false)
		body.in_parking_area.erase(self)

func export_static() -> Array:
	var export_data = []
	export_data.append(["Parking_area.instance", parking_area_name, "parking_area"])
	export_data.append(["Parking_area.cells", parking_area_name, ExportManager.convert_vector2s_array_to_arrays_array(cells)])
	export_data.append(["Parking_area.polygons", parking_area_name, ExportManager.convert_polys_list_to_meters(polys)])

	return export_data
