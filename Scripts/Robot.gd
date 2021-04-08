extends KinematicBody2D

var moving: bool = false
var move_time: float = 0.0
var velocity: Vector2 = Vector2.ZERO

func _physics_process(delta):
	if moving:
		var collision = move_and_collide(velocity*delta)
		move_time -= delta
		if collision or move_time <= 0.0:
			stop()

func goto(dir:float, speed:float, time:float):
	# dir : rad
	# speed : px/s
	# time : s
	move_time = time
	velocity = speed * Vector2.RIGHT.rotated(dir) # already normalized
	moving = true
	# Send "started"

func stop():
	move_time = 0.0
	velocity = Vector2.ZERO
	moving = false
	# Send "stopped"
	
