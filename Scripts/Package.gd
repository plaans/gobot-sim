extends Node2D


# Declare member variables here. Examples:


var package_id : int
#id to uniquely identify this package (also attributed from Main node)

var colors_sprites : Array #will contain the array of the sprites used to store colors
const color_palette : Array = ["cornflower", "crimson ", "yellow", "seagreen", "sandybrown", "skyblue ", "lightpink ", "palegreen ", "aquamarine", "saddlebrown"] #list of colorsto be used to represent processes


var processes_list : Array
#Array of 2-elements arrays [process_id, process_duration]

var delivery_limit : float 
#deadline for delivering the package

var location #node currently carrying the package


func set_id(id : int):
	package_id = id
	
func get_id() -> int:
	return package_id

func _ready():
	generates_display()
	

func generates_display():
	for k in range(8):
		var sprite = Sprite.new()
		sprite.texture = load("res://Assets/package/Package-%s.png" % (k+2))
		sprite.modulate = ColorN(color_palette[k], 1)
		sprite.visible = false
		$Main_Sprite.add_child(sprite)
		colors_sprites.append(sprite)



func update_tasks_display():
	for k in range(processes_list.size()):
		if k<8:
			#only display  for the first 8 tasks
			var process = processes_list[k]
			var id = process[0]
			var color_name
			if id<color_palette.size():
				color_name = color_palette[id]
			else:
				#if too much different tasks compared to palette size default other colors to white
				color_name = "white"
			
			colors_sprites[k].modulate = ColorN(color_name, 1)
			colors_sprites[k].visible = true
		
	for k in range(processes_list.size(),8):
		colors_sprites[k].visible = false
		
func set_processes(processes : Array):
	processes_list = processes
	update_tasks_display()
	
func get_processes():
	return processes_list #returns a reference so it will be editable
	
	
func set_delivery_limit(time : float):
	delivery_limit = time

func get_delivery_limit() -> float:
	return delivery_limit
	

func set_location(node : Node):
	location = node

func get_location() -> Node:
	return location
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
