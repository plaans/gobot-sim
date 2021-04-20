class_name PolyHelper

static func grow_polys(polys: Array, delta: float)->Array:
	var new_polys = []
	
	for poly in polys:
		new_polys.append(Geometry.offset_polygon_2d(poly, delta)[0])
	
	return new_polys

static func merge_polys(polys: Array)->Array:
	var new_polys = []
	var old_polys = polys.duplicate()
	
	while old_polys.size() > 0:
		var current_poly = old_polys[0]
		old_polys.remove(0)
		
		var i: int = 0
		while i < old_polys.size():
			if Geometry.intersect_polygons_2d(current_poly, old_polys[i]).size() > 0:
				current_poly = Geometry.merge_polygons_2d(current_poly, old_polys[i])[0]
				old_polys.remove(i)
				i = 0
			else:
				i += 1
		new_polys.append(current_poly)
	
	return new_polys

# Careful: polys is passed by reference
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

#given an array of polygons, returns an array of CollisionPoly2D
static func make_collision_polys(polys: Array)->Array:
	var collision_polys = []
	
	for poly in merge_polys(polys):
		var new_collision_poly: CollisionPolygon2D = CollisionPolygon2D.new()
		new_collision_poly.polygon = poly
		collision_polys.append(new_collision_poly)
	
	return collision_polys

#given an array of polygons and an external outline, returns a NavigationPolygon
static func make_navigation_poly(polys: Array, outline: PoolVector2Array)->NavigationPolygon:
	var navigation_poly: NavigationPolygon = NavigationPolygon.new()
	
	# TODO: calculate NavigationPolygon
	
	return navigation_poly
	
	
