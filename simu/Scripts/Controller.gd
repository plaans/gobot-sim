tool
extends Node2D
class_name Controller

export(Vector2) var target_point = null # px, in global coordinates
export(float) var target_margin = 0.0 # px

func _get_configuration_warning():
	if !has_method("get_velocity") or !has_method("reached_target"):
		return "%s must implement the methods get_velocity and reached_target"%get_class()
	return ""

func _get_property_list():
	var properties = []
	properties.append({
			name = "Target",
			type = TYPE_NIL,
			hint_string = "target_",
			usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
	})
	return properties

func get_class():
	return "Controller"
