extends Area2D

func _on_ParkingArea_body_entered(body):
	if body.is_in_group("robots"):
		body.set_in_station(true)

func _on_ParkingArea_body_exited(body):
	if body.is_in_group("robots"):
		body.set_in_station(false)
