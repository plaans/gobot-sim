class_name Process

# Data management class.
# Creates a process with an id and a duration
# Color is calculated automatically with RNG, seeded by the id
#
# Create a process from an array:
# | var new_process = Process.new().from_array([...])

var id: int setget set_id, get_id
var duration: float setget set_duration, get_duration
var color: Color setget set_color, get_color

# Note: if no id or duration is given, the fields will stay empty
func _init(new_id: int = NAN, new_duration: float = NAN):
	if new_id:
		id = new_id
		color = calculate_color(id)
	if new_duration:
		duration = new_duration

# Warning: creates incoherence between id and color
func set_id(new_id: int):
	id = new_id
func get_id():
	return id

func set_duration(new_duration: float):
	duration = new_duration
func get_duration():
	return duration

# Warning: creates incoherence between id and color
func set_color(new_color: Color):
	color = new_color
func get_color():
	return color

func to_array()->Array:
	return [id, duration]
func from_array(data: Array = []):
	id = int(data[0])
	duration = float(data[1])
	color = calculate_color(id)

static func calculate_color(id: int)->Color:
	var rng := RandomNumberGenerator.new()
	rng.seed = int((id+32)^2)
	
	return Color(rng.randf(), rng.randf(), rng.randf())
