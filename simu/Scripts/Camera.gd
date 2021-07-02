extends Camera2D

export(float, 0.0, 10) var pan_speed = 1.0
export(float, 0.0, 2) var zoom_speed = 0.1
export(float) var zoom_min = 0.2
export(float) var zoom_max = 4.0
var panning: bool = false
var zoom_amount = 1.0

func _unhandled_input(event):
	if event is InputEventMouseButton:
		match event.button_index:
			BUTTON_MIDDLE:
				panning = event.pressed
			BUTTON_WHEEL_DOWN:
				if event.pressed:
					add_zoom(zoom_speed)
			BUTTON_WHEEL_UP:
				if event.pressed:
					add_zoom(-zoom_speed)
	if event is InputEventMouseMotion and panning:
		self.position -= event.relative*pan_speed*zoom_amount

func add_zoom(amount: float):
	zoom_amount = clamp(zoom_amount + amount, zoom_min, zoom_max)
	zoom = Vector2.ONE*zoom_amount
