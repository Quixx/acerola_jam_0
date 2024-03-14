extends Node3D

@onready var animation_player = $AnimationPlayer

var next_flicker = 0
@export var next_flicker_min = 12.0
@export var next_flicker_max = 180.0


func _ready():
	pass # Replace with function body.


func _process(delta):
	next_flicker -= delta
	if next_flicker <= 0:
		randomize_flicker_time()
		animation_player.play("flicker")

func randomize_flicker_time():
	next_flicker = randf_range(next_flicker_min, next_flicker_max)
