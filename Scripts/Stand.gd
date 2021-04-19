extends StaticBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


func get_area_rectangle()-> Array:
	#returns info about the location of the stand, as a Vector2 Array [location, size]
	var location = $Sprite.global_transform.get_origin()
	var size = $Sprite.texture.get_size() * $Sprite.scale
	
	return [location, size]
