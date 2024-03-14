extends Node

@onready var success = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer/Success
@onready var seed_label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/SeedLabel

@export_file("*.tscn") var main_menu
@export_file("*.tscn") var game_scene

@export var success_color: Color
@export var fail_color: Color

func _ready():
	Global.stop_timer()
	Global.set_cursor(Global.CursorType.DEFAULT)
	if Global.goal_reached:
		success.text = "PASSED"
		success.add_theme_color_override("font_color", success_color)
	else:
		success.add_theme_color_override("font_color", fail_color)
		success.text = "FAILED"
	
	seed_label.text = '#' + Global.seed_value


func _on_replay_button_button_down():
	get_tree().change_scene_to_file(game_scene)

func _on_play_button_pressed():
	var newSeed = ''
	for i in 6:
		newSeed += str(randi_range(0, 9))
	Global.seed_value = newSeed
	get_tree().change_scene_to_file(game_scene)

func _on_main_menu_pressed():
	get_tree().change_scene_to_file(main_menu)
