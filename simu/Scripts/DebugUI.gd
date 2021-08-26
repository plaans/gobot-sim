extends CanvasLayer

enum Debug {ALL, PATH, CONTROLLER}
var active_debug: Array = [false,false,false] setget set_active_debug

func _on_DrawDebug_toggled(button_pressed):
	active_debug[Debug.ALL] = button_pressed
	set_active_debug(active_debug)

func _on_DrawRobotPathDebug_toggled(button_pressed):
	active_debug[Debug.PATH] = button_pressed
	set_active_debug(active_debug)

func _on_DrawControllerDebug_toggled(button_pressed):
	active_debug[Debug.CONTROLLER] = button_pressed
	set_active_debug(active_debug)

func set_active_debug(states: Array):
	active_debug = states
	for node in get_tree().get_nodes_in_group("debug"):
		if node.is_in_group("debug_path"):
			node.debug_draw = active_debug[Debug.PATH] and active_debug[Debug.ALL]
		if node.is_in_group("debug_controller"):
			node.debug_draw = active_debug[Debug.CONTROLLER] and active_debug[Debug.ALL]
