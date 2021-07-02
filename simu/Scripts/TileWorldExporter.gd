class_name TileWorldExporter extends Node
tool

export(bool) var export_environment = true setget set_export_environment
export(String, FILE, "*.json") var target_path

func set_export_environment(value: bool):
	if is_inside_tree() and Engine.editor_hint:
		export_environment = do_export()

func do_export()->bool:
	var parent = get_parent()
	if !parent is TileMap:
		print("%s error: should be a child of a Tilemap"%get_class())
		return false
	if target_path == "":
		print("%s error: no target path specified"%get_class())
		return false
	
	var world = TileWorld.new(parent)
	var world_data = JSON.print(world.to_dict(), "")
	
	var file: File = File.new()
	var error = file.open(target_path, File.WRITE)
	if error:
		print("%s error: %s"%[get_class(), error])
		return false
	
	file.store_string(world_data)
	file.close()

	
	return true

func _get_configuration_warning():
	if not get_parent() is TileMap:
		return "%s must be a child of a TileMap"%get_class()
	else:
		return ""

func get_class():
	return "TileWorldExporter"

func is_class(value):
	if value == get_class():
		return true
	else:
		return false
