extends Area2D

func _on_InteractArea_body_entered(body):
	if body.is_in_group("robots"):
		body.set_in_interact(true)

func _on_InteractArea_body_exited(body):
	if body.is_in_group("robots"):
		body.set_in_interact(false)
