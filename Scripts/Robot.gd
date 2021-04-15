extends KinematicBody2D

onready var _Package = get_node("../../Package")

var moving: bool = false
var move_time: float = 0.0
var velocity: Vector2 = Vector2.ZERO

var path: PoolVector2Array
var path_line: Line2D
var following: bool = false
var current_path_point: int = 0

var carried_package

func _physics_process(delta):
	if !moving && following:
		if move_time <= 0.0:
			current_path_point += 1
			
		if current_path_point >= path.size():
			stop_path()
		else:
			var dir_vec: Vector2 = (path[current_path_point] - position)
			var speed = 96.0
			var time = dir_vec.length()/speed
			goto(dir_vec.angle(), speed, time)
		
	if moving:
		var collision = move_and_collide(velocity*delta)
		#if carried_package!=null:
			#carried_package.position = position
		
		move_time -= delta
		if collision:
			stop()
			stop_path()
			# Send "collision"
		elif move_time <= 0.0:
			stop()
			
func is_moving():
	return moving

func goto(dir:float, speed:float, time:float):
	# dir : rad
	# speed : px/s
	# time : s
	move_time = time
	velocity = speed * Vector2.RIGHT.rotated(dir) # already normalized
	moving = true
	# Send "started"

func goto_path(point: Vector2):
	stop()
	stop_path()
	var _nav: Navigation2D = get_node("../Navigation2D")
	if _nav:
		path = _nav.get_simple_path(position, point, true)
		var new_path_line = Line2D.new()
		new_path_line.points = path
		new_path_line.width = 2
		new_path_line.default_color = Color(1,1,1,0.5)
		self.path_line = new_path_line
		_nav.add_child(new_path_line)
		
		following = true
		current_path_point = 0

func stop():
	move_time = 0.0
	velocity = Vector2.ZERO
	moving = false
	# Send "stopped"
	
func stop_path():
	following = false
	if path_line:
		path_line.free()
	
func pickup():
	if carried_package==null:
		#no package carried so pick up function
		
		#first find the closest stand
		var closest_stand = find_closest_stand()
		
		#then check if a close enough stand was found
		if closest_stand !=null:
			var stand_package = closest_stand.get_node("Package")
			if stand_package!=null:
				carried_package=stand_package
				closest_stand.remove_child(carried_package)
				self.add_child(carried_package)
				#carried_package.set_owner(self)
	else: 
		#already carrying a package so drop off function
		
		var closest_stand = find_closest_stand()
		
		#then check if a close enough stand was found
		if closest_stand !=null:
			var stand_package = closest_stand.get_node("Package")
			if stand_package==null:
				self.remove_child(carried_package)
				closest_stand.add_child(carried_package)
				#carried_package.set_owner(closest_stand)
				carried_package=null
	
func find_closest_stand():
	#if no stands in pickup radius returns null
	#if multiple stands are in pickup radius returns the closest one
	
	var stands = $Area2D.get_overlapping_bodies()
	var closest_stand = null
	var dist_min=1000000
	for stand in stands:
		var distance = self.position.distance_to(stand.position)
		if distance <= dist_min:
			dist_min = distance
			closest_stand = stand	
	return closest_stand
	
