extends Node

onready var _Robot = $Robot

export var ROBOT_SPEED = 96 #px/s
# Note:
# 1m ~ 32px
# so 3m/s = 96px/s

func _unhandled_input(event):
	# From GDQuest - Navigation 2D and Tilemaps
	if not event is InputEventMouseButton:
		return
	if event.button_index != BUTTON_LEFT or not event.pressed:
		return
	# -> then, has to be a click from the RMB
	
	var dir_vec: Vector2 = (event.position - _Robot.position)
	var speed = ROBOT_SPEED
	var time = dir_vec.length()/speed
	_Robot.goto(dir_vec.angle(), speed, time)
	
