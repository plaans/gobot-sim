extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


const default_battery_charge_rate = 0.8
const default_battery_drain_rate = 0.1
const default_battery_drain_rate_idle = default_battery_drain_rate / 100
const standard_speed = 50.0
const default_battery_capacity = 10


# Called when the node enters the scene tree for the first time.
func _ready():
	ExportManager.add_export_static(self)
	pass # Replace with function body.

func export_static() -> Array:
	var export_data = []
	export_data.append(["Globals.robot_default_battery_capacity", default_battery_capacity])
	export_data.append(["Globals.robot_battery_charge_rate",default_battery_charge_rate])
	export_data.append(["Globals.robot_battery_drain_rate", default_battery_drain_rate])
	export_data.append(["Globals.robot_battery_drain_rate_idle", default_battery_drain_rate_idle])
	export_data.append(["Globals.robot_standard_speed",  ExportManager.pixel_to_meter(standard_speed)])
	return export_data

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
