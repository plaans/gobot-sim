extends Node2D

var delivery_limit: float setget set_delivery_limit, get_delivery_limit
# deadline for delivering the package
onready var _Processes = $ProcessesNode
# List of processes and helper to display processes colors

func _ready():
	pass

func set_delivery_limit(time : float):
	delivery_limit = time
func get_delivery_limit() -> float:
	return delivery_limit
