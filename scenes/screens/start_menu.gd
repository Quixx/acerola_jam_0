extends Control

@onready var seed_label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/SeedLabel

@export_file("*.tscn") var game_scene
@export var display_seed_count = 6

var subject_id = []
var displayed_subject_id = []
var randomize_array = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '#', '?', '-', '_']

var next_seed_adjustment = 0
var seed_adjustment_time = 0.025
var current_try = 0
var max_tries = 10

func _ready():
	subject_id.resize(display_seed_count)
	displayed_subject_id.resize(display_seed_count)
	displayed_subject_id.fill('0')
	randomize_seed()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var label_text = '#'
	for number in displayed_subject_id:
		label_text += number
	seed_label.text = label_text

	if next_seed_adjustment <= 0:
		for index in display_seed_count:
			if str(subject_id[index]) == displayed_subject_id[index]:
				continue
			if current_try >= max_tries:
				displayed_subject_id[index] = str(subject_id[index])
			else:
				current_try += 1
				displayed_subject_id[index] = randomize_array.pick_random()
			
			if str(subject_id[index]) == displayed_subject_id[index]:
				current_try = 0

			next_seed_adjustment = seed_adjustment_time
			break
	next_seed_adjustment -= delta

func randomize_seed():
	for index in display_seed_count:
		subject_id[index] = randi_range(0, 9)
	next_seed_adjustment = seed_adjustment_time
	current_try = 0

func _on_randomize_seed_button_pressed():
	randomize_seed()

func _on_play_button_pressed():
	Global.seed_value = ''
	for digit in subject_id:
		Global.seed_value += str(digit)
	
	get_tree().change_scene_to_file(game_scene)

func _on_exit_button_pressed():
	get_tree().quit()

