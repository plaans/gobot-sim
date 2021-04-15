extends Node

onready var _Robot = $Robot
onready var _Package = $Package

export var ROBOT_SPEED = 96 #px/s
# Note:
# 1m ~ 32px
# so 3m/s = 96px/s

func _ready():
	#$Package.position = $Stand.position #for testing purposes we use only one package and initially place it at the first stand
	#$Stand.set_package($Package)
	self.remove_child(_Package)
	$Stand.add_child(_Package)
	_Package.set_owner($Stand)

func _unhandled_input(event):
	# From GDQuest - Navigation 2D and Tilemaps
	if Input.is_action_pressed("ui_accept"):
		_Robot.pickup()
		
	if not event is InputEventMouseButton:
		return
		
	if event.button_index != BUTTON_LEFT or not event.pressed:
		return
	# -> then, has to be a click from the RMB
	
#	var dir_vec: Vector2 = (event.position - _Robot.position)
#	var speed = ROBOT_SPEED
#	var time = dir_vec.length()/speed
	_Robot.goto_path(event.position)
	
