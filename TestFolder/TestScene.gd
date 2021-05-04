extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var timer = Timer.new()
	timer.wait_time = 2
	timer.one_shot = true
	add_child(timer)
	timer.connect("timeout", self, "_on_Timer_timeout")
	timer.start()
	
	$Custom/Belt.visual_speed = 0.5
	$Custom/Belt.move_package_offset($Custom/Belt/PackagePath/Package, 1)

func _on_Timer_timeout():
	var machine = $Custom/Machine
	machine.current_display_index = 0
	machine.set_process_blinking(true)
	$Custom/Machine/AnimationPlayer.play("process")
	yield(get_tree().create_timer(3), "timeout")
	machine.set_process_blinking(false)
	$Custom/Machine/AnimationPlayer.stop()
