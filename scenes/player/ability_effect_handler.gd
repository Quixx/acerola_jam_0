extends Node

@onready var fullscreen_effect: ColorRect = $FullscreenEffect

var display_timer = 0
var target_alpha = 0.0

func _ready():
	GlobalSignals.connect("ability_start", on_ability_start)

func _process(delta):
	if display_timer > 0:
		display_timer -= delta
	
	if display_timer <= 0:
		target_alpha = 0.0
	
	var alpha = fullscreen_effect.material.get_shader_parameter("alpha")
	var timeScale = Engine.time_scale if Engine.time_scale > 0.0 else 1.0
	alpha = move_toward(alpha, target_alpha, delta / timeScale)
	fullscreen_effect.material.set_shader_parameter("alpha", alpha)
	
func on_ability_start(duration):
	fullscreen_effect.visible = true
	display_timer = max(0.2, duration)
	target_alpha = 0.5
