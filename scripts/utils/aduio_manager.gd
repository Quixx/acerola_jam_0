extends Node


func _process(delta):
	var enable_sfx = Engine.time_scale < 1.0
	AudioServer.set_bus_effect_enabled(1, 0, enable_sfx)
	AudioServer.set_bus_effect_enabled(1, 1, enable_sfx)
