class_name PolyHelper

# Helper class to do operations on multiple polygons
# and create CollisionPolygon2Ds and NavigationPolygons

static func grow_polys(polys: Array, delta: float)->Array:
	var new_polys = []
	
	for poly in polys:
		new_polys.append(Geometry.offset_polygon_2d(poly, delta)[0])
	
	return new_polys

# Given an array of polygons as PoolVector2Arrays, returns a new array of polygons
# where overlapping ones have been merged
static func merge_polys(polys: Array)->Array:
	var new_polys = []
	var old_polys = polys.duplicate()
	
	while old_polys.size() > 0:
		var current_poly = old_polys[0]
		old_polys.remove(0)
		
		var i: int = 0
		while i < old_polys.size():
			var test_poly = Geometry.merge_polygons_2d(current_poly, old_polys[i])
			if test_poly.size() == 1:
				current_poly = test_poly[0]
				old_polys.remove(i)
				i = 0
			else:
				i += 1
		new_polys.append(current_poly)
	
	return new_polys

# Given an array of polygons as PoolVector2Arrays and an outline polygon, returns
# the new outline clipped by the polygons overlapping its border.
# Note: The polys array is passed by reference and is mutated to remove the overlapping polygons from it
static func outline_exclude_polys(polys: Array, outline: PoolVector2Array)->PoolVector2Array:
	var new_outline: PoolVector2Array = outline
	
	var i: int = 0
	while i < polys.size():
		if Geometry.clip_polygons_2d(polys[i], new_outline).size() > 0:
			new_outline = Geometry.clip_polygons_2d(new_outline, polys[i])[0]
			polys.remove(i)
			i = 0
		else:
			i += 1
	
	return new_outline

# Given an array of polygons, returns an array of CollisionPolygon2Ds
static func make_collision_polys(polys: Array)->Array:
	var collision_polys = []
	
	for poly in polys:
		var new_collision_poly: CollisionPolygon2D = CollisionPolygon2D.new()
		new_collision_poly.polygon = poly
		collision_polys.append(new_collision_poly)
	
	return collision_polys

# Given an array of polygons and an external outline, returns a NavigationPolygon
# Note: the function assumes you have already merged the polygons and cut the outline
static func make_navigation_poly(polys: Array, outline: PoolVector2Array)->NavigationPolygon:
	var navigation_poly: NavigationPolygon = NavigationPolygon.new()
	
	# assumes every poly has been merged correctly
	for poly in polys:
		navigation_poly.add_outline(poly)
	navigation_poly.add_outline(outline)
	navigation_poly.make_polygons_from_outlines()
	
	return navigation_poly
	
	
