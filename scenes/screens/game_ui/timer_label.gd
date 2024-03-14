extends Node

func _process(delta):
	var timer = Global.timer
	var minutes = timer / 60
	var seconds = fmod(timer, 60)
	var milliseconds = fmod(timer, 1) * 100
	var time_string = "%02d:%02d:%02d" % [minutes, seconds, milliseconds]
	self.text = time_string
