extends Node

onready var _Robot = $Robot
onready var _Package = $Package
onready var _Navigation = $Navigation2D

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
	
	for node in get_tree().get_nodes_in_group("stands"):
		var shape_transform: Transform2D = node.get_node("CollisionShape2D").get_global_transform()
		var shape: RectangleShape2D = node.get_node("CollisionShape2D").shape
		var shape_poly := PoolVector2Array([
			Vector2(-shape.extents.x, -shape.extents.y),
			Vector2(-shape.extents.x, shape.extents.y),
			Vector2(shape.extents.x, shape.extents.y),
			Vector2(shape.extents.x, -shape.extents.y)
		])
		shape_poly = Geometry.offset_polygon_2d(shape_poly, _Navigation.nav_margin)[0]
		
		_Navigation.get_node("NavigationPolygonInstance").navpoly = _Navigation.cut_poly(shape_transform.xform(shape_poly), true)

func _unhandled_input(event):
	# From GDQuest - Navigation 2D and Tilemaps
	if event.is_action_pressed("ui_accept"):
		_Robot.pickup()
		
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			BUTTON_LEFT:
				_Robot.goto_path(event.position)
			BUTTON_RIGHT:
				var temp_shape = PoolVector2Array([Vector2(-32,-32),Vector2(-32,32),Vector2(32,32),Vector2(32,-32)])
				var temp_transform = Transform2D(0, event.position)
				
				_Navigation.get_node("NavigationPolygonInstance").navpoly = _Navigation.cut_poly(temp_transform.xform(temp_shape))
			BUTTON_MIDDLE:
				_Navigation.get_node("NavigationPolygonInstance").navpoly = _Navigation.static_poly
