extends Node3D
@onready var generated_map = $GeneratedMap

@export_file("*.tscn") var end_scene

var player_dead = false
var player_dead_timer = 0

func _ready():
	GlobalSignals.connect("game_end", on_game_end)
	GlobalSignals.connect("player_dead", on_player_dead)

	Global.timer = 0
	Global.goal_reached = false
	player_dead = false
	player_dead_timer = 0
	
	var seed_value = 0
	if Global.seed_value != '':
		seed_value = hash(Global.seed_value)
	else:
		# seed_value = randi()
		Global.seed_value = '687080'
		seed_value = hash(Global.seed_value)
	
	Global.rng.set_seed(seed_value)
	generated_map.generate_map()
	$Player.position = generated_map.player_spawn_position
	GlobalSignals.emit_signal("random_initialized")

func _process(delta):
	if player_dead:
		player_dead_timer += delta
		if player_dead_timer > 2.0:
			GlobalSignals.emit_signal("game_end")
	
func on_game_end():
	get_tree().change_scene_to_file(end_scene)

func on_player_dead():
	player_dead = true
