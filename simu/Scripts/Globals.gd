extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


const default_battery_charge_rate = 0.8
const default_battery_drain_rate = 0.1
const default_battery_drain_rate_idle = default_battery_drain_rate / 100
const standard_velocity = 50
const default_battery_capacity = 10
const default_battery_charge_rate_percentage = default_battery_charge_rate / default_battery_capacity * 100
const default_battery_drain_rate_percentage = default_battery_drain_rate / default_battery_capacity * 100
const default_battery_drain_rate_idle_percentage = default_battery_drain_rate_idle / default_battery_drain_rate * 100


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
	export_data.append(["Globals.robot_standard_velocity",  standard_velocity])
	export_data.append(["Globals.robot_battery_charge_rate_percentage", default_battery_charge_rate_percentage])
	export_data.append(["Globals.robot_battery_drain_rate_percentage", default_battery_drain_rate_percentage])
	export_data.append(["Globals.robot_battery_drain_rate_idel_percentage", default_battery_drain_rate_idle_percentage])
	return export_data

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
