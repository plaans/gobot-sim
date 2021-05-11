extends Area2D

var belt: Node = null

func _on_InteractArea_body_entered(body):
	if body.is_in_group("robots"):
		print("belt: "+str(belt))
		body.in_interact.append(self)

func _on_InteractArea_body_exited(body):
	if body.is_in_group("robots"):
		body.in_interact.erase(self)
