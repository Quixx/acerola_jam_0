extends Node

var death_time = 0

func _ready():
	var tween = create_tween()
	tween.tween_property(self, "position", Vector2(0, 64), 1).as_relative().set_ease(Tween.EASE_IN)
	death_time = Time.get_ticks_msec() + 1000
	
func _process(delta):
	if Time.get_ticks_msec() > death_time:
		queue_free()
