extends Node


@export var color_a: Color
@export var color_b: Color

var SPEED = 0.001

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var time_in_seconds = Time.get_ticks_usec() * 0.001
	var progress = (sin(time_in_seconds * SPEED) + 1.0) * 0.5
	var target_color = color_a.lerp(color_b, progress)
	self.light_color = target_color
