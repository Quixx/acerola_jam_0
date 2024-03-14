extends Node

func _process(delta):
	var velocity: Vector3 = get_parent().velocity
	if velocity.length_squared() > 0:
		Global.start_timer()
		queue_free()
