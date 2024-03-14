extends Area3D

var is_teleporter = true

func _process(delta):
	for body in get_overlapping_bodies():
		var body_class = body.get_class()
		if body is Player:
			Global.goal_reached = true
			GlobalSignals.emit_signal("game_end")
