extends Node

@export var scene_candidates: Array[PackedScene]

@export_group("RoomDefinition")
@export var isRoom: bool
@export_flags("TOP", "BOTTON", "LEFT", "RIGHT") var doors
@export var spawn_probability = 1.0

func _ready():
	GlobalSignals.connect("random_initialized", on_randomize)

func on_randomize():
	if Global.rng.randf_range(0.0, 1.0) > spawn_probability:
		queue_free()
	else:
		select_random_scene()

func select_random_scene():
	for child in get_children():
		child.queue_free()

	var pick_index = Global.rng.randi() % scene_candidates.size()
	var new_scene = scene_candidates[pick_index].instantiate()
	add_child(new_scene)
